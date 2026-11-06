#!/usr/bin/env bash
# Installe butler (client itch.io, MIT) dans <dir>/butler depuis broth, à une
# version épinglée. Idempotent. Usage : tools/install_butler.sh [dir]
set -eu
VERSION="${BUTLER_VERSION:-15.32.0}"
DIR="${1:-$HOME/butler-bin}"
mkdir -p "$DIR"
if [ ! -x "$DIR/butler" ] || ! "$DIR/butler" -V 2>&1 | grep -q "v$VERSION"; then
	curl -sSL -o "$DIR/butler.zip" "https://broth.itch.zone/butler/linux-amd64/${VERSION}/archive/default"
	unzip -q -o "$DIR/butler.zip" -d "$DIR"
	chmod +x "$DIR/butler"
	rm -f "$DIR/butler.zip"
fi
"$DIR/butler" -V 2>&1
