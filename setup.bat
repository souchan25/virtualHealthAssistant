@echo off
REM ===================================
REM CPSU Virtual Health Assistant
REM Windows Setup Script
REM ===================================

echo ======================================
echo CPSU Virtual Health Assistant Setup
echo ======================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo Error: Python is not installed
    echo Please install Python 3.11+ from https://www.python.org/downloads/
    pause
    exit /b 1
)

echo [OK] Python found
python --version

echo.
echo Step 1: Creating environment files...

REM Create .env files from templates
if not exist "Django\.env" (
    copy "Django\.env.example" "Django\.env"
    echo [OK] Created Django\.env from template
) else (
    echo [SKIP] Django\.env already exists
)

if not exist "Vue\.env" (
    copy "Vue\.env.example" "Vue\.env"
    echo [OK] Created Vue\.env from template
) else (
    echo [SKIP] Vue\.env already exists
)

echo.
echo Step 2: Setting up Python virtual environment...

if not exist "venv" (
    python -m venv venv
    echo [OK] Created virtual environment
) else (
    echo [SKIP] Virtual environment already exists
)

REM Activate virtual environment
call venv\Scripts\activate.bat

echo.
echo Step 3: Installing Django dependencies...

cd Django
pip install -r requirements.txt
if errorlevel 1 (
    echo [ERROR] Failed to install dependencies
    cd ..
    pause
    exit /b 1
)
echo [OK] Django dependencies installed

echo.
echo Step 4: Generating Django SECRET_KEY...

python generate_secret_key.py
echo.
echo [INFO] Copy the SECRET_KEY above and add it to Django\.env
echo.

cd ..

echo.
echo Step 5: Creating necessary directories...

if not exist "Django\logs" mkdir Django\logs
if not exist "Django\staticfiles" mkdir Django\staticfiles
if not exist "Django\media" mkdir Django\media
if not exist "ML\models" mkdir ML\models
echo [OK] Directories created

echo.
echo Step 6: Running database migrations...

cd Django
python manage.py migrate
if errorlevel 1 (
    echo [ERROR] Database migration failed
    cd ..
    pause
    exit /b 1
)
echo [OK] Database migrations completed

echo.
echo Step 7: Collecting static files...

python manage.py collectstatic --noinput
echo [OK] Static files collected

cd ..

echo.
echo ======================================
echo Setup Complete!
echo ======================================
echo.
echo Next Steps:
echo.
echo 1. SECURITY: Add your API keys to Django\.env
echo    - GEMINI_API_KEY
echo    - OPENROUTER_API_KEY
echo    - GROQ_API_KEY
echo    - COHERE_API_KEY
echo.
echo 2. Create a superuser:
echo    cd Django
echo    python manage.py createsuperuser
echo.
echo 3. Train the ML model (first time only):
echo    cd ML\scripts
echo    python train_model_realistic.py
echo.
echo 4. Start the development server:
echo    cd Django
echo    python manage.py runserver
echo.
echo 5. (Optional) Setup Vue frontend:
echo    cd Vue
echo    npm install
echo    npm run dev
echo.
echo For production deployment, see DEPLOYMENT.md
echo IMPORTANT: Read SECURITY.md before deploying!
echo.
pause
