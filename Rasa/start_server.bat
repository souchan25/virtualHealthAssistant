@echo off
REM Start Rasa server with the latest trained model (Windows)
REM Run this from the Rasa directory

echo ========================================
echo Starting CPSU Rasa Server (Windows)
echo ========================================
echo.

REM Check if we're in Rasa directory
if not exist "domain.yml" (
    echo [WARNING] Not in Rasa directory. Changing to Rasa\
    cd Rasa 2>nul || (
        echo [ERROR] Rasa directory not found!
        pause
        exit /b 1
    )
)

REM Check if models directory exists
if not exist "models" (
    echo [ERROR] models\ directory not found!
    echo.
    echo Please train a model first:
    echo   rasa train
    echo.
    pause
    exit /b 1
)

REM Find the latest model (most recent .tar.gz file)
set LATEST_MODEL=
for /f "delims=" %%i in ('dir /b /o-d models\*.tar.gz 2^>nul') do (
    if not defined LATEST_MODEL set LATEST_MODEL=%%i
    goto :found_model
)

:found_model
if not defined LATEST_MODEL (
    echo [ERROR] No trained models found in models\
    echo.
    echo Please train a model first:
    echo   rasa train
    echo.
    pause
    exit /b 1
)

echo [OK] Found trained model:
echo    models\%LATEST_MODEL%
echo.

REM Check if Rasa action server is running
curl -s http://localhost:5055 >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] Rasa action server is running (port 5055)
) else (
    echo [WARNING] Rasa action server is NOT running
    echo    Start it in another terminal:
    echo    cd Rasa ^&^& rasa run actions
    echo.
)

REM Start Rasa server
echo.
echo Starting Rasa server...
echo    - Port: 5005
echo    - Model: %LATEST_MODEL%
echo    - CORS: Enabled for all origins
echo    - API: Enabled
echo.
echo Press Ctrl+C to stop
echo.

rasa run --model "models\%LATEST_MODEL%" --enable-api --cors "*" --port 5005 --debug

REM Note: Remove --debug for production use
