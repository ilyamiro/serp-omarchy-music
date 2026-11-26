#!/usr/bin/env bash

declare -F qs_ensure_cache >/dev/null && return 0

export PATH="$PATH:$HOME/.local/bin"
export QS_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/serpantinum"
export QS_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/serpantinum"
export QS_RUN_DIR="${XDG_RUNTIME_DIR:-/tmp}/serpantinum"

qs_ensure_cache() {
    local name="$1" upper="${1^^}"
    local cache="$QS_CACHE_DIR/$name" state="$QS_STATE_DIR/$name" run="$QS_RUN_DIR/$name"
    [[ -d "$cache" && -d "$state" && -d "$run" ]] || mkdir -p "$cache" "$state" "$run"
    export "QS_CACHE_${upper}=$cache" "QS_STATE_${upper}=$state" "QS_RUN_${upper}=$run"
}
