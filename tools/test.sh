#!/usr/bin/env bash
# Importe les ressources (classes et assets) puis lance GUT.
# Échoue si un script ne charge pas, car GUT sort en 0 dans ce cas.
set -u
GODOT="${GODOT:-godot}"
LOG="${STACKMATES_TEST_LOG:-/tmp/stackmates_tests.log}"
"$GODOT" --headless --path . --import > /dev/null 2>&1
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gexit > "$LOG" 2>&1
CODE=$?
grep -E 'passed|failed|SCRIPT ERROR|Parse Error' "$LOG" | tail -20
if grep -q 'SCRIPT ERROR' "$LOG"; then
	echo "tests: un script a échoué au chargement (voir $LOG)"
	exit 1
fi
exit "$CODE"
