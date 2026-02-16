@echo off
REM ==============================================================================
REM Azure Deployment Script - Django Backend + ML Models (Windows)
REM ==============================================================================
REM This script automates the deployment of CPSU Health Assistant to Azure
REM using Azure Developer CLI (azd)
REM ==============================================================================

setlocal enabledelayedexpansion

echo.
echo ========================================
echo Azure Deployment Script
echo ========================================
echo.

REM ==============================================================================
REM Pre-deployment Checks
REM ==============================================================================

echo [Pre-Deployment Checks]
echo.

REM Check if azd is installed
where azd >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Azure Developer CLI (azd) is not installed
    echo Install from: https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd
    exit /b 1
)
echo [OK] Azure Developer CLI found

REM Check if Python is installed
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Python is not installed
    exit /b 1
)
echo [OK] Python found

REM Check if ML model exists
if not exist "ML\models\disease_predictor_v2.pkl" (
    echo [WARNING] ML model not found
    set /p train_choice="Do you want to train the model now? (y/n): "
    if /i "!train_choice!"=="y" (
        echo Training ML model...
        cd ML\scripts
        python train_model_realistic.py
        cd ..\..
        echo [OK] ML model trained successfully
    ) else (
        echo [ERROR] ML model is required for deployment
        exit /b 1
    )
)
echo [OK] ML model found

REM Check if .env file exists
if not exist "Django\.env" (
    echo [WARNING] .env file not found. Creating from template...
    
    REM Generate Django secret key
    for /f "delims=" %%i in ('python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"') do set DJANGO_SECRET=%%i
    
    echo # Django Configuration > Django\.env
    echo DJANGO_SECRET_KEY=!DJANGO_SECRET! >> Django\.env
    echo DEBUG=False >> Django\.env
    echo DJANGO_ALLOWED_HOSTS=.azurewebsites.net,.azurestaticapps.net >> Django\.env
    echo. >> Django\.env
    echo # Database (will be set by Azure) >> Django\.env
    echo # DATABASE_URL will be configured during deployment >> Django\.env
    echo. >> Django\.env
    echo # LLM API Keys (Optional) >> Django\.env
    echo GEMINI_API_KEY= >> Django\.env
    echo OPENROUTER_API_KEY= >> Django\.env
    echo COHERE_API_KEY= >> Django\.env
    echo. >> Django\.env
    echo # Rasa Configuration >> Django\.env
    echo RASA_ENABLED=False >> Django\.env
    echo RASA_SERVER_URL=http://localhost:5005 >> Django\.env
    echo RASA_TIMEOUT=60 >> Django\.env
    
    echo [OK] Created Django\.env file
    echo [INFO] Please edit Django\.env to add your LLM API keys (optional)
    pause
)

REM ==============================================================================
REM Azure Authentication
REM ==============================================================================

echo.
echo [Azure Authentication]
echo.

REM Check if already logged in
azd auth login --check-status >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] Already logged in to Azure
) else (
    echo Logging in to Azure...
    azd auth login
    echo [OK] Successfully logged in to Azure
)

REM ==============================================================================
REM Environment Configuration
REM ==============================================================================

echo.
echo [Environment Configuration]
echo.

if exist ".azure\config.json" (
    echo [OK] Using existing environment
) else (
    set /p ENV_NAME="Enter environment name (e.g., cpsu-health-prod): "
    
    echo Initializing Azure environment...
    azd env new !ENV_NAME!
    
    echo [OK] Environment created
)

REM ==============================================================================
REM Deployment
REM ==============================================================================

echo.
echo [Deploying to Azure]
echo.

echo This will:
echo   1. Provision Azure resources (App Service, PostgreSQL, Redis, etc.)
echo   2. Build and deploy Django backend
echo   3. Upload ML models and datasets
echo   4. Configure environment variables
echo   5. Run database migrations
echo.
echo [WARNING] This may take 10-15 minutes on first deployment
echo.

set /p deploy_choice="Continue with deployment? (y/n): "
if /i not "!deploy_choice!"=="y" (
    echo Deployment cancelled
    exit /b 0
)

echo Starting deployment...
echo.

azd up

if %errorlevel% neq 0 (
    echo [ERROR] Deployment failed
    exit /b 1
)

REM ==============================================================================
REM Post-Deployment
REM ==============================================================================

echo.
echo [Post-Deployment Configuration]
echo.

echo [OK] Backend deployed successfully!
echo.

echo Next Steps:
echo 1. Create a superuser account:
echo    azd exec --service web -- python manage.py createsuperuser
echo.
echo 2. View application logs:
echo    azd monitor --overview
echo.
echo 3. Update environment variables:
echo    azd env set VARIABLE_NAME "value"
echo.
echo 4. Redeploy after code changes:
echo    azd deploy
echo.

echo [SUCCESS] Deployment Complete!
echo.
echo Documentation:
echo   - Full guide: DEPLOY_CLI_GUIDE.md
echo   - Quick start: QUICKSTART_AZURE.md
echo.

pause
