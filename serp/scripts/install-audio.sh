#!/usr/bin/env bash
set -euo pipefail

REPO="ilyamiro/serpantinum-audio"
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
LICENSE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/licenses/serpantinum-audio"

fail() {
    echo "serpantinum-audio: $*" >&2
    exit 1
}

case "$(uname -m)" in
    x86_64|amd64) arch="x86_64" ;;
    aarch64|arm64) arch="aarch64" ;;
    *) fail "no prebuilt release for $(uname -m)" ;;
esac

for tool in curl jq tar sha256sum; do
    command -v "$tool" >/dev/null 2>&1 || fail "$tool is required"
done

echo "Checking the latest serpantinum-audio release..."
json="$(curl -fsSL --connect-timeout 15 --retry 3 "https://api.github.com/repos/$REPO/releases/latest")" || fail "could not reach GitHub"
tag="$(jq -r '.tag_name // empty' <<< "$json")"
[ -n "$tag" ] || fail "the latest release has no tag"
version="${tag#v}"

existing="$(PATH="$PATH:$BIN_DIR" command -v serpantinum-audio || true)"
current=""
[ -n "$existing" ] && current="$("$existing" version 2>/dev/null | awk '{print $2}')"

if [ "$current" = "$version" ]; then
    echo "serpantinum-audio $version is already installed at $existing"
    "$existing" start >/dev/null 2>&1 || true
    exit 0
fi

tarball_url="$(jq -r --arg re "-${arch}-linux\\.tar\\.gz$" '[.assets[] | select(.name | test($re))][0].browser_download_url // empty' <<< "$json")"
sums_url="$(jq -r '[.assets[] | select(.name == "SHA256SUMS")][0].browser_download_url // empty' <<< "$json")"
[ -n "$tarball_url" ] && [ -n "$sums_url" ] || fail "release $tag has no $arch build"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
archive="$work/${tarball_url##*/}"

echo "Downloading serpantinum-audio $version for $arch..."
curl -fsSL --connect-timeout 15 --retry 3 "$tarball_url" -o "$archive" || fail "download failed"
curl -fsSL --connect-timeout 15 --retry 3 "$sums_url" -o "$work/SHA256SUMS" || fail "checksum download failed"

(cd "$work" && grep -F " ${archive##*/}" SHA256SUMS | sha256sum -c --quiet -) || fail "checksum verification failed, nothing was installed"
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

echo "Installed serpantinum-audio $version to $BIN_DIR"
if [ -n "$existing" ] && [ "$existing" != "$BIN_DIR/serpantinum-audio" ]; then
    echo "Note: an older copy at $existing comes first on PATH. Update it with the Serpantinum installer or remove it."
fi
[ "$running" = true ] && echo "Restarted the running daemon"
exit 0
