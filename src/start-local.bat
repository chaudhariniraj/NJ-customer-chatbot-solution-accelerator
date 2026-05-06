@echo off
setlocal
set "SRC_DIR=%~dp0"

echo Starting E-commerce Chat Application...

echo.
echo Starting Backend (FastAPI)...
start "Backend" cmd /k "cd /d ""%SRC_DIR%api"" && python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"

echo.
echo Waiting 3 seconds for backend to start...
timeout /t 3 /nobreak > nul

echo.
echo Starting Frontend (React)...
start "Frontend" cmd /k "cd /d ""%SRC_DIR%App"" && npm run dev"

echo.
echo Both services are starting...
echo Backend: http://localhost:8000
echo Frontend: http://localhost:5173
echo.
pause
endlocal