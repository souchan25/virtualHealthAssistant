@echo off
REM ==============================================================================
REM Azure Deployment Script - Django + ML with Supabase Database
REM ==============================================================================
REM Simplified deployment using Supabase (no Azure PostgreSQL needed)
REM ==============================================================================

setlocal enabledelayedexpansion

echo.
echo ========================================
echo Azure Deployment with Supabase
echo ========================================
echo.

REM ==============================================================================
REM Pre-deployment Checks
REM ==============================================================================

echo [Pre-Deployment Checks]
echo.

REM Check Azure CLI
where az >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Azure CLI not installed
    echo Install: https://aka.ms/installazurecliwindows
    pause
    exit /b 1
)
echo [OK] Azure CLI found

REM Check Python
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Python not installed
    pause
    exit /b 1
)
echo [OK] Python found

REM Check ML model
if not exist "ML\models\disease_predictor_v2.pkl" (
    echo [WARNING] ML model not found
    set /p train_choice="Train model now? (y/n): "
    if /i "!train_choice!"=="y" (
        echo Training model...
        cd ML\scripts
        python train_model_realistic.py
        cd ..\..
        echo [OK] Model trained
    ) else (
        echo [ERROR] Model required for deployment
        pause
        exit /b 1
    )
)
echo [OK] ML model found

REM ==============================================================================
REM Collect Configuration
REM ==============================================================================

echo.
echo [Configuration]
echo.

REM Get Supabase connection string
echo Enter your Supabase DATABASE_URL:
echo Example: postgresql://postgres.[project-ref]:[password]@aws-0-us-east-1.pooler.supabase.com:6543/postgres
echo.
set /p DATABASE_URL="DATABASE_URL: "

if "!DATABASE_URL!"=="" (
    echo [ERROR] DATABASE_URL is required
    pause
    exit /b 1
)

REM Generate Django secret key
for /f "delims=" %%i in ('python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"') do set DJANGO_SECRET=%%i

REM Get resource group name
set /p RESOURCE_GROUP="Resource group name (default: cpsu-health-rg): "
if "!RESOURCE_GROUP!"=="" set RESOURCE_GROUP=cpsu-health-rg

REM Get app name
set /p APP_NAME="App Service name (default: cpsu-health-backend): "
if "!APP_NAME!"=="" set APP_NAME=cpsu-health-backend

REM Add random suffix for uniqueness
for /f %%i in ('powershell -command "[guid]::NewGuid().ToString().Substring(0,6)"') do set SUFFIX=%%i
set APP_NAME=!APP_NAME!-!SUFFIX!

REM Get region
set /p LOCATION="Azure region (default: eastus): "
if "!LOCATION!"=="" set LOCATION=eastus

echo.
echo Configuration Summary:
echo   Resource Group: !RESOURCE_GROUP!
echo   App Name: !APP_NAME!
echo   Region: !LOCATION!
echo   Database: Supabase (external)
echo.

set /p confirm="Continue? (y/n): "
if /i not "!confirm!"=="y" (
    echo Cancelled
    pause
    exit /b 0
)

REM ==============================================================================
REM Azure Login
REM ==============================================================================

echo.
echo [Azure Login]
echo.

az account show >nul 2>nul
if %errorlevel% neq 0 (
    echo Logging in...
    az login
)
echo [OK] Logged in

REM ==============================================================================
REM Create Resources
REM ==============================================================================

echo.
echo [Creating Azure Resources]
echo.

REM Create resource group
echo Creating resource group...
az group create --name !RESOURCE_GROUP! --location !LOCATION! >nul
echo [OK] Resource group created

REM Create App Service Plan
echo Creating App Service Plan...
az appservice plan create ^
    --name !APP_NAME!-plan ^
    --resource-group !RESOURCE_GROUP! ^
    --location !LOCATION! ^
    --is-linux ^
    --sku B1 >nul
echo [OK] App Service Plan created

REM Create Web App
echo Creating Web App...
az webapp create ^
    --name !APP_NAME! ^
    --resource-group !RESOURCE_GROUP! ^
    --plan !APP_NAME!-plan ^
    --runtime "PYTHON:3.11" >nul
echo [OK] Web App created

