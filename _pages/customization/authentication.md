---
title: "Authentication Configuration"
layout: single
classes: wide
permalink: "/customization/authentication/"
author_profile: false
sidebar:
  nav: "docs"
---

## Overview

SiteRM 1.6.0 introduces a fully replaced authentication system. All API calls — from human users via the Web UI, from Agents and Debuggers, and from external tools — use **JWT Bearer tokens** obtained through one of three authentication flows:

| Method | Who uses it | Endpoint |
|---|---|---|
| Username/password | Human users, Web UI | `POST /auth/login` |
| X.509 certificate M2M | Agents, Debuggers, automated services | `POST /m2m/token` → `POST /m2m/token/{id}` |
| Token refresh | Any authenticated session | `POST /m2m/token/refresh` |

Tokens are signed with **RS256** (RSA 3072-bit, SHA-256). The signing key pair is auto-generated at Frontend startup. Standard OIDC discovery endpoints allow third-party tools to verify tokens:

- `GET /.well-known/jwks.json` — JSON Web Key Set
- `GET /.well-known/openid-configuration` — OpenID Provider Metadata

---

## Token Lifetime

| Token | Default lifetime | Configurable via |
|---|---|---|
| Access token (Bearer) | 60 minutes | `OIDC_TOKEN_LIFETIME_MINUTES` |
| Refresh token | 12 hours | `REFRESH_TOKEN_TTL_HOURS` |

Tokens are renewed automatically by Agents using the refresh flow. If a refresh token expires, the Agent re-authenticates using the X.509 certificate challenge.

---

## User Management (`siterm-usertool`)

Human users and Web UI logins require a local account in the Frontend database. Accounts are managed with `siterm-usertool` inside the Frontend container.

### Create a user

```bash
docker exec -it siterm-fe bash
siterm-usertool --action create --username admin --permissions admin
# Enter password when prompted (minimum 12 characters)
```

For Kubernetes:
```bash
kubectl exec -n sense <siterm-fe-pod> -- siterm-usertool --action create --username admin --permissions admin
```

### Permission levels

| Level | Value | Access |
|---|---|---|
| `read` | 1 | Read-only API access |
| `write` | 2 | Write-only API access |
| `readwrite` | 3 | Full read/write API access |
| `admin` | 4 | Full access including user management |

### Other user management commands

```bash
# List all users
siterm-usertool --action list

# Disable a user (blocks login, does not delete)
siterm-usertool --action disable --username someuser

# Re-enable a disabled user
siterm-usertool --action enable --username someuser

# Change a user's password
siterm-usertool --action setpassword --username someuser

# Delete a user permanently
siterm-usertool --action delete --username someuser
```

### Password policy

- Minimum 12 characters
- Stored with Argon2id hashing (time cost: 3, memory: 64 MB, parallelism: 4)
- Hash parameters are configurable via environment variables (see below)

---

## Username/Password Login Flow

Used by the Web UI and any human operator using the REST API directly.

```bash
# Login — returns access_token and refresh_token
curl -X POST https://<FE_HOST>/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "your-password"}'

# Response:
{
  "access_token": "eyJ...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "expires_at": 1742000000,
  "refresh_token": "eyJ...",
  "session_id": "abc123..."
}

# Use the token
curl -H "Authorization: Bearer eyJ..." https://<FE_HOST>/api/<site>/...

# Check your identity
curl -H "Authorization: Bearer eyJ..." https://<FE_HOST>/auth/whoami
```

The Web UI handles login automatically — click the **Login** button in the Swagger UI or navigate to the Frontend Web UI; you will be prompted to enter credentials.

---

## X.509 Certificate M2M Flow

Used by Agents, Debuggers, and any service that authenticates using a host certificate and private key. This is a **two-step challenge-response flow**:

### Step 1 — Submit certificate, receive challenge

```bash
curl -X POST https://<FE_HOST>/m2m/token \
  -H "Content-Type: application/json" \
  -d '{"certificate": "<PEM-encoded cert>", "session_id": "<unique-session-id>"}'

# Response:
{
  "challenge": "<base64-encoded-random-bytes>",
  "ref_url": "/m2m/token/<challenge-id>"
}
```

### Step 2 — Sign the challenge with the private key, submit signature

```python
import base64, hashlib
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, ec

# Load private key
with open("/etc/secret-mount/tls.key", "rb") as f:
    private_key = serialization.load_pem_private_key(f.read(), password=None)

challenge_bytes = base64.b64decode(challenge)

# RSA key:
signature = private_key.sign(challenge_bytes, padding.PSS(
    mgf=padding.MGF1(hashes.SHA256()), salt_length=padding.PSS.MAX_LENGTH), hashes.SHA256())

# EC key:
# signature = private_key.sign(challenge_bytes, ec.ECDSA(hashes.SHA256()))

sig_b64 = base64.b64encode(signature).decode()
```

