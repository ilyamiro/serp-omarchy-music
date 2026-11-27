#!/usr/bin/env bash
set -euo pipefail

REPO="ilyamiro/serpantinum-audio"
VERSION="0.4.0"
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
LICENSE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/licenses/serpantinum-audio"

fail() {
    echo "serpantinum-audio: $*" >&2
    exit 1
}

case "$(uname -m)" in
    x86_64|amd64)
        arch="x86_64"
        sha256="8c1ac960b3bf6a6f06ac9d0ffb6a7a92ef32b06be7aec28de5d915db6b46f28d"
        ;;
    aarch64|arm64)
        arch="aarch64"
        sha256="e074fd31471e0190424f2d761bbc6ff647d40da94e50af2c3818fd8925e7b535"
        ;;
    *) fail "no prebuilt release for $(uname -m)" ;;
esac

for tool in curl tar sha256sum; do
    command -v "$tool" >/dev/null 2>&1 || fail "$tool is required"
done

existing="$(PATH="$PATH:$BIN_DIR" command -v serpantinum-audio || true)"
current=""
[ -n "$existing" ] && current="$("$existing" version 2>/dev/null | awk '{print $2}')"

if [ "$current" = "$VERSION" ]; then
    echo "serpantinum-audio $VERSION is already installed at $existing"
    "$existing" start >/dev/null 2>&1 || true
    exit 0
fi

tarball="serpantinum-audio-$VERSION-$arch-linux.tar.gz"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
archive="$work/$tarball"

echo "Downloading serpantinum-audio $VERSION for $arch..."
curl -fsSL --connect-timeout 15 --retry 3 "https://github.com/$REPO/releases/download/v$VERSION/$tarball" -o "$archive" || fail "download failed"

echo "$sha256  $archive" | sha256sum -c --quiet - || fail "checksum verification failed, nothing was installed"
echo "Checksum verified"

mkdir -p "$work/stage"
tar -xzf "$archive" -C "$work/stage"
"$work/stage/usr/bin/serpantinum-audio" version >/dev/null 2>&1 || fail "the downloaded binary does not run on this system"

running=false
if [ -n "$existing" ] && "$existing" ctl status >/dev/null 2>&1; then
    running=true
    "$existing" ctl quit >/dev/null 2>&1 || true
fi

install -Dm755 "$work/stage/usr/bin/serpantinum-audio" "$BIN_DIR/serpantinum-audio"
if [ -f "$work/stage/usr/share/licenses/serpantinum-audio/LICENSE" ]; then
    install -Dm644 "$work/stage/usr/share/licenses/serpantinum-audio/LICENSE" "$LICENSE_DIR/LICENSE"
fi

"$BIN_DIR/serpantinum-audio" start >/dev/null 2>&1 || fail "installed, but the daemon did not start"

echo "Installed serpantinum-audio $VERSION to $BIN_DIR"
if [ -n "$existing" ] && [ "$existing" != "$BIN_DIR/serpantinum-audio" ]; then
    echo "Note: an older copy at $existing comes first on PATH. Update it with the Serpantinum installer or remove it."
fi
[ "$running" = true ] && echo "Restarted the running daemon"
exit 0
