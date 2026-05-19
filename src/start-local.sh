#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

BACKEND_PID=""
FRONTEND_PID=""

# Cleanup can run before both services are started, so guard PID usage.
cleanup() {
  echo ""
  echo "Stopping services..."

  if [[ -n "${BACKEND_PID}" ]] && kill -0 "$BACKEND_PID" 2>/dev/null; then
    kill "$BACKEND_PID" 2>/dev/null
    wait "$BACKEND_PID" 2>/dev/null
  fi

  if [[ -n "${FRONTEND_PID}" ]] && kill -0 "$FRONTEND_PID" 2>/dev/null; then
    kill "$FRONTEND_PID" 2>/dev/null
    wait "$FRONTEND_PID" 2>/dev/null
  fi
}

# Install traps early so Ctrl+C during startup does not orphan processes.
trap 'cleanup; exit 0' INT TERM
trap cleanup EXIT

echo "Starting E-commerce Chat Application..."

echo ""
echo "Starting Backend (FastAPI)..."
(
	cd api || exit 1
	exec python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
) &
BACKEND_PID=$!

echo ""
echo "Waiting 3 seconds for backend to start..."
sleep 3

echo ""
echo "Starting Frontend (React)..."
(
	cd App || exit 1
	exec npm run dev
) &
FRONTEND_PID=$!

echo ""
echo "Both services are starting..."
echo "Backend: http://localhost:8000"
echo "Frontend: http://localhost:5173"
echo ""
echo "Press Ctrl+C to stop both services"

# Wait for user to stop
wait "$BACKEND_PID" "$FRONTEND_PID"