```bash
curl -X POST https://<FE_HOST>/m2m/token/<challenge-id> \
  -H "Content-Type: application/json" \
  -d '{"signature": "<base64-signature>", "session_id": "<same-session-id>"}'

# Response: same format as /auth/login — access_token + refresh_token
```

The Agent and Debugger perform this flow **automatically** using `SiteRMLibs/HTTPLibrary.py`. No manual configuration is needed beyond providing the host certificate and private key as usual.

---

## Token Refresh Flow

Refresh tokens are valid for 12 hours. On each refresh, a **new refresh token is issued** (rotation) — the old one is revoked. Refresh tokens are **bound to the client IP address**: only the same IP that obtained the token can refresh it.

```bash
curl -X POST https://<FE_HOST>/m2m/token/refresh \
  -H "Content-Type: application/json" \
  -d '{"session_id": "<session-id>", "refresh_token": "<refresh-token>"}'

# Response: new access_token + new refresh_token (old refresh_token is revoked)
```

If the refresh token is expired or revoked, the Agent falls back to a full certificate challenge automatically.

---

## Trust Store — Which CAs are Accepted

The Frontend validates X.509 certificates against a filtered trust store built from `/etc/grid-security/certificates`. By default, only certificates from the following CA issuers are accepted:

- Let's Encrypt (`R*` series)
- InCommon RSA CA
- CERN Grid CAs

### Customizing the trusted CAs

Create `/etc/grid-security/allowed_truststore.yaml` inside the Frontend container (or mount it via Docker volume / Kubernetes ConfigMap):

```yaml
allowed_issuers:
  - "Let's Encrypt"
  - "InCommon RSA Server CA"
  - "CERN Grid Certification Authority"
  - "GEANT TCS"                   # Add your site's CA here
```

The truststore is rebuilt on each Frontend startup. Certificates from CAs not in this list will be **rejected** with a 403 error even if technically valid.

To check which CAs are currently trusted, inspect the container:
```bash
docker exec -it siterm-fe ls /etc/grid-security/truststore/
```

---

## JWT Key Pair — Auto-generation and Rotation

The Frontend auto-generates an RSA-3072 key pair at startup if one does not already exist:

- Private key: `/opt/siterm/jwt_secrets/private_key.pem` (mode 0600, owned by Apache)
- Public key: `/opt/siterm/jwt_secrets/public_key.pem` (mode 0644)

**Key rotation:** To rotate keys without a service interruption, place the new key as the active key and move the old key to the `_prev` paths:
- `/opt/siterm/jwt_secrets/private_key_prev.pem`
- `/opt/siterm/jwt_secrets/public_key_prev.pem`

The Frontend validates tokens against both the current and previous key pair, so in-flight tokens remain valid during rotation.

To force key regeneration, delete the key files and restart the Frontend.

### Configuring key size and location

| Environment variable | Default | Description |
|---|---|---|
| `RSA_DIR` | `/opt/siterm/jwt_secrets` | Directory for JWT key files |
| `RSA_KEY_SIZE` | `3072` | RSA key size in bits |
| `RSA_PUBLIC_EXPONENT` | `65537` | RSA public exponent |

---

## OIDC Configuration Parameters

These environment variables control token behavior. Set them in your Docker `run.sh` or Helm `values.yaml`:

| Variable | Default | Description |
|---|---|---|
| `OIDC_TOKEN_LIFETIME_MINUTES` | `60` | Access token lifetime in minutes |
| `REFRESH_TOKEN_TTL_HOURS` | `12` | Refresh token lifetime in hours |
| `OIDC_LEEWAY` | `60` | Clock skew tolerance in seconds |
| `OIDC_ALGORITHM` | `RS256` | JWT signing algorithm |
| `OIDC_APP_NAME` | `SITERM Token Issuer` | Issuer name in token metadata |
| `OIDC_CA_DIR` | `/etc/grid-security/truststore/` | Trusted CA directory for X.509 M2M |

### Argon2 password hashing parameters

| Variable | Default | Description |
|---|---|---|
| `ARGON2_TIME_COST` | `3` | Number of iterations |
| `ARGON2_MEMORY_COST` | `65536` | Memory in KiB (64 MB) |
| `ARGON2_PARALLELISM` | `4` | Parallel threads |
| `ARGON2_HASH_LEN` | `32` | Output hash length in bytes |

---

## Rate Limiting

Auth endpoints are rate-limited to prevent brute-force attacks:

- Default: **1 request per second per client IP**
- On receiving a `429 Too Many Requests`, clients wait a random 10–30 seconds before retrying
- This is handled automatically by the Agent's HTTP library

---

## Database Tables

Two new tables are created automatically by Alembic migration on Frontend startup:

**`users`** — local user accounts:

