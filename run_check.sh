#!/usr/bin/env bash
set -euo pipefail

MOON="${MOON:-moon}"

if ! command -v "$MOON" >/dev/null 2>&1; then
  if [ -n "${HOME:-}" ] && [ -x "$HOME/.moon/bin/moon" ]; then
    export PATH="$HOME/.moon/bin:$PATH"
  elif [ -n "${USERPROFILE:-}" ] && command -v cygpath >/dev/null 2>&1; then
    MOON_HOME="$(cygpath -u "$USERPROFILE")/.moon/bin"
    if [ -x "$MOON_HOME/moon" ]; then
      export PATH="$MOON_HOME:$PATH"
    fi
  elif [ -d /mnt/c/Users ]; then
    for MOON_HOME in /mnt/c/Users/*/.moon/bin; do
      if [ -x "$MOON_HOME/moon.exe" ]; then
        export PATH="$MOON_HOME:$PATH"
        MOON="moon.exe"
        break
      fi
    done
  fi
fi

"$MOON" fmt --check
"$MOON" info
git diff --exit-code -- '*.mbti'
"$MOON" check --deny-warn
"$MOON" build --deny-warn
"$MOON" test --deny-warn
"$MOON" run cmd/demo
"$MOON" run cmd/track
"$MOON" run cmd/query
"$MOON" run cmd/bench
