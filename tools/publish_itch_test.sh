#!/usr/bin/env bash
# Teste tools/publish_itch.sh avec un faux butler qui enregistre ses arguments.
# Sort en 0 avec « publish_itch_test: OK », sinon en 1 avec le cas en échec.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$ROOT/tools/publish_itch.sh"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/publish_itch_test.XXXXXX")"
trap 'rm -r "$WORK"' EXIT
FAKE="$WORK/butler"
CALLS="$WORK/calls"
DIST="$WORK/dist"
printf '#!/usr/bin/env bash\necho "$*" >> "%s"\n' "$CALLS" > "$FAKE"
chmod +x "$FAKE"
FAILED=0

fail() {
	echo "publish_itch_test: FAIL: $1"
	FAILED=1
}

prepare() {
	rm -rf "$DIST"
	mkdir -p "$DIST"
	for platform in linux windows macos; do
		: > "$DIST/stackmates-v0.3.0-$platform.zip"
	done
	: > "$CALLS"
}

# Cas nominal : trois push dans l'ordre, version sans le v.
prepare
if ITCH_TARGET=someone/stackmates BUTLER_API_KEY=x BUTLER="$FAKE" DIST="$DIST" \
	bash "$SCRIPT" v0.3.0 > "$WORK/out" 2>&1; then
	EXPECTED="push $DIST/stackmates-v0.3.0-linux.zip someone/stackmates:linux --userversion 0.3.0
push $DIST/stackmates-v0.3.0-windows.zip someone/stackmates:windows --userversion 0.3.0
push $DIST/stackmates-v0.3.0-macos.zip someone/stackmates:mac --userversion 0.3.0"
	[ "$(cat "$CALLS")" = "$EXPECTED" ] || fail "nominal : appels inattendus : $(cat "$CALLS")"
else
	fail "nominal : exit $? : $(cat "$WORK/out")"
fi

# Zip macOS absent : échec avant tout push.
prepare
rm "$DIST/stackmates-v0.3.0-macos.zip"
if ITCH_TARGET=someone/stackmates BUTLER_API_KEY=x BUTLER="$FAKE" DIST="$DIST" \
	bash "$SCRIPT" v0.3.0 > "$WORK/out" 2>&1; then
	fail "zip manquant : devrait sortir en 1"
fi
[ ! -s "$CALLS" ] || fail "zip manquant : butler appelé : $(cat "$CALLS")"

# Clé vide : échec avant tout push.
prepare
if ITCH_TARGET=someone/stackmates BUTLER_API_KEY= BUTLER="$FAKE" DIST="$DIST" \
	bash "$SCRIPT" v0.3.0 > "$WORK/out" 2>&1; then
	fail "clé vide : devrait sortir en 1"
fi
[ ! -s "$CALLS" ] || fail "clé vide : butler appelé : $(cat "$CALLS")"

if [ "$FAILED" = 0 ]; then
	echo "publish_itch_test: OK"
	exit 0
fi
exit 1
