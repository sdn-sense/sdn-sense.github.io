#!/usr/bin/env bash
# Log in to SENSE-O (Keycloak) with the OAuth 2.0 device flow and cache the
# tokens, so one login survives new terminals and reboots.
#
# On every run the cheapest working option wins:
#   1. the cached access token, if valid for more than SENSE_MIN_TTL seconds
#   2. a refresh with the cached refresh token
#   3. the interactive device login in a browser (skipped with --no-login)
#
# --offline adds the offline_access scope. Keycloak then issues an offline
# refresh token with no fixed lifetime, only an idle timeout (30 days by
# default, reset by every refresh). Once a cached login is offline, later
# re-logins request offline_access again until --logout.
#
# Tokens are stored in SENSE_TOKEN_FILE (mode 600), one login per
# KC/REALM/CLIENT_ID, so logins to different Keycloaks do not evict each other.
# They are only ever printed by --env and --token, whose purpose is to hand
# the access token over.
set -euo pipefail
umask 077

KC="${KC:-https://sense-o.es.net:8543}"
REALM="${REALM:-StackV}"
CLIENT_ID="${CLIENT_ID:-sense-cli}"
BASE="$KC/realms/$REALM/protocol/openid-connect"
KEY="$KC|$REALM|$CLIENT_ID"
TOKEN_FILE="${SENSE_TOKEN_FILE:-$HOME/.private/sense-tokens.json}"
MIN_TTL="${SENSE_MIN_TTL:-60}"
LOCK_DIR="$TOKEN_FILE.lock"
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
PROG="$(basename "$0")"

usage() {
  cat <<EOF
Usage: $PROG [options]

Get a SENSE-O access token: reuse the cached one, refresh it, or fall back to
the browser device login.

  --offline     request offline_access (durable refresh token, ~30 days idle)
  --force       ignore the cache and do a fresh device login
  --no-login    never start a device login; only use/refresh the cache
  --env         print 'export SENSE_ACCESS_TOKEN=...' lines for eval
  --token       print only the access token
  --status      show the cached login (no network)
  --logout      revoke the session at Keycloak and delete the cache
  --shell-init  print shell code for ~/.bashrc or ~/.zshrc:
                  eval "\$($SELF --shell-init)"
  -q, --quiet   no informational output
  -h, --help    show this help

Environment: KC, REALM, CLIENT_ID, SENSE_OFFLINE=1,
             SENSE_TOKEN_FILE (default ~/.private/sense-tokens.json),
             SENSE_MIN_TTL (renew when fewer seconds are left, default 60)
EOF
}

MODE=summary OFFLINE="${SENSE_OFFLINE:-0}" FORCE=0 NO_LOGIN=0 QUIET=0
CACHE='{}' SOURCE='' HAVE_LOCK=0 TMP_FILE='' EMITTED=0

say()  { echo "$@"; }   # informational, to fd 1 (stderr for --env/--token)
warn() { if ((QUIET == 0)); then echo "$PROG: $*" >&2; fi; }
die()  { echo "$PROG: $*" >&2; exit 1; }
now()  { date +%s; }

while (($#)); do
  case $1 in
    --offline)    OFFLINE=1 ;;
    --force)      FORCE=1 ;;
    --no-login)   NO_LOGIN=1 ;;
    --env)        MODE=env ;;
    --token)      MODE=token ;;
    --status)     MODE=status ;;
    --logout)     MODE=logout ;;
    --shell-init) MODE=shell_init ;;
    -q|--quiet)   QUIET=1 ;;
    -h|--help)    usage; exit 0 ;;
    *)            echo "$PROG: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done
[[ $OFFLINE =~ ^[01]$ ]] || die "SENSE_OFFLINE must be 0 or 1"
[[ $MIN_TTL =~ ^[0-9]+$ ]] || die "SENSE_MIN_TTL must be a number of seconds"

# fd 3 is the real stdout. For --env/--token it carries only machine output and
# everything human-readable moves to stderr, so `eval "$(...)"` stays safe.
exec 3>&1
if [[ $MODE == env || $MODE == token ]]; then exec 1>&2; fi
if ((QUIET)); then exec 1>/dev/null; fi

CURL_OPTS=(--connect-timeout 5 --max-time 20)
if ((NO_LOGIN)); then CURL_OPTS=(--connect-timeout 3 --max-time 8); fi  # shell startup: fail fast

release_lock() {
  if ((HAVE_LOCK)); then rmdir "$LOCK_DIR" 2>/dev/null || true; HAVE_LOCK=0; fi
}