| Column | Type | Description |
|---|---|---|
| `id` | UUID | Primary key |
| `username` | String(128) | Unique login name |
| `password_hash` | Text | Argon2id hash |
| `display_name` | String(255) | Optional display name |
| `permissions` | Integer | 1=read, 2=write, 3=readwrite, 4=admin |
| `disabled` | Boolean | Account disabled flag |
| `created_at` | Integer | Unix timestamp |
| `updated_at` | Integer | Unix timestamp |
| `password_changed_at` | Integer | Unix timestamp |

**`refresh_tokens`** — active refresh token sessions:

| Column | Type | Description |
|---|---|---|
| `id` | Integer | Auto-increment primary key |
| `username` | String | Owning user |
| `client_ip` | String(64) | IP address that obtained the token |
| `token_hash` | String(64) | SHA-256 hash of the refresh token |
| `session_id` | String(64) | Session identifier |
| `expires_at` | Integer | Unix expiry timestamp |
| `permissions` | Integer | Permission level at issue time |
| `revoked` | Boolean | True if rotated or logged out |
| `rotated_from` | String(64) | Hash of the previous token (audit trail) |

---

## Agent and Debugger Authentication

Agents and Debuggers authenticate to the Frontend automatically using the M2M certificate challenge flow. The host certificate and private key are used to sign challenges — the same files that were used for direct certificate auth in previous releases.

**No changes are needed to Agent/Debugger configuration.** The certificate paths are:
- Certificate: `agent/conf/etc/secret-mount/tls.crt`
- Private key: `agent/conf/etc/secret-mount/tls.key`

The Agent's `HTTPLibrary.py` handles the full flow:
1. Checks if the current Bearer token is valid (expires within 2 minutes → refresh)
2. If refresh token is available: posts session ID + refresh token to `/m2m/token/refresh`
3. If refresh fails or no token: performs full X.509 challenge-response against `/m2m/token`
4. Stores the new Bearer token and refresh token for subsequent calls

**Note:** Agent and Debugger containers no longer require host certificates for the purpose of API authentication alone. However, if your site uses certificates for other purposes (TLS, SNMP), keep them mounted as before.

---

## Web UI Login

The Frontend Web UI uses token-based authentication for all API calls starting in 1.6.0.

1. Navigate to `https://<FE_HOST>/`
2. Click **Login** in the top navigation
3. Enter your username and password (created with `siterm-usertool`)
4. The Web UI stores the Bearer token in the browser session and sends it with all API requests
5. The Swagger UI (`https://<FE_HOST>/docs`) also shows a **Authorize** button — click it and enter `Bearer <token>` to authorize API calls from the Swagger interface

Tokens expire after 60 minutes. The Web UI will prompt you to log in again when the token expires.

---

## Upgrading from 1.5.63

1. **Create at least one admin user before restarting the Frontend.** Pull the new image, enter the container interactively (do not start services yet), and run:
   ```bash
   siterm-usertool --action create --username admin --permissions admin
   ```

2. **Start the new Frontend.** Alembic migrations run automatically and create the `users` and `refresh_tokens` tables.

3. **Verify auth is working:**
   ```bash
   curl -X POST https://<FE_HOST>/auth/login \
     -d '{"username":"admin","password":"<your-password"}' \
     -H "Content-Type: application/json"
   # Should return access_token
   ```

4. **No changes needed for Agents/Debuggers** — they re-authenticate automatically using the M2M flow on next restart.

5. **Review your trust store** if your site uses custom CAs for X.509 M2M. See the [Trust Store](#trust-store--which-cas-are-accepted) section above.

---

## Troubleshooting

| Symptom | Likely cause | Resolution |
|---|---|---|
| `401 Unauthorized` on all API calls | Token missing or expired | Log in again with `siterm-usertool` or re-issue credentials |
| `403 Forbidden` on M2M auth | Certificate CA not in trust store | Add CA to `allowed_truststore.yaml` and restart Frontend |
| `429 Too Many Requests` on auth | Rate limit hit | Clients back off automatically; reduce request frequency |
| `users` table not found | Alembic migration did not run | Check Frontend startup logs; ensure DB is accessible |
| Agent fails with auth error | Certificate or key path wrong | Verify `tls.crt` and `tls.key` are mounted and readable under `secret-mount/` |
| Web UI redirects to login repeatedly | Token lifetime too short | Increase `OIDC_TOKEN_LIFETIME_MINUTES` or check clock skew |
| Key pair not generated | `RSA_DIR` not writable by Apache | Check directory permissions; must be owned by the Apache user |

---

## See Also

- [Enable Switch Control](/customization/enable-switch-control/) — Ansible inventory and SSH key configuration
- [Frontend Configuration](/customization/configuration-frontend/) — Full `siterm.yaml` and environment variable reference
- [Release Notes](/docs/release-notes/) — 1.6.0 upgrade instructions
