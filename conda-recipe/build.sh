#!/usr/bin/env bash
set -euo pipefail

src_root="${SRC_DIR}/ampwrap"
dst_root="${PREFIX}/bin"

install_path() {
    local src="$1"
    local base
    base="$(basename "$src")"
    local dst="${dst_root}/${base}"

    if [ -d "$src" ]; then
        mkdir -p "$dst"
        cp -a "$src"/. "$dst"/
        chmod -R u+rwX,go+rX "$dst"
    else
        install -m 0755 "$src" "$dst"
    fi
}

mkdir -p "$dst_root"
cd "$src_root"

for item in AmpWrap_db AmpWrap_long AmpWrap_short ampwrap scripts snakefile.long snakefile.short VERSION
do
    install_path "$item"
done
