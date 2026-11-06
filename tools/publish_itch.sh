#!/usr/bin/env bash
# Pousse les trois zips de dist/ sur itch.io avec butler.
# Usage : ITCH_TARGET=user/stackmates BUTLER_API_KEY=... tools/publish_itch.sh vX.Y.Z
# BUTLER : binaire butler (défaut : butler). DIST : dossier des zips (défaut : dist).
# Les trois zips sont vérifiés avant le premier push : jamais de release partielle.
set -eu
TAG="${1:?usage: publish_itch.sh vX.Y.Z}"
: "${ITCH_TARGET:?ITCH_TARGET manquant (user/stackmates)}"
: "${BUTLER_API_KEY:?BUTLER_API_KEY manquant}"
BUTLER="${BUTLER:-butler}"
DIST="${DIST:-dist}"
VERSION="${TAG#v}"
CHANNELS="linux:linux windows:windows macos:mac"
for pair in $CHANNELS; do
	platform="${pair%%:*}"
	zip="$DIST/stackmates-$TAG-$platform.zip"
	if [ ! -f "$zip" ]; then
		echo "publish_itch: $zip manquant" >&2
		exit 1
	fi
done
for pair in $CHANNELS; do
	platform="${pair%%:*}"
	channel="${pair##*:}"
	"$BUTLER" push "$DIST/stackmates-$TAG-$platform.zip" "$ITCH_TARGET:$channel" \
		--userversion "$VERSION"
done
echo "publish_itch: $ITCH_TARGET $VERSION publié (linux, windows, mac)"