REM ==============================================================================
REM Configure Web App
REM ==============================================================================

echo.
echo [Configuring Web App]
echo.

REM Set environment variables
echo Setting environment variables...
az webapp config appsettings set ^
    --resource-group !RESOURCE_GROUP! ^
    --name !APP_NAME! ^
    --settings ^
        DATABASE_URL="!DATABASE_URL!" ^
        DJANGO_SECRET_KEY="!DJANGO_SECRET!" ^
        DEBUG="False" ^
        DJANGO_ALLOWED_HOSTS=".azurewebsites.net" ^
        PYTHONPATH="/home/site/wwwroot/Django" ^
        SCM_DO_BUILD_DURING_DEPLOYMENT="true" ^
        POST_BUILD_COMMAND="cd Django && python manage.py migrate && python manage.py collectstatic --noinput" ^
        WEBSITE_HTTPLOGGING_RETENTION_DAYS="7" >nul

echo [OK] Environment variables set

REM Set startup command
echo Configuring startup...
az webapp config set ^
    --resource-group !RESOURCE_GROUP! ^
    --name !APP_NAME! ^
    --startup-file "startup.sh" >nul
echo [OK] Startup configured

REM ==============================================================================
REM Deploy Code
REM ==============================================================================

echo.
echo [Deploying Application]
echo.

REM Configure GitHub deployment (if git remote exists)
git remote get-url origin >nul 2>nul
if %errorlevel% equ 0 (
    echo GitHub repository detected
    set /p use_github="Deploy from GitHub? (y/n): "
    
    if /i "!use_github!"=="y" (
        echo.
        echo To complete GitHub deployment:
        echo 1. Go to Azure Portal: https://portal.azure.com
        echo 2. Navigate to: !APP_NAME! ^> Deployment Center
        echo 3. Select: GitHub ^> Authorize ^> Select repository
        echo 4. Branch: main
        echo 5. Click Save
        echo.
        echo [INFO] Visit: https://portal.azure.com/#@/resource/subscriptions/.../resourceGroups/!RESOURCE_GROUP!/providers/Microsoft.Web/sites/!APP_NAME!/vstscd
        pause
    )
) else (
    echo [INFO] No git remote found. Using ZIP deployment...
    
    REM Create ZIP for deployment
    echo Creating deployment package...
    powershell -command "Compress-Archive -Path * -DestinationPath deploy.zip -Force"
    
    echo Uploading to Azure...
    az webapp deployment source config-zip ^
        --resource-group !RESOURCE_GROUP! ^
        --name !APP_NAME! ^
        --src deploy.zip
    
    del deploy.zip
    echo [OK] Deployed
)

REM ==============================================================================
REM Post-Deployment
REM ==============================================================================

echo.
echo [Post-Deployment]
echo.

REM Get app URL
for /f "delims=" %%i in ('az webapp show --resource-group !RESOURCE_GROUP! --name !APP_NAME! --query "defaultHostName" -o tsv') do set APP_URL=%%i

echo.
echo ========================================
echo Deployment Complete!
echo ========================================
echo.
echo Backend URL: https://!APP_URL!
echo.
echo Test endpoints:
echo   Health: https://!APP_URL!/api/health/
echo   Predict: https://!APP_URL!/api/rasa/predict/
echo.
echo Next steps:
echo   1. Create superuser:
echo      az webapp ssh --resource-group !RESOURCE_GROUP! --name !APP_NAME!
echo      cd Django && python manage.py createsuperuser
echo.
echo   2. View logs:
echo      az webapp log tail --resource-group !RESOURCE_GROUP! --name !APP_NAME!
echo.
echo   3. Update settings:
echo      az webapp config appsettings set --resource-group !RESOURCE_GROUP! --name !APP_NAME! --settings KEY=VALUE
echo.
echo Resources Dashboard:
echo   https://portal.azure.com/#@/resource/subscriptions/.../resourceGroups/!RESOURCE_GROUP!
echo.

REM Test health endpoint
echo Testing health endpoint...
timeout /t 30 /nobreak >nul
curl -s https://!APP_URL!/api/health/ >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] Backend is responding
) else (
    echo [INFO] Backend starting up (may take 2-3 minutes)
)

echo.
pause
