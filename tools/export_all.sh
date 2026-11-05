#!/usr/bin/env bash
# Exporte le jeu pour Linux, Windows et macOS dans export/.
# Les export templates 4.7.2 doivent être installés (tools/install_godot.sh --templates).
set -eu
GODOT="${GODOT:-godot}"
mkdir -p export/linux export/windows export/macos
"$GODOT" --headless --path . --import > /dev/null 2>&1
"$GODOT" --headless --path . --export-release Linux export/linux/stackmates.x86_64
"$GODOT" --headless --path . --export-release Windows export/windows/stackmates.exe
"$GODOT" --headless --path . --export-release macOS export/macos/stackmates.zip
ls -l export/*/
