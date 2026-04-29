#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$ROOT_DIR/src-tauri/target/release/bundle/macos/Copyosity.app"
APP_BINARY="$ROOT_DIR/src-tauri/target/release/copyosity"
RUNNER_NAME="copyosity-runner"

if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "App bundle not found: $APP_BUNDLE" >&2
  exit 1
fi

if [[ ! -x "$APP_BINARY" ]]; then
  echo "App binary not found: $APP_BINARY" >&2
  exit 1
fi

cp "$APP_BINARY" "$APP_BUNDLE/Contents/Resources/$RUNNER_NAME"
chmod +x "$APP_BUNDLE/Contents/Resources/$RUNNER_NAME"

cat > "$APP_BUNDLE/Contents/MacOS/copyosity" <<'SH'
#!/bin/sh
set -eu

APP_SUPPORT="$HOME/Library/Application Support/Copyosity"
RUNNER="$APP_SUPPORT/copyosity-runner"
SOURCE="$(dirname "$0")/../Resources/copyosity-runner"

mkdir -p "$APP_SUPPORT"
if [ ! -f "$RUNNER" ] || [ "$SOURCE" -nt "$RUNNER" ]; then
  cp "$SOURCE" "$RUNNER"
  chmod +x "$RUNNER"
fi

if pgrep -fx "$RUNNER" >/dev/null 2>&1; then
  exit 0
fi

nohup "$RUNNER" >/tmp/copyosity.log 2>&1 &
exit 0
SH
chmod +x "$APP_BUNDLE/Contents/MacOS/copyosity"

dot_clean -m "$APP_BUNDLE"
find "$APP_BUNDLE" -name '._*' -delete
xattr -cr "$APP_BUNDLE"
codesign --force --deep --sign - "$APP_BUNDLE"
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

echo "$APP_BUNDLE"
