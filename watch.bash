#!/usr/bin/env bash
set -eu

log() {
    echo "$(date): $*"
}

build() {
    log "Building..."

    if ruby build.rb; then
        log "Build!"
    else
        log "Failed to build!"
    fi
}

build

fswatch -e "$PWD/build/" . | (while read; do build; done)
