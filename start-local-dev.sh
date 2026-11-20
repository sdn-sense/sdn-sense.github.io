#!/usr/bin/env bash

set -euo pipefail

site_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$site_dir"

is_supported_ruby() {
  local candidate="$1"

  [[ -x "$candidate" ]] || return 1
  "$candidate" -e 'exit RUBY_VERSION.start_with?("3.") ? 0 : 1' >/dev/null 2>&1
}

if [[ -n "${SDN_SENSE_RUBY:-}" ]]; then
  if ! is_supported_ruby "$SDN_SENSE_RUBY"; then
    printf 'SDN_SENSE_RUBY must point to a Ruby 3 executable: %s\n' "$SDN_SENSE_RUBY" >&2
    exit 1
  fi
  ruby_bin="$SDN_SENSE_RUBY"
else
  ruby_candidates=()

  if active_ruby="$(command -v ruby 2>/dev/null)"; then
    ruby_candidates+=("$active_ruby")
  fi

  if command -v brew >/dev/null 2>&1; then
    for formula in ruby@3.3 ruby@3.4; do
      if formula_prefix="$(brew --prefix "$formula" 2>/dev/null)"; then
        ruby_candidates+=("$formula_prefix/bin/ruby")
      fi
    done
  fi

  ruby_candidates+=(
    "/usr/local/opt/ruby@3.3/bin/ruby"
    "/usr/local/opt/ruby@3.4/bin/ruby"
    "/opt/homebrew/opt/ruby@3.3/bin/ruby"
    "/opt/homebrew/opt/ruby@3.4/bin/ruby"
  )

  ruby_bin=""
  for candidate in "${ruby_candidates[@]}"; do
    if is_supported_ruby "$candidate"; then
      ruby_bin="$candidate"
      break
    fi
  done

  if [[ -z "$ruby_bin" ]]; then
    cat >&2 <<'MESSAGE'
No compatible Ruby 3 installation was found. Ruby 4 cannot resolve the
GitHub Pages 232 dependency set used by this site.

Install the CI-compatible runtime, then run this script again:

  brew install ruby@3.3

You may also select an existing Ruby 3 executable explicitly:

  SDN_SENSE_RUBY=/path/to/ruby ./start-local-dev.sh
MESSAGE
    exit 1
  fi
fi

ruby_bin_dir="$(cd -- "$(dirname -- "$ruby_bin")" && pwd)"
ruby_bin="$ruby_bin_dir/ruby"
export PATH="$ruby_bin_dir:$PATH"

ruby_version="$("$ruby_bin" -e 'print RUBY_VERSION')"
printf 'Using Ruby %s (%s)\n' "$ruby_version" "$ruby_bin"

if [[ "${1:-}" == "--check-runtime" ]]; then
  exit 0
fi

export BUNDLE_WITHOUT="${BUNDLE_WITHOUT:-test}"

if "$ruby_bin" -S bundle --version >/dev/null 2>&1 && "$ruby_bin" -S bundle check >/dev/null 2>&1; then
  printf 'Starting the SDN-Sense development server with the pinned bundle...\n'
  exec "$ruby_bin" -S bundle exec jekyll serve --livereload "$@"
fi

gem_bindir="$("$ruby_bin" -rrubygems -e 'print Gem.bindir')"
jekyll_bin="$gem_bindir/jekyll"

if [[ -f "$jekyll_bin" ]]; then
  jekyll_version="$(JEKYLL_NO_BUNDLER_REQUIRE=true "$ruby_bin" "$jekyll_bin" --version 2>/dev/null || true)"
  if [[ "$jekyll_version" == "jekyll 3.10."* ]]; then
    printf 'The pinned bundle is incomplete; using the compatible installed %s.\n' "$jekyll_version"
    printf 'Starting the SDN-Sense development server...\n'
    exec env JEKYLL_NO_BUNDLER_REQUIRE=true "$ruby_bin" "$jekyll_bin" serve --livereload "$@"
  fi
fi

if ! "$ruby_bin" -S bundle --version >/dev/null 2>&1; then
  printf 'Bundler is missing for Ruby %s; installing it now...\n' "$ruby_version"
  "$ruby_bin" -S gem install bundler
fi

printf 'Installing the site dependencies...\n'
"$ruby_bin" -S bundle install

printf 'Starting the SDN-Sense development server with the pinned bundle...\n'
exec "$ruby_bin" -S bundle exec jekyll serve --livereload "$@"
