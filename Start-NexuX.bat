@echo off
setlocal
cd /d "%~dp0"

echo NexuX startup

where docker >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker Desktop is not installed or docker.exe is not on PATH.
    pause
    exit /b 1
)

docker info >nul 2>&1
if errorlevel 1 (
    echo Starting Docker Desktop...
    start "" "%ProgramFiles%\Docker\Docker\Docker Desktop.exe"
    echo Please wait until Docker Desktop is ready, then press any key.
    pause
)

where ollama >nul 2>&1
if errorlevel 1 (
    echo ERROR: Ollama is not installed or ollama.exe is not on PATH.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-WebRequest -UseBasicParsing -TimeoutSec 3 'http://localhost:11434/api/tags' | Out-Null; exit 0 } catch { exit 1 }"
if errorlevel 1 (
    echo Starting Ollama...
    start "" cmd /c "ollama serve"
)

if not exist ".env" copy ".env.example" ".env"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Setup-Environment.ps1"

docker compose up --build -d --remove-orphans
if errorlevel 1 (
    echo ERROR: Docker services failed to start.
    pause
    exit /b 1
)

cd /d "%~dp0frontend"
if not exist node_modules call npm ci --no-audit --no-fund

set "NEXT_PUBLIC_API_BASE_URL=http://10.54.15.175:8000"
start "" "http://10.54.15.175:3000"
npm run dev

