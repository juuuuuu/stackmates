#!/usr/bin/env bash
# Installe le binaire Godot (Linux x86_64) dans <dir>/godot.
# Avec --templates, installe aussi les export templates dans
# ~/.local/share/godot/export_templates/<version>.stable/.
# Idempotent : ne retélécharge rien de déjà présent.
# Usage : tools/install_godot.sh [dir] [--templates]
set -eu
VERSION="${GODOT_VERSION:-4.7.2}"
DIR="${1:-$HOME/godot-bin}"
WITH_TEMPLATES=0
if [ "${2:-}" = "--templates" ]; then
	WITH_TEMPLATES=1
fi
BASE="https://github.com/godotengine/godot-builds/releases/download/${VERSION}-stable"
mkdir -p "$DIR"
if [ ! -x "$DIR/godot" ]; then
	curl -fsSL -o "$DIR/godot.zip" "$BASE/Godot_v${VERSION}-stable_linux.x86_64.zip"
	unzip -q -o "$DIR/godot.zip" -d "$DIR"
	mv "$DIR/Godot_v${VERSION}-stable_linux.x86_64" "$DIR/godot"
	chmod +x "$DIR/godot"
	rm -f "$DIR/godot.zip"
fi
"$DIR/godot" --version
if [ "$WITH_TEMPLATES" = 1 ]; then
	TEMPLATES_DIR="$HOME/.local/share/godot/export_templates/${VERSION}.stable"
	if [ ! -f "$TEMPLATES_DIR/version.txt" ]; then
		TPZ="$DIR/templates.tpz"
		if [ ! -f "$TPZ" ]; then
			curl -fsSL -o "$TPZ" "$BASE/Godot_v${VERSION}-stable_export_templates.tpz"
		fi
		rm -rf "$DIR/templates_tmp"
		unzip -q -o "$TPZ" -d "$DIR/templates_tmp"
		mkdir -p "$TEMPLATES_DIR"
		mv "$DIR/templates_tmp/templates/"* "$TEMPLATES_DIR/"
		rm -rf "$DIR/templates_tmp" "$TPZ"
	fi
	echo "export templates : $TEMPLATES_DIR"
fi
