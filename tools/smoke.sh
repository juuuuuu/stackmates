#!/usr/bin/env bash
# Lance un host et un client headless, attend les deux, échoue si l'un échoue.
set -u
GODOT="${GODOT:-godot}"
PORT="${PORT:-28015}"
LOG_DIR="${STACKMATES_SMOKE_LOG_DIR:-/tmp}"
# Un binaire exporté embarque le projet : pas de --path.
PROJECT_ARGS=(--path .)
if [ -n "${STACKMATES_EXPORTED:-}" ]; then PROJECT_ARGS=(); fi
"$GODOT" --headless "${PROJECT_ARGS[@]}" -- --host --port="$PORT" --name=Host --smoke > "$LOG_DIR/smoke_host.log" 2>&1 &
HOST_PID=$!
sleep 2
"$GODOT" --headless "${PROJECT_ARGS[@]}" -- --join=127.0.0.1:"$PORT" --name=Guest --smoke > "$LOG_DIR/smoke_client.log" 2>&1
CLIENT_CODE=$?
wait "$HOST_PID"
HOST_CODE=$?
echo "host=$HOST_CODE client=$CLIENT_CODE"
grep -q "SMOKE OK" "$LOG_DIR/smoke_host.log" && grep -q "SMOKE OK" "$LOG_DIR/smoke_client.log" && [ "$HOST_CODE" = 0 ] && [ "$CLIENT_CODE" = 0 ]
