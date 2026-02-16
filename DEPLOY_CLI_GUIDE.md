# 🚀 Azure CLI Deployment Guide - Django Backend + ML

This guide walks you through deploying your Django backend with ML models to Azure using **Azure Developer CLI (azd)**.

## 📦 What Gets Deployed

✅ **Django Backend** - REST API with authentication, health endpoints  
✅ **ML Models** - Pre-trained scikit-learn models (`.pkl` files) included  
✅ **PostgreSQL Database** - Azure PostgreSQL Flexible Server  
✅ **Redis Cache** - For Rasa/session management  
✅ **Application Insights** - Monitoring and logging  
✅ **Key Vault** - Secure secrets management  

**ML Note**: The ML models in `ML/models/*.pkl` are deployed as part of the Django app. Django's `ml_service.py` loads them at runtime using the singleton pattern.

---

## ⚙️ Prerequisites

- [x] **Azure Developer CLI** installed (`azd version` confirms ✓)
- [ ] **Azure subscription** (free tier works fine)
- [ ] **GitHub account** (optional, for CI/CD)

---

## 🎯 Step-by-Step Deployment

### Step 1: Login to Azure

```bash
# Login to your Azure account
azd auth login
```

This opens your browser for Azure authentication. Sign in with your account.

### Step 2: Initialize Azure Developer Environment

```bash
# Navigate to project root
cd c:\Users\Souchan\OneDrive\Desktop\VirtualAssistant

# Initialize azd (if not already done)
azd init
```

**When prompted:**
- Environment name: `cpsu-health-prod` (or any name you prefer)
- Subscription: Select your Azure subscription
- Location: Choose region (e.g., `eastus`, `westus2`)

### Step 3: Set Environment Variables

Create `.env` file in project root with required secrets:

```bash
# Create .env file
cat > .env << 'EOF'
# Django Settings
DJANGO_SECRET_KEY=$(python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
DEBUG=False

# LLM API Keys (Optional - for AI features)
GEMINI_API_KEY=your_gemini_key_here
OPENROUTER_API_KEY=your_openrouter_key_here
COHERE_API_KEY=your_cohere_key_here

# ML Model Path (auto-configured in deployment)
# ML_MODEL_PATH=/home/site/wwwroot/ML/models/disease_predictor_v2.pkl
EOF
```

Or generate Django secret key separately:

```bash
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

### Step 4: Deploy to Azure

```bash
# Deploy everything (infrastructure + app)
azd up
```

This command:
1. ✅ Provisions all Azure resources (App Service, PostgreSQL, Redis, Key Vault)
2. ✅ Builds Django app with ML dependencies
3. ✅ Uploads ML model files (`.pkl`)
4. ✅ Configures environment variables
5. ✅ Runs database migrations
6. ✅ Starts the Django web app

**Deployment time**: 10-15 minutes (first time)

---

## 🔧 Alternative: Manual Azure CLI Deployment

If you prefer lower-level control, use Azure CLI directly:

### 1. Login and Set Subscription

```bash
# Login
az login

# List subscriptions
az account list --output table

# Set subscription
az account set --subscription "Your-Subscription-Name"
```

### 2. Create Resource Group

```bash
az group create \
  --name cpsu-health-rg \
  --location eastus
```

### 3. Create PostgreSQL Database

```bash
az postgres flexible-server create \
  --resource-group cpsu-health-rg \
  --name cpsu-health-db-$(openssl rand -hex 4) \
  --location eastus \
  --admin-user adminuser \
  --admin-password "YourSecurePassword123!" \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --storage-size 32 \
  --version 15

# Create database
az postgres flexible-server db create \
  --resource-group cpsu-health-rg \
  --server-name cpsu-health-db-XXXX \
  --database-name cpsu_health
```

### 4. Create Web App (App Service)

```bash
# Create App Service Plan
az appservice plan create \
  --name cpsu-health-plan \
  --resource-group cpsu-health-rg \
  --location eastus \
  --is-linux \
  --sku B1