cleanup() {
  local rc=$?
  if [[ -n $TMP_FILE ]]; then rm -f "$TMP_FILE"; fi
  release_lock
  # --env must leave the calling shell consistent: on any failure, tell it to
  # drop the token it holds, which is expired or about to be.
  if [[ $MODE == env ]] && ((EMITTED == 0)); then
    echo "unset SENSE_ACCESS_TOKEN SENSE_ACCESS_TOKEN_EXP" >&3
  fi
  exit "$rc"
}
trap cleanup EXIT

# Several shells may refresh at once; Keycloak can rotate refresh tokens, so
# serialise read-refresh-write with a mkdir lock (flock is not on macOS).
acquire_lock() {
  local tries=0 mtime
  mkdir -p -m 700 "$(dirname "$TOKEN_FILE")"
  until mkdir "$LOCK_DIR" 2>/dev/null; do
    mtime=$(stat -c %Y "$LOCK_DIR" 2>/dev/null || stat -f %m "$LOCK_DIR" 2>/dev/null || echo 0)
    if ((mtime > 0 && $(now) - mtime > 60)); then  # holder died: break the lock
      rmdir "$LOCK_DIR" 2>/dev/null || true
      continue
    fi
    ((++tries <= 150)) || die "timed out waiting for lock $LOCK_DIR"
    sleep 0.2
  done
  HAVE_LOCK=1
}

# Decode a JWT payload (base64url, unpadded); '{}' for opaque tokens.
jwt_payload() {
  local p
  p=$(cut -d. -f2 | tr '_-' '/+' | awk '{ while (length($0) % 4) $0 = $0 "="; print }' |
      base64 -d 2>/dev/null) || true
  if jq -e 'type == "object"' >/dev/null 2>&1 <<<"$p"; then printf '%s\n' "$p"; else echo '{}'; fi
}

access_valid() {
  jq -e --argjson now "$(now)" --argjson ttl "$MIN_TTL" \
    '(.access_token | type) == "string" and ((.expires_at // 0) - $now) > $ttl' >/dev/null <<<"$CACHE"
}
refresh_usable() {  # refresh_expires_at null = no fixed expiry (offline token)
  jq -e --argjson now "$(now)" \
    '(.refresh_token | type) == "string" and (.refresh_expires_at == null or (.refresh_expires_at - $now) > 10)' \
    >/dev/null <<<"$CACHE"
}
cache_offline() { jq -e '.offline == true' >/dev/null <<<"$CACHE"; }

# The cache file holds {"logins": {"<kc>|<realm>|<client>": {...}, ...}}.
# Prints it in that shape, converting the older single-login format.
read_file() {
  local f='{}'
  if [[ -s $TOKEN_FILE ]]; then
    f=$(jq -c 'select(type == "object")' "$TOKEN_FILE" 2>/dev/null) || f=''
    if [[ -z $f ]]; then warn "ignoring unreadable token cache $TOKEN_FILE"; f='{}'; fi
  fi
  jq -c 'if has("logins") then .
         elif has("kc") then {logins: {("\(.kc)|\(.realm)|\(.client_id)"): .}}
         else {logins: {}} end' <<<"$f"
}

load_cache() { CACHE=$(read_file | jq -c --arg k "$KEY" '.logins[$k] // {}'); }

# $1 = new record for $KEY, or null to remove it. Re-reads the file so other
# logins are kept; atomic replace, and mktemp creates the file with mode 600.
write_cache() {
  local f
  f=$(read_file | jq -c --arg k "$KEY" --argjson r "$1" \
        'if $r == null then del(.logins[$k]) else .logins[$k] = $r end')
  if [[ $1 == null ]]; then CACHE='{}'; else CACHE=$1; fi
  if [[ $(jq '.logins | length' <<<"$f") == 0 ]]; then rm -f "$TOKEN_FILE"; return 0; fi
  TMP_FILE=$(mktemp "$TOKEN_FILE.XXXXXX")
  printf '%s\n' "$f" >"$TMP_FILE"
  mv -f "$TMP_FILE" "$TOKEN_FILE"
  TMP_FILE=''
}

other_logins() { read_file | jq -r --arg k "$KEY" '.logins | keys[] | select(. != $k)'; }

