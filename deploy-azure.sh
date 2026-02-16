#!/bin/bash
# ==============================================================================
# Azure Deployment Script - Django Backend + ML Models
# ==============================================================================
# This script automates the deployment of CPSU Health Assistant to Azure
# using Azure Developer CLI (azd)
# ==============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# ==============================================================================
# Pre-deployment Checks
# ==============================================================================

print_header "Pre-Deployment Checks"

# Check if azd is installed
if ! command -v azd &> /dev/null; then
    print_error "Azure Developer CLI (azd) is not installed"
    echo "Install from: https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd"
    exit 1
fi
print_success "Azure Developer CLI found: $(azd version)"

# Check if Python is installed
if ! command -v python &> /dev/null; then
    print_error "Python is not installed"
    exit 1
fi
print_success "Python found: $(python --version)"

# Check if ML model exists
if [ ! -f "ML/models/disease_predictor_v2.pkl" ]; then
    print_warning "ML model not found at ML/models/disease_predictor_v2.pkl"
    read -p "Do you want to train the model now? (y/n): " train_choice
    if [ "$train_choice" = "y" ] || [ "$train_choice" = "Y" ]; then
        print_info "Training ML model..."
        cd ML/scripts
        python train_model_realistic.py
        cd ../..
        print_success "ML model trained successfully"
    else
        print_error "ML model is required for deployment. Exiting."
        exit 1
    fi
fi
print_success "ML model found: ML/models/disease_predictor_v2.pkl"

# Check if .env file exists
if [ ! -f "Django/.env" ]; then
    print_warning ".env file not found. Creating from template..."
    
    # Generate Django secret key
    DJANGO_SECRET=$(python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
    
    cat > Django/.env << EOF
# Django Configuration
DJANGO_SECRET_KEY=$DJANGO_SECRET
DEBUG=False
DJANGO_ALLOWED_HOSTS=.azurewebsites.net,.azurestaticapps.net

# Database (will be set by Azure)
# DATABASE_URL will be configured during deployment

# LLM API Keys (Optional - add your keys here)
GEMINI_API_KEY=
OPENROUTER_API_KEY=
COHERE_API_KEY=

# Rasa Configuration
RASA_ENABLED=False
RASA_SERVER_URL=http://localhost:5005
RASA_TIMEOUT=60
EOF
    
    print_success "Created Django/.env file"
    print_warning "Please edit Django/.env to add your LLM API keys (optional)"
    read -p "Press Enter to continue..."
fi

# ==============================================================================
# Azure Authentication
# ==============================================================================

print_header "Azure Authentication"

# Check if already logged in
if azd auth login --check-status &> /dev/null; then
    print_success "Already logged in to Azure"
else
    print_info "Logging in to Azure..."
    azd auth login
    print_success "Successfully logged in to Azure"
fi

# ==============================================================================
# Environment Configuration
# ==============================================================================

print_header "Environment Configuration"

# Check if environment already exists
if [ -f ".azure/config.json" ]; then
    ENV_NAME=$(cat .azure/config.json | grep -o '"defaultEnvironment": *"[^"]*"' | grep -o '"[^"]*"$' | tr -d '"')
    print_success "Using existing environment: $ENV_NAME"
else
    read -p "Enter environment name (e.g., cpsu-health-prod): " ENV_NAME
    
    print_info "Initializing Azure environment..."
    azd env new $ENV_NAME
    
    print_success "Environment created: $ENV_NAME"
fi

# Set environment variables
print_info "Configuring environment variables..."

# Load .env file and set azd variables
if [ -f "Django/.env" ]; then
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ $key =~ ^#.*$ ]] && continue
        [[ -z $key ]] && continue
        
        # Remove quotes and whitespace
        key=$(echo $key | xargs)
        value=$(echo $value | xargs | sed 's/^"//' | sed 's/"$//')
        
        # Set environment variable
        if [ ! -z "$value" ]; then
            azd env set $key "$value" 2>/dev/null || true
        fi
    done < Django/.env
    
    print_success "Environment variables configured"
fi

# ==============================================================================
# Deployment
# ==============================================================================

print_header "Deploying to Azure"

print_info "This will:"
echo "  1. Provision Azure resources (App Service, PostgreSQL, Redis, etc.)"
echo "  2. Build and deploy Django backend"
echo "  3. Upload ML models and datasets"
echo "  4. Configure environment variables"
echo "  5. Run database migrations"
echo ""
print_warning "This may take 10-15 minutes on first deployment"
echo ""

read -p "Continue with deployment? (y/n): " deploy_choice
if [ "$deploy_choice" != "y" ] && [ "$deploy_choice" != "Y" ]; then
    print_info "Deployment cancelled"
    exit 0
fi

# Run deployment
print_info "Starting deployment..."
echo ""

azd up

# ==============================================================================
# Post-Deployment
# ==============================================================================

print_header "Post-Deployment Configuration"

# Get backend URL
BACKEND_URL=$(azd env get-values | grep REACT_APP_WEB_BASE_URL | cut -d'=' -f2 | tr -d '"')

if [ ! -z "$BACKEND_URL" ]; then
    print_success "Backend deployed successfully!"
    echo ""
    echo "Backend URL: $BACKEND_URL"
    echo ""
    
    # Test health endpoint
    print_info "Testing health endpoint..."
    if curl -s -f "$BACKEND_URL/api/health/" > /dev/null; then
        print_success "Health check passed!"
    else
        print_warning "Health check failed. Backend may still be starting up."
    fi
    
    # Test ML prediction endpoint
    print_info "Testing ML prediction endpoint..."
    PREDICT_RESPONSE=$(curl -s -X POST "$BACKEND_URL/api/rasa/predict/" \
        -H "Content-Type: application/json" \
        -d '{"symptoms":["fever","cough"]}' || echo "failed")
    
    if [[ "$PREDICT_RESPONSE" != "failed" ]] && [[ "$PREDICT_RESPONSE" == *"predicted_disease"* ]]; then
        print_success "ML prediction endpoint working!"
        echo "Sample prediction: $PREDICT_RESPONSE" | python -m json.tool 2>/dev/null || echo "$PREDICT_RESPONSE"
    else
        print_warning "ML prediction endpoint may need a few minutes to initialize"
    fi
else
    print_warning "Could not retrieve backend URL"
fi

# ==============================================================================
# Next Steps
# ==============================================================================

print_header "Next Steps"

echo "1. Create a superuser account:"
echo "   azd exec --service web -- python manage.py createsuperuser"
echo ""
echo "2. View application logs:"
echo "   azd monitor --overview"
echo ""
echo "3. SSH into the web app:"
echo "   azd exec --service web -- /bin/bash"
echo ""
echo "4. Update environment variables:"
echo "   azd env set VARIABLE_NAME 'value'"
echo ""
echo "5. Redeploy after code changes:"
echo "   azd deploy"
echo ""

print_success "Deployment Complete!"
echo ""
echo "📚 Documentation:"
echo "   - Full guide: DEPLOY_CLI_GUIDE.md"
echo "   - Quick start: QUICKSTART_AZURE.md"
echo ""
echo "🔗 Useful Commands:"
echo "   - View resources: azd show"
echo "   - View logs: azd monitor --logs"
echo "   - Clean up: azd down"
echo ""
