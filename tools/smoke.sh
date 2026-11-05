#!/usr/bin/env bash
# Lance un host et un client headless, attend les deux, échoue si l'un échoue.
# GODOT : binaire à utiliser (défaut : godot). STACKMATES_EXPORTED=1 : GODOT est
# un binaire exporté, qui embarque le projet (pas de --path ni d'import).
set -u
GODOT="${GODOT:-godot}"
PORT="${PORT:-28015}"
LOG_DIR="${STACKMATES_SMOKE_LOG_DIR:-/tmp}"
PROCESS_TIMEOUT_SEC="${STACKMATES_SMOKE_PROCESS_TIMEOUT:-60}"
PROJECT_ARGS=(--path .)
if [ -n "${STACKMATES_EXPORTED:-}" ]; then
	PROJECT_ARGS=()
else
	# Sans import préalable, les class_name ne sont pas connus et le jeu ne démarre pas.
	"$GODOT" --headless --path . --import > /dev/null 2>&1
fi
timeout "$PROCESS_TIMEOUT_SEC" "$GODOT" --headless "${PROJECT_ARGS[@]}" -- --host --port="$PORT" --name=Host --smoke > "$LOG_DIR/smoke_host.log" 2>&1 &
HOST_PID=$!
sleep 2
timeout "$PROCESS_TIMEOUT_SEC" "$GODOT" --headless "${PROJECT_ARGS[@]}" -- --join=127.0.0.1:"$PORT" --name=Guest --smoke > "$LOG_DIR/smoke_client.log" 2>&1
CLIENT_CODE=$?
wait "$HOST_PID"
HOST_CODE=$?
echo "host=$HOST_CODE client=$CLIENT_CODE"
if [ "$HOST_CODE" != 0 ] || [ "$CLIENT_CODE" != 0 ]; then
	echo "--- host log ---"
	tail -20 "$LOG_DIR/smoke_host.log"
	echo "--- client log ---"
	tail -20 "$LOG_DIR/smoke_client.log"
fi
grep -q "SMOKE OK" "$LOG_DIR/smoke_host.log" && grep -q "SMOKE OK" "$LOG_DIR/smoke_client.log" && [ "$HOST_CODE" = 0 ] && [ "$CLIENT_CODE" = 0 ]
