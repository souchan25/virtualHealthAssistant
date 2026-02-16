#!/bin/bash
# ==============================================================================
# Azure Deployment Script - Django + ML with Supabase Database
# ==============================================================================
# Simplified deployment using Supabase (no Azure PostgreSQL needed)
# ==============================================================================

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ $1${NC}"; }

# ==============================================================================
# Pre-deployment Checks
# ==============================================================================

print_header "Pre-Deployment Checks"

# Check Azure CLI
if ! command -v az &> /dev/null; then
    print_error "Azure CLI not installed"
    echo "Install: https://aka.ms/installazurecli"
    exit 1
fi
print_success "Azure CLI found: $(az version --query '\"azure-cli\"' -o tsv)"

# Check Python
if ! command -v python &> /dev/null; then
    print_error "Python not installed"
    exit 1
fi
print_success "Python found: $(python --version)"

# Check ML model
if [ ! -f "ML/models/disease_predictor_v2.pkl" ]; then
    print_warning "ML model not found"
    read -p "Train model now? (y/n): " train_choice
    if [ "$train_choice" = "y" ]; then
        print_info "Training model..."
        cd ML/scripts
        python train_model_realistic.py
        cd ../..
        print_success "Model trained"
    else
        print_error "Model required for deployment"
        exit 1
    fi
fi
print_success "ML model found"

# ==============================================================================
# Configuration
# ==============================================================================

print_header "Configuration"

# Get Supabase connection string
echo "Enter your Supabase DATABASE_URL:"
echo "Example: postgresql://postgres.[project-ref]:[password]@aws-0-us-east-1.pooler.supabase.com:6543/postgres"
echo ""
read -p "DATABASE_URL: " DATABASE_URL

if [ -z "$DATABASE_URL" ]; then
    print_error "DATABASE_URL is required"
    exit 1
fi

# Generate Django secret key
DJANGO_SECRET=$(python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')

# Get resource group name
read -p "Resource group name (default: cpsu-health-rg): " RESOURCE_GROUP
RESOURCE_GROUP=${RESOURCE_GROUP:-cpsu-health-rg}

# Get app name
read -p "App Service name (default: cpsu-health-backend): " APP_NAME
APP_NAME=${APP_NAME:-cpsu-health-backend}

# Add random suffix for uniqueness
SUFFIX=$(openssl rand -hex 3)
APP_NAME="${APP_NAME}-${SUFFIX}"

# Get region
read -p "Azure region (default: eastus): " LOCATION
LOCATION=${LOCATION:-eastus}

echo ""
echo "Configuration Summary:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  App Name: $APP_NAME"
echo "  Region: $LOCATION"
echo "  Database: Supabase (external)"
echo ""

read -p "Continue? (y/n): " confirm
if [ "$confirm" != "y" ]; then
    print_info "Cancelled"
    exit 0
fi

# ==============================================================================
# Azure Login
# ==============================================================================

print_header "Azure Login"

if ! az account show &> /dev/null; then
    print_info "Logging in..."
    az login
fi
print_success "Logged in"

# ==============================================================================
# Create Resources
# ==============================================================================

print_header "Creating Azure Resources"

# Create resource group
print_info "Creating resource group..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" > /dev/null
print_success "Resource group created"

# Create App Service Plan
print_info "Creating App Service Plan..."
az appservice plan create \
    --name "${APP_NAME}-plan" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --is-linux \
    --sku B1 > /dev/null
print_success "App Service Plan created"

# Create Web App
print_info "Creating Web App..."
az webapp create \
    --name "$APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --plan "${APP_NAME}-plan" \
    --runtime "PYTHON:3.11" > /dev/null
print_success "Web App created"

# ==============================================================================
# Configure Web App
# ==============================================================================

print_header "Configuring Web App"

# Set environment variables
print_info "Setting environment variables..."
az webapp config appsettings set \
    --resource-group "$RESOURCE_GROUP" \
    --name "$APP_NAME" \
    --settings \
        DATABASE_URL="$DATABASE_URL" \
        DJANGO_SECRET_KEY="$DJANGO_SECRET" \
        DEBUG="False" \
        DJANGO_ALLOWED_HOSTS=".azurewebsites.net" \
        PYTHONPATH="/home/site/wwwroot/Django" \
        SCM_DO_BUILD_DURING_DEPLOYMENT="true" \
        POST_BUILD_COMMAND="cd Django && python manage.py migrate && python manage.py collectstatic --noinput" \
        WEBSITE_HTTPLOGGING_RETENTION_DAYS="7" > /dev/null

print_success "Environment variables set"

# Set startup command
print_info "Configuring startup..."
az webapp config set \
    --resource-group "$RESOURCE_GROUP" \
    --name "$APP_NAME" \
    --startup-file "startup.sh" > /dev/null
print_success "Startup configured"

# ==============================================================================
# Deploy Code
# ==============================================================================

print_header "Deploying Application"

# Check if git remote exists
if git remote get-url origin &> /dev/null; then
    print_info "GitHub repository detected"
    read -p "Deploy from GitHub? (y/n): " use_github
    
    if [ "$use_github" = "y" ]; then
        echo ""
        echo "To complete GitHub deployment:"
        echo "1. Go to Azure Portal: https://portal.azure.com"
        echo "2. Navigate to: $APP_NAME > Deployment Center"
        echo "3. Select: GitHub > Authorize > Select repository"
        echo "4. Branch: main"
        echo "5. Click Save"
        echo ""
        print_info "Press Enter when done..."
        read
    fi
else
    print_info "Using ZIP deployment..."
    
    # Create ZIP for deployment
    print_info "Creating deployment package..."
    git archive --format=zip --output=deploy.zip HEAD
    
    print_info "Uploading to Azure..."
    az webapp deployment source config-zip \
        --resource-group "$RESOURCE_GROUP" \
        --name "$APP_NAME" \
        --src deploy.zip
    
    rm deploy.zip
    print_success "Deployed"
fi

# ==============================================================================
# Post-Deployment
# ==============================================================================

print_header "Post-Deployment"

# Get app URL
APP_URL=$(az webapp show --resource-group "$RESOURCE_GROUP" --name "$APP_NAME" --query "defaultHostName" -o tsv)

echo ""
print_header "Deployment Complete!"
echo ""
echo "Backend URL: https://$APP_URL"
echo ""
echo "Test endpoints:"
echo "  Health: https://$APP_URL/api/health/"
echo "  Predict: https://$APP_URL/api/rasa/predict/"
echo ""
echo "Next steps:"
echo "  1. Create superuser:"
echo "     az webapp ssh --resource-group $RESOURCE_GROUP --name $APP_NAME"
echo "     cd Django && python manage.py createsuperuser"
echo ""
echo "  2. View logs:"
echo "     az webapp log tail --resource-group $RESOURCE_GROUP --name $APP_NAME"
echo ""
echo "  3. Update settings:"
echo "     az webapp config appsettings set --resource-group $RESOURCE_GROUP --name $APP_NAME --settings KEY=VALUE"
echo ""

# Test health endpoint
print_info "Testing health endpoint (waiting 30s for startup)..."
sleep 30

if curl -s -f "https://$APP_URL/api/health/" > /dev/null; then
    print_success "Backend is responding!"
else
    print_warning "Backend still starting up (may take 2-3 minutes)"
fi

echo ""
print_success "All done! 🎉"
