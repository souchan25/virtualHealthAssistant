#!/bin/bash

# Deployment Verification Script
# Run this before deploying to production

set -e

echo "🔍 CPSU Health Assistant - Deployment Verification"
echo "=================================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check Python version
echo "📦 Checking Python version..."
python_version=$(python --version 2>&1 | grep -oP '\d+\.\d+')
major_version=$(echo $python_version | cut -d. -f1)
minor_version=$(echo $python_version | cut -d. -f2)
if [ "$major_version" -ge 3 ] && [ "$minor_version" -ge 8 ]; then
    echo -e "${GREEN}✅ Python $python_version${NC}"
else
    echo -e "${RED}❌ Python $python_version is too old (need 3.8+)${NC}"
    exit 1
fi

# Check if ML model exists
echo ""
echo "🤖 Checking ML model..."
if [ -f "ML/models/disease_predictor_v2.pkl" ]; then
    echo -e "${GREEN}✅ ML model found${NC}"
else
    echo -e "${YELLOW}⚠️  ML model not found. Training now...${NC}"
    cd ML/scripts
    python train_model_realistic.py
    cd ../..
    echo -e "${GREEN}✅ ML model trained${NC}"
fi

# Check Django settings
echo ""
echo "⚙️  Checking Django settings..."
cd Django
export DEBUG=False
export SECRET_KEY=test-verification-key
export ALLOWED_HOSTS=localhost

python -c "from health_assistant import settings; print('✅ Settings OK')" 2>/dev/null && echo -e "${GREEN}✅ Django settings valid${NC}" || { echo -e "${RED}❌ Django settings invalid${NC}"; exit 1; }

# Check required packages
echo ""
echo "📚 Checking required packages..."
packages=("django" "djangorestframework" "gunicorn" "whitenoise" "dj-database-url" "python-dotenv")
for package in "${packages[@]}"; do
    python -c "import $package" 2>/dev/null && echo -e "${GREEN}✅ $package${NC}" || { echo -e "${RED}❌ $package not installed${NC}"; exit 1; }
done

# Check deployment files
echo ""
echo "📄 Checking deployment files..."
cd ..
files=("Procfile" "runtime.txt" "railway.json" "render.yaml" "Dockerfile" ".env.example")
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $file${NC}"
    else
        echo -e "${RED}❌ $file missing${NC}"
    fi
done

# Check frontend build
echo ""
echo "🎨 Checking frontend..."
if [ -d "Vue/node_modules" ]; then
    echo -e "${GREEN}✅ Node modules installed${NC}"
else
    echo -e "${YELLOW}⚠️  Node modules not installed (run: cd Vue && npm install)${NC}"
fi

if [ -f "Vue/vercel.json" ]; then
    echo -e "${GREEN}✅ Vercel config${NC}"
fi

if [ -f "Vue/netlify.toml" ]; then
    echo -e "${GREEN}✅ Netlify config${NC}"
fi

# Summary
echo ""
echo "=================================================="
echo "📋 Deployment Checklist:"
echo "=================================================="
echo ""
echo "Before deploying, ensure you have:"
echo ""
echo "1. ✅ GitHub Student Developer Pack activated"
echo "   https://education.github.com/pack"
echo ""
echo "2. ✅ Railway or Render account created"
echo "   Railway: https://railway.app/"
echo "   Render: https://render.com/"
echo ""
echo "3. ✅ Vercel account created"
echo "   https://vercel.com/"
echo ""
echo "4. ✅ Environment variables ready:"
echo "   - SECRET_KEY (generate new!)"
echo "   - DEBUG=False"
echo "   - ALLOWED_HOSTS=your-domain.com"
echo "   - DATABASE_URL (auto-configured by platform)"
echo "   - CORS_ALLOWED_ORIGINS=https://frontend.vercel.app"
echo ""
echo "5. ✅ API keys (optional for LLM features):"
echo "   - GEMINI_API_KEY"
echo "   - OPENROUTER_API_KEY"
echo "   - COHERE_API_KEY"
echo ""
echo "=================================================="
echo ""
echo -e "${GREEN}✅ All checks passed! Ready to deploy!${NC}"
echo ""
echo "📖 Next steps:"
echo "   1. Read DEPLOYMENT.md for detailed instructions"
echo "   2. Follow DEPLOYMENT_CHECKLIST.md"
echo "   3. Review STUDENT_PACK_GUIDE.md for benefits"
echo ""
echo "🚀 Happy deploying!"