# Create Web App
az webapp create \
  --resource-group cpsu-health-rg \
  --plan cpsu-health-plan \
  --name cpsu-health-backend-$(openssl rand -hex 4) \
  --runtime "PYTHON:3.11"
```

### 5. Configure Environment Variables

```bash
# Set app settings
az webapp config appsettings set \
  --resource-group cpsu-health-rg \
  --name cpsu-health-backend-XXXX \
  --settings \
    DJANGO_SECRET_KEY="your-secret-key-here" \
    DEBUG="False" \
    DATABASE_URL="postgresql://adminuser:YourPassword@cpsu-health-db-XXXX.postgres.database.azure.com:5432/cpsu_health" \
    PYTHONPATH="/home/site/wwwroot/Django" \
    SCM_DO_BUILD_DURING_DEPLOYMENT="true" \
    WEBSITE_HTTPLOGGING_RETENTION_DAYS="7"
```

### 6. Deploy Code with ML Models

```bash
# Navigate to project root
cd c:\Users\Souchan\OneDrive\Desktop\VirtualAssistant

# Create deployment ZIP (includes ML models)
git archive --format=zip --output=deploy.zip HEAD

# Deploy using Azure CLI
az webapp deployment source config-zip \
  --resource-group cpsu-health-rg \
  --name cpsu-health-backend-XXXX \
  --src deploy.zip
```

### 7. Run Database Migrations

```bash
# SSH into the web app
az webapp ssh --resource-group cpsu-health-rg --name cpsu-health-backend-XXXX

# Inside the SSH session:
cd /home/site/wwwroot/Django
python manage.py migrate
python manage.py createsuperuser  # Optional
exit
```

---

## 📊 Verify ML Models Are Deployed

### Check Model Files

```bash
# SSH into Azure Web App
az webapp ssh --resource-group cpsu-health-rg --name cpsu-health-backend-XXXX

# Verify ML model files exist
ls -lh /home/site/wwwroot/ML/models/
# Expected: disease_predictor_v2.pkl (~500KB)

ls -lh /home/site/wwwroot/ML/Datasets/active/
# Expected: train.csv, test.csv, symptom_Description.csv, etc.
```

### Test ML Prediction Endpoint

```bash
# Get your backend URL
BACKEND_URL=$(az webapp show \
  --resource-group cpsu-health-rg \
  --name cpsu-health-backend-XXXX \
  --query defaultHostName -o tsv)

# Test ML prediction
curl -X POST "https://$BACKEND_URL/api/rasa/predict/" \
  -H "Content-Type: application/json" \
  -d '{"symptoms":["fever","cough","fatigue"]}'
```

Expected response:
```json
{
  "predicted_disease": "Common Cold",
  "confidence": 0.89,
  "top_3_predictions": [...],
  "severity": "Moderate",
  "precautions": [...]
}
```

---

## 🔍 Monitoring & Troubleshooting

### View Logs

```bash
# Stream application logs
az webapp log tail \
  --resource-group cpsu-health-rg \
  --name cpsu-health-backend-XXXX
```

### Check ML Service Status

```bash
# Check if ML model loaded successfully
curl "https://$BACKEND_URL/api/health/"
```

### Common Issues

#### Issue 1: "ML model not found"

**Solution**: Ensure ML models are included in deployment:

```bash
# Check if .pkl files are in repository
git ls-files | grep -E "\.pkl$"

# If not tracked, add them:
cd ML/models
git add disease_predictor_v2.pkl
git commit -m "Add ML model for deployment"
git push
```

#### Issue 2: "ModuleNotFoundError: scikit-learn"

**Solution**: Verify `requirements.txt` includes ML dependencies:

```bash
# Check Django/requirements.txt
grep -E "scikit-learn|joblib|numpy|pandas" Django/requirements.txt
```

Expected:
```
scikit-learn==1.3.2
joblib==1.3.2
numpy==1.24.3
pandas==2.0.3
```

#### Issue 3: Database connection errors

**Solution**: Check DATABASE_URL encoding:

```python
# URL-encode password special characters
python -c "from urllib.parse import quote; print(quote('your-password', safe=''))"
```

---

## 🎉 Post-Deployment Steps

### 1. Create Superuser (Admin Account)

```bash
az webapp ssh --resource-group cpsu-health-rg --name cpsu-health-backend-XXXX

