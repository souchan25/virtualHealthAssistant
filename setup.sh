#!/bin/bash

# ===================================
# CPSU Virtual Health Assistant
# Initial Setup Script
# ===================================

set -e  # Exit on error

echo "======================================"
echo "CPSU Virtual Health Assistant Setup"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running in git repository
if [ ! -d ".git" ]; then
    echo -e "${RED}Error: This script must be run from the repository root${NC}"
    exit 1
fi

echo -e "${YELLOW}Step 1: Checking prerequisites...${NC}"

# Check Python
if ! command -v python &> /dev/null; then
    echo -e "${RED}Error: Python is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Python found: $(python --version)${NC}"

# Check pip
if ! command -v pip &> /dev/null; then
    echo -e "${RED}Error: pip is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ pip found${NC}"

# Check Node.js (optional for frontend)
if command -v node &> /dev/null; then
    echo -e "${GREEN}✓ Node.js found: $(node --version)${NC}"
else
    echo -e "${YELLOW}⚠ Node.js not found (required for Vue frontend)${NC}"
fi

echo ""
echo -e "${YELLOW}Step 2: Creating environment files...${NC}"

# Check if .env files exist
if [ -f "Django/.env" ]; then
    echo -e "${YELLOW}Django/.env already exists. Skipping...${NC}"
else
    cp Django/.env.example Django/.env
    echo -e "${GREEN}✓ Created Django/.env from template${NC}"
fi

if [ -f "Vue/.env" ]; then
    echo -e "${YELLOW}Vue/.env already exists. Skipping...${NC}"
else
    cp Vue/.env.example Vue/.env
    echo -e "${GREEN}✓ Created Vue/.env from template${NC}"
fi

echo ""
echo -e "${YELLOW}Step 3: Setting up Python virtual environment...${NC}"

if [ -d "venv" ]; then
    echo -e "${YELLOW}Virtual environment already exists${NC}"
else
    python -m venv venv
    echo -e "${GREEN}✓ Created virtual environment${NC}"
fi

# Activate virtual environment
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    source venv/Scripts/activate
else
    source venv/bin/activate
fi

echo -e "${GREEN}✓ Activated virtual environment${NC}"

echo ""
echo -e "${YELLOW}Step 4: Installing Django dependencies...${NC}"

cd Django
pip install -r requirements.txt
echo -e "${GREEN}✓ Django dependencies installed${NC}"
cd ..

echo ""
echo -e "${YELLOW}Step 5: Generating Django SECRET_KEY...${NC}"

cd Django
SECRET_KEY=$(python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())")
echo -e "${GREEN}✓ Generated SECRET_KEY${NC}"
echo ""
echo -e "${YELLOW}Add this to your Django/.env file:${NC}"
echo "DJANGO_SECRET_KEY=$SECRET_KEY"
echo ""

# Ask if user wants to automatically update .env
read -p "Do you want to automatically add this to Django/.env? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Check if DJANGO_SECRET_KEY already exists
    if grep -q "^DJANGO_SECRET_KEY=" .env; then
        # Replace existing key
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s|^DJANGO_SECRET_KEY=.*|DJANGO_SECRET_KEY=$SECRET_KEY|" .env
        else
            # Linux/Git Bash
            sed -i "s|^DJANGO_SECRET_KEY=.*|DJANGO_SECRET_KEY=$SECRET_KEY|" .env
        fi
        echo -e "${GREEN}✓ Updated DJANGO_SECRET_KEY in .env${NC}"
    else
        # Append new key
        echo "DJANGO_SECRET_KEY=$SECRET_KEY" >> .env
        echo -e "${GREEN}✓ Added DJANGO_SECRET_KEY to .env${NC}"
    fi
fi

cd ..

echo ""
echo -e "${YELLOW}Step 6: Creating necessary directories...${NC}"

mkdir -p Django/logs
mkdir -p Django/staticfiles
mkdir -p Django/media
mkdir -p ML/models
echo -e "${GREEN}✓ Directories created${NC}"

echo ""
echo -e "${YELLOW}Step 7: Running database migrations...${NC}"

cd Django
python manage.py migrate
echo -e "${GREEN}✓ Database migrations completed${NC}"

echo ""
echo -e "${YELLOW}Step 8: Collecting static files...${NC}"

python manage.py collectstatic --noinput
echo -e "${GREEN}✓ Static files collected${NC}"

cd ..

echo ""
echo -e "${GREEN}======================================"
echo "Setup Complete!"
echo "======================================${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo "1. ${RED}SECURITY: Add your API keys to Django/.env${NC}"
echo "   - GEMINI_API_KEY"
echo "   - OPENROUTER_API_KEY"
echo "   - GROQ_API_KEY"
echo "   - COHERE_API_KEY"
echo ""
echo "2. Create a superuser:"
echo "   cd Django"
echo "   python manage.py createsuperuser"
echo ""
echo "3. Train the ML model (first time only):"
echo "   cd ML/scripts"
echo "   python train_model_realistic.py"
echo ""
echo "4. Start the development server:"
echo "   cd Django"
echo "   python manage.py runserver"
echo ""
echo "5. (Optional) Setup Vue frontend:"
echo "   cd Vue"
echo "   npm install"
echo "   npm run dev"
echo ""
echo -e "${YELLOW}For production deployment, see DEPLOYMENT.md${NC}"
echo -e "${RED}IMPORTANT: Read SECURITY.md before deploying!${NC}"
echo ""
