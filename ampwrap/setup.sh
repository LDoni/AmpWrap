#!/usr/bin/env bash
set -euo pipefail

install_path() {
	local src="$1"
	local dst_root="${CONDA_PREFIX}/bin"
	local dst="${dst_root}/$(basename "$src")"

	if [ -d "$src" ]; then
		mkdir -p "$dst"
		cp -a "$src"/. "$dst"/
		chmod -R +x "$dst"
	else
		cp -f "$src" "$dst_root"/
		chmod +x "$dst"
	fi
}

for i in AmpWrap_db AmpWrap_long AmpWrap_short ampwrap scripts snakefile.long snakefile.short VERSION
do
	install_path "$i"
done