cd /home/site/wwwroot/Django
python manage.py createsuperuser
# Use school_id (not username), e.g., "admin-001"
```

### 2. Test All Endpoints

```bash
# Get base URL
BACKEND_URL="https://$(az webapp show --resource-group cpsu-health-rg --name cpsu-health-backend-XXXX --query defaultHostName -o tsv)"

# Health check
curl "$BACKEND_URL/api/health/"

# Available symptoms
curl "$BACKEND_URL/api/symptoms/available/"

# Register test user
curl -X POST "$BACKEND_URL/api/auth/register/" \
  -H "Content-Type: application/json" \
  -d '{"school_id":"2024-001","password":"test123","name":"Test User"}'
```

### 3. Configure CORS (for Vue.js Frontend)

```bash
# Update allowed hosts
az webapp config appsettings set \
  --resource-group cpsu-health-rg \
  --name cpsu-health-backend-XXXX \
  --settings \
    DJANGO_ALLOWED_HOSTS=".azurewebsites.net,.azurestaticapps.net"
```

---

## 📈 Cost Estimation

| Service | Tier | Monthly Cost |
|---------|------|-------------|
| App Service (B1) | Basic | ~$13 |
| PostgreSQL (B1ms) | Burstable | ~$12 |
| Redis (Basic) | 250MB | ~$15 |
| Application Insights | Free | $0 |
| Key Vault | Standard | ~$0.50 |
| **Total** | | **~$40/month** |

**Free Alternative**: Use Azure for Students (free credits):
- $100 free credits for 12 months
- Free app services (F1 tier, limited)
- [Apply here](https://azure.microsoft.com/en-us/free/students/)

---

## 🔄 Updating Deployment

### Update Code Only

```bash
# After making code changes
git add .
git commit -m "Update Django backend"
git push

# Redeploy
azd deploy
```

### Update Infrastructure

```bash
# After modifying infra/main.bicep
azd up
```

### Retrain ML Model & Redeploy

```bash
# 1. Retrain model locally
cd ML/scripts
python train_model_realistic.py

# 2. Commit new model
git add ../models/disease_predictor_v2.pkl
git commit -m "Update ML model"
git push

# 3. Redeploy
azd deploy
```

---

## 📚 Additional Resources

- [Azure Developer CLI Docs](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/)
- [Django on Azure](https://learn.microsoft.com/en-us/azure/app-service/quickstart-python)
- [PostgreSQL Flexible Server](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/)

---

## 🆘 Need Help?

**Quick Diagnostics:**

```bash
# Check Azure resources
azd show

# Check deployment logs
azd env get-values

# SSH into app
az webapp ssh --resource-group cpsu-health-rg --name cpsu-health-backend-XXXX
```

**Review deployment docs:**
- `QUICKSTART_AZURE.md` - Quick 5-minute setup
- `AZURE_DEPLOYMENT_GUIDE.md` - Detailed manual setup

---

## ✅ Deployment Checklist

- [ ] Azure CLI/azd authenticated (`azd auth login`)
- [ ] Environment variables configured (`.env` file)
- [ ] ML models tracked in git (`git ls-files | grep .pkl`)
- [ ] Django requirements include ML deps (`scikit-learn`, `joblib`)
- [ ] Database migrations run (`python manage.py migrate`)
- [ ] Superuser created (`python manage.py createsuperuser`)
- [ ] Endpoints tested (health, predict, auth)
- [ ] Logs reviewed (no errors)
- [ ] CORS configured for frontend

---

**🎊 You're all set!** Your Django backend with ML models is now running on Azure.