# Store a token-endpoint response, merged over $CACHE (a refresh response may
# omit fields such as id_token), with lifetimes converted to absolute times.
save_tokens() {
  local resp=$1 at_claims rt_claims='{}' rt
  jq -e '(.access_token | type) == "string"' >/dev/null <<<"$resp" || die "token response has no access_token"
  at_claims=$(jq -r .access_token <<<"$resp" | jwt_payload)
  rt=$(jq -r '.refresh_token // empty' <<<"$resp")
  if [[ -n $rt ]]; then rt_claims=$(jwt_payload <<<"$rt"); fi
  write_cache "$(jq -c --argjson old "$CACHE" --argjson atc "$at_claims" --argjson rtc "$rt_claims" \
      --argjson now "$(now)" --arg kc "$KC" --arg realm "$REALM" --arg client "$CLIENT_ID" '
    {
      kc: $kc, realm: $realm, client_id: $client, obtained_at: $now,
      user: ($atc.preferred_username // $old.user),
      token_type, scope: (.scope // $old.scope),
      access_token, expires_at: ($now + (.expires_in // 0)),
      id_token: (.id_token // $old.id_token),
      refresh_token: (.refresh_token // $old.refresh_token),
      refresh_expires_at: (
        if .refresh_token == null then $old.refresh_expires_at
        elif (.refresh_expires_in // 0) > 0 then $now + .refresh_expires_in
        elif ($rtc.exp // 0) > 0 then $rtc.exp
        else null end),
      offline: (
        ((.scope // "") | split(" ") | any(. == "offline_access"))
        or (($rtc.typ // "") | ascii_downcase) == "offline"
        or (.refresh_token == null and $old.offline == true))
    }' <<<"$resp")"
}

# Sets SOURCE=refresh on success. Failures only warn: the caller falls back
# to a device login (or fails under --no-login).
do_refresh() {
  local rt resp err
  rt=$(jq -r .refresh_token <<<"$CACHE")
  # Tokens go through stdin, never argv, so they do not show up in `ps`.
  if ! resp=$(printf %s "$rt" | curl -sS "${CURL_OPTS[@]}" "$BASE/token" \
                -d grant_type=refresh_token -d client_id="$CLIENT_ID" \
                --data-urlencode refresh_token@-); then
    warn "token refresh failed: cannot reach $KC"
    return 0
  fi
  err=$(jq -r 'if type == "object" then .error // "" else "bad_response" end' <<<"$resp" 2>/dev/null) ||
    err=bad_response
  case $err in
    "") ;;
    invalid_grant)  # session expired or revoked: forget the dead refresh token
      warn "refresh token no longer valid ($(jq -r '.error_description // "expired or revoked"' <<<"$resp"))"
      write_cache "$(jq -c 'del(.refresh_token, .refresh_expires_at)' <<<"$CACHE")"
      return 0 ;;
    *)
      warn "token refresh failed: $err"
      return 0 ;;
  esac
  save_tokens "$resp"
  SOURCE=refresh
}

device_login() {
  local scope=openid dev device_code interval deadline resp err
  if ((OFFLINE)); then scope="openid offline_access"; fi

  if ! dev=$(curl -sS "${CURL_OPTS[@]}" "$BASE/auth/device" \
               -d client_id="$CLIENT_ID" --data-urlencode "scope=$scope"); then
    die "cannot reach $KC"
  fi
  device_code=$(jq -r '.device_code // empty' <<<"$dev" 2>/dev/null) || true
  if [[ -z $device_code ]]; then
    die "device authorization failed: $(jq -r '"\(.error // "unknown error"): \(.error_description // "")"' \
        <<<"$dev" 2>/dev/null || printf '%.200s' "$dev")"
  fi
  interval=$(jq -r '.interval // 5' <<<"$dev")
  deadline=$(($(now) + $(jq -r '.expires_in // 600' <<<"$dev")))

  {
    echo
    echo "Open in a browser:  $(jq -r '.verification_uri_complete // empty' <<<"$dev")"
    echo "Or go to $(jq -r .verification_uri <<<"$dev") and enter: $(jq -r .user_code <<<"$dev")"
    echo "Code expires in $(jq -r '.expires_in // "?"' <<<"$dev")s (scope: $scope). Waiting for approval..."
  } >&2

  # Poll the token endpoint until the user approves in the browser.
  while :; do
    if ! resp=$(printf %s "$device_code" | curl -sS "${CURL_OPTS[@]}" "$BASE/token" \
                  -d grant_type=urn:ietf:params:oauth:grant-type:device_code \
                  -d client_id="$CLIENT_ID" --data-urlencode device_code@-); then
      err=network_error  # transient: keep polling until the code expires
    else
      err=$(jq -r 'if type == "object" then .error // "" else "bad_response" end' <<<"$resp" 2>/dev/null) ||
        err=bad_response
    fi
    case $err in
      "") break ;;
      authorization_pending | network_error | bad_response) ;;
      slow_down) interval=$((interval + 5)) ;;
      *) die "login failed: $(jq -r '"\(.error): \(.error_description // "")"' <<<"$resp")" ;;
    esac
    (($(now) + interval < deadline)) || die "device code expired before it was approved"
    sleep "$interval"
  done

  acquire_lock
  CACHE='{}'  # a new login must not inherit fields from an older session
  save_tokens "$resp"
  release_lock
  SOURCE=login
}

ensure_token() {
  acquire_lock
  load_cache
  if cache_offline; then OFFLINE=1; fi
  if ((FORCE)); then
    :
  elif ((OFFLINE && NO_LOGIN == 0)) && ! cache_offline; then
    if [[ $CACHE != '{}' ]]; then say "Cached login lacks offline_access; starting a new login."; fi
  elif access_valid; then
    SOURCE=cache
  elif refresh_usable; then
    do_refresh
  fi
  release_lock

  if [[ -z $SOURCE ]]; then
    if ((NO_LOGIN)); then
      die "no usable SENSE token (login expired or revoked, or $KC unreachable); run: sense-login"
    fi
    device_login
  fi
}

checked_access_token() {  # refuse to hand anything odd to eval or a header
  local at
  at=$(jq -r .access_token <<<"$CACHE")
  [[ $at =~ ^[A-Za-z0-9._~+/=-]+$ ]] || die "cached access token has unexpected characters"
  printf '%s' "$at"
}

emit_env() {
  local at exp
  at=$(checked_access_token)
  exp=$(jq -r '.expires_at | floor' <<<"$CACHE")
  printf "export SENSE_ACCESS_TOKEN='%s'\nexport SENSE_ACCESS_TOKEN_EXP=%s\n" "$at" "$exp" >&3
  # Which login the token belongs to, so the prompt hook refreshes that one.
  printf 'export SENSE_KC=%q SENSE_REALM=%q SENSE_CLIENT_ID=%q\n' "$KC" "$REALM" "$CLIENT_ID" >&3
  EMITTED=1
}

JQ_DUR='def dur:
  if . <= 0 then "expired"
  elif . >= 86400 then "\(./86400 | floor)d\(. % 86400 / 3600 | floor)h"
  elif . >= 3600 then "\(./3600 | floor)h\(. % 3600 / 60 | floor)m"
  elif . >= 60 then "\(./60 | floor)m\(. % 60)s"
  else "\(.)s" end;'

describe() {  # $1 = where the token came from
  jq --arg src "$1" --arg file "$TOKEN_FILE" --argjson now "$(now)" "$JQ_DUR"'
    {
      source: $src, kc, realm, client_id, user, token_type, scope, offline,
      access_expires_in: ((.expires_at // 0) - $now | dur),
      access_expires_at: ((.expires_at // 0) | strflocaltime("%Y-%m-%d %H:%M:%S %Z")),
      refresh_expires_in: (
        if .refresh_token == null then "none: device login needed once the access token expires"
        elif .refresh_expires_at == null then "no fixed expiry: idle timeout, refresh at least every ~30 days"
        else (.refresh_expires_at - $now | dur) end),
      last_refreshed: ((.obtained_at // 0) | strflocaltime("%Y-%m-%d %H:%M:%S %Z")),
      has_access_token: (.access_token != null),
      has_refresh_token: (.refresh_token != null),
      has_id_token: (.id_token != null),
      token_file: $file
    }' <<<"$CACHE"
  # Decoded access-token claims: who/what it was issued for.
  jq -r '.access_token // empty' <<<"$CACHE" | jwt_payload | jq '{iss, azp, preferred_username, aud, scope, exp}'
}

brief() {
  jq -r --arg src "$1" --argjson now "$(now)" "$JQ_DUR"'
    "SENSE token ok (\($src)): \(.user // "unknown user"). Exported to SENSE_ACCESS_TOKEN"
    + (if .offline then ", offline session" else "" end)
    + ", access token valid \((.expires_at // 0) - $now | dur)"' <<<"$CACHE"
}

do_logout() {
  local rt code
  acquire_lock
  load_cache
  rt=$(jq -r '.refresh_token // empty' <<<"$CACHE")
  if [[ -n $rt ]]; then
    # RFC 7009 revocation also ends an offline session; /logout is the fallback.
    code=$(printf %s "$rt" | curl -sS -o /dev/null -w '%{http_code}' "${CURL_OPTS[@]}" "$BASE/revoke" \
             -d client_id="$CLIENT_ID" -d token_type_hint=refresh_token --data-urlencode token@-) || code=000
    if [[ $code != 200 ]]; then
      code=$(printf %s "$rt" | curl -sS -o /dev/null -w '%{http_code}' "${CURL_OPTS[@]}" "$BASE/logout" \
               -d client_id="$CLIENT_ID" --data-urlencode refresh_token@-) || code=000
      if [[ $code != 200 && $code != 204 ]]; then
        warn "could not revoke the session at Keycloak (HTTP $code); deleting local tokens anyway"
      fi
    fi
  fi
  write_cache null
  release_lock
  say "Logged out of $KC (realm $REALM, client $CLIENT_ID)"
}

shell_init() {
  printf '# SENSE-O token helpers, generated by: %q --shell-init\n' "$SELF" >&3
  printf '_SENSE_LOGIN=%q\n_SENSE_TOKEN_FILE=%q\n' "$SELF" "$TOKEN_FILE" >&3
  cat >&3 <<'EOF'
_SENSE_NEXT_CHECK=0

# sense-login [--offline] [--force]: log in if needed, then export
# SENSE_ACCESS_TOKEN and SENSE_ACCESS_TOKEN_EXP in this shell. Use another
# Keycloak with: KC=https://... sense-login (this shell then sticks to it).
# --status, --logout, --token and --help are passed straight through.
sense-login() {
  local a rc out
  for a in "$@"; do
    case $a in
      --status|--logout|--token|--shell-init|-h|--help)
        SENSE_TOKEN_FILE=$_SENSE_TOKEN_FILE "$_SENSE_LOGIN" "$@"; rc=$?
        if [ "$a" = --logout ]; then unset SENSE_ACCESS_TOKEN SENSE_ACCESS_TOKEN_EXP; fi
        return $rc ;;
    esac
  done
  out=$(SENSE_TOKEN_FILE=$_SENSE_TOKEN_FILE "$_SENSE_LOGIN" --env "$@") || return
  eval "$out"
  _SENSE_NEXT_CHECK=$(( SENSE_ACCESS_TOKEN_EXP - ${SENSE_MIN_TTL:-60} ))
}

# Keeps SENSE_ACCESS_TOKEN fresh from the saved login without ever prompting.
# Runs before each prompt but calls the script only when the token is about
# to expire; after a failure it backs off for 5 minutes.
_sense_env_refresh() {
  local rc=$? now out
  if [ -f "$_SENSE_TOKEN_FILE" ]; then
    now=${EPOCHSECONDS:-$(date +%s)}
    if [ "$now" -ge "${_SENSE_NEXT_CHECK:-0}" ]; then
      if out=$(KC=${SENSE_KC:-${KC:-}} REALM=${SENSE_REALM:-${REALM:-}} CLIENT_ID=${SENSE_CLIENT_ID:-${CLIENT_ID:-}} \
               SENSE_TOKEN_FILE=$_SENSE_TOKEN_FILE "$_SENSE_LOGIN" --env --no-login --quiet 2>/dev/null); then
        eval "$out"
        _SENSE_NEXT_CHECK=$(( SENSE_ACCESS_TOKEN_EXP - ${SENSE_MIN_TTL:-60} ))
      else
        eval "$out"
        _SENSE_NEXT_CHECK=$(( now + 300 ))
      fi
    fi
  fi
  return $rc
}

case $- in
  *i*)
    if [ -f "$_SENSE_TOKEN_FILE" ]; then
      _sense_env_refresh
      if [ -z "${SENSE_ACCESS_TOKEN:-}" ]; then
        echo "SENSE: saved login unusable (expired, revoked, or server unreachable); run: sense-login" >&2
      fi
    fi
    if [ -n "${ZSH_VERSION:-}" ]; then
      autoload -Uz add-zsh-hook && add-zsh-hook precmd _sense_env_refresh
    elif [ -n "${BASH_VERSION:-}" ]; then
      case ";${PROMPT_COMMAND:-};" in
        *";_sense_env_refresh;"*) ;;
        *) PROMPT_COMMAND="_sense_env_refresh${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;;
      esac
    fi ;;
esac
EOF
}

case $MODE in
  shell_init) shell_init ;;
  logout)     do_logout ;;
  status)
    load_cache
    others=$(other_logins)
    if [[ $CACHE == '{}' ]]; then say "No SENSE login cached for $KC (realm $REALM, client $CLIENT_ID)"
    else describe cache-file; fi
    if [[ -n $others ]]; then
      say "Other cached logins (pick one with KC=... REALM=... CLIENT_ID=...):"
      say "$(sed 's/^/  /' <<<"$others")"
    fi
    [[ $CACHE != '{}' ]] ;;
  *)
    ensure_token
    case $MODE in
      token)   checked_access_token >&3; echo >&3 ;;
      env)     emit_env; brief "$SOURCE" ;;
      summary) say "SUCCESS (token from: $SOURCE)"; describe "$SOURCE" ;;
    esac ;;
esac
