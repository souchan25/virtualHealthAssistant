# Azure Deployment Guide with Supabase

This guide walks you through deploying the CPSU Virtual Health Assistant to Azure with Supabase as the database.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Azure Deployment                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────┐      ┌──────────────────────┐   │
│  │  Azure Static Web    │      │   Azure Web App      │   │
│  │      Apps (SWA)      │─────▶│   (App Service)      │   │
│  │                      │      │                      │   │
│  │   Vue.js Frontend    │      │  Django Backend      │   │
│  │   (Port 443/HTTPS)   │      │  (Python 3.11)       │   │
│  └──────────────────────┘      └──────────┬───────────┘   │
│                                            │                │
│                                            │                │
└────────────────────────────────────────────┼────────────────┘
                                             │
                                             ▼
                                  ┌──────────────────────┐
                                  │   Supabase (Cloud)   │
                                  │  PostgreSQL Database │
                                  │   (Managed Service)  │
                                  └──────────────────────┘
```

## 📋 Prerequisites

1. **Azure Account** with an active subscription
2. **GitHub Account** with repository access
3. **Supabase Account** with a project created

### Required Tools
- Azure CLI (for local testing)
- Git
- Python 3.11+ (for local testing)
- Node.js 18+ (for local testing)

## 🗄️ Part 1: Setting Up Supabase Database

### Step 1: Create Supabase Project

1. Go to [Supabase Dashboard](https://app.supabase.com/)
2. Click **"New Project"**
3. Fill in:
   - **Project Name**: `cpsu-health-assistant`
   - **Database Password**: Generate a strong password (save it securely!)
   - **Region**: Choose closest to your Azure region
4. Click **"Create new project"** (takes ~2 minutes)

### Step 2: Get Database Connection String

1. In your Supabase project, go to **Settings** → **Database**
2. Scroll down to **Connection String** section
3. Select **"URI"** mode
4. Copy the connection string (looks like):
   ```
   postgresql://postgres.[project-ref]:[YOUR-PASSWORD]@aws-0-us-east-1.pooler.supabase.com:6543/postgres
   ```
5. **Replace `[YOUR-PASSWORD]`** with your actual database password

### Step 3: URL-Encode Special Characters (if needed)

If your password contains special characters, encode them:

```bash
# Using Python
python -c "from urllib.parse import quote; print(quote('your-password', safe=''))"

# Common encodings:
# @ → %40
# # → %23
# $ → %24
# % → %25
# : → %3A
```

Example:
- Original: `my@pass#word`
- Encoded: `my%40pass%23word`

## 🚀 Part 2: Deploying Django Backend to Azure Web App

### Step 1: Create Azure Web App

#### Option A: Using Azure Portal

1. Go to [Azure Portal](https://portal.azure.com/)
2. Click **"Create a resource"** → **"Web App"**
3. Fill in:
   - **Resource Group**: Create new `cpsu-health-rg`
   - **Name**: `cpsu-health-assistant-backend` (must be globally unique)
   - **Runtime stack**: Python 3.11
   - **Operating System**: Linux
   - **Region**: Same as your Supabase (e.g., East US)
   - **Pricing Plan**: B1 or higher (F1 free tier may be too slow)
4. Click **"Review + Create"** → **"Create"**

#### Option B: Using Azure CLI

```bash
# Login to Azure
az login

# Create resource group
az group create --name cpsu-health-rg --location eastus

# Create App Service Plan
az appservice plan create \
  --name cpsu-health-plan \
  --resource-group cpsu-health-rg \
  --sku B1 \
  --is-linux

# Create Web App
az webapp create \
  --resource-group cpsu-health-rg \
  --plan cpsu-health-plan \
  --name cpsu-health-assistant-backend \
  --runtime "PYTHON:3.11"
```

### Step 2: Configure GitHub Actions Deployment

1. In your Web App, go to **Deployment Center**
2. Choose **GitHub** as source
3. Authorize GitHub access
4. Select:
   - **Organization**: Your GitHub account
   - **Repository**: `virtualHealthAssistant`
   - **Branch**: `main`
5. GitHub Actions will auto-generate credentials
6. Click **"Save"** (this creates secrets in your GitHub repo)

**Important**: Azure creates these secrets automatically:
- `AZUREAPPSERVICE_CLIENTID_...`
- `AZUREAPPSERVICE_TENANTID_...`
- `AZUREAPPSERVICE_SUBSCRIPTIONID_...`

### Step 3: Configure Environment Variables in Azure

In your Web App, go to **Configuration** → **Application settings**, add:

```
DATABASE_URL = postgresql://postgres.[project-ref]:[password]@aws-0-region.pooler.supabase.com:6543/postgres
DJANGO_SECRET_KEY = [generate-a-random-secret-key]
DEBUG = False
DJANGO_ALLOWED_HOSTS = cpsu-health-assistant-backend.azurewebsites.net,.azurewebsites.net
CORS_ALLOWED_ORIGINS = https://your-frontend-url.azurestaticapps.net
WEBSITE_HTTPLOGGING_RETENTION_DAYS = 7
PYTHONPATH = /home/site/wwwroot/Django
DJANGO_SETTINGS_MODULE = health_assistant.settings

# Optional: LLM API Keys (if using AI features)
GEMINI_API_KEY = your-gemini-key
OPENROUTER_API_KEY = your-openrouter-key
COHERE_API_KEY = your-cohere-key
```

**Generate Django Secret Key:**
```bash
python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
```

### Step 4: Configure Startup Command

In your Web App, go to **Configuration** → **General settings**:

Set **Startup Command** to:
```bash
bash startup.sh
```

Click **"Save"** and restart the app.

### Step 5: Deploy via GitHub Actions

The workflow `azure-django-backend.yml` will automatically:
1. ✅ Build Django app
2. ✅ Train ML model
3. ✅ Run migrations
4. ✅ Collect static files
5. ✅ Deploy to Azure

**Push to main branch to trigger deployment:**
```bash
git add .
git commit -m "Configure Azure deployment"
git push origin main
```

Monitor deployment in **GitHub Actions** tab.

### Step 6: Verify Backend Deployment

Test your backend:
```bash
# Health check
curl https://cpsu-health-assistant-backend.azurewebsites.net/api/health/

# Should return 200 OK
```

Check logs in Azure:
```bash
az webapp log tail \
  --name cpsu-health-assistant-backend \
  --resource-group cpsu-health-rg
```

Or in Azure Portal: **Monitoring** → **Log Stream**

## 🎨 Part 3: Deploying Vue Frontend to Azure Static Web Apps

### Step 1: Create Azure Static Web App

#### Option A: Using Azure Portal

1. Go to [Azure Portal](https://portal.azure.com/)
2. Click **"Create a resource"** → **"Static Web App"**
3. Fill in:
   - **Resource Group**: Use existing `cpsu-health-rg`
   - **Name**: `cpsu-health-assistant-frontend`
   - **Hosting Plan**: Free (sufficient for most cases)
   - **Region**: East US 2 (or your preferred region)
   - **Source**: GitHub
   - **Organization**: Your GitHub account
   - **Repository**: `virtualHealthAssistant`
   - **Branch**: `main`
   - **Build Presets**: Custom
   - **App location**: `/Vue`
   - **Output location**: `dist`
4. Click **"Review + Create"** → **"Create"**

#### Option B: Using Azure CLI

```bash
# Create Static Web App with GitHub integration
az staticwebapp create \
  --name cpsu-health-assistant-frontend \
  --resource-group cpsu-health-rg \
  --source https://github.com/YOUR-USERNAME/virtualHealthAssistant \
  --location "East US 2" \
  --branch main \
  --app-location "Vue" \
  --output-location "dist" \
  --login-with-github
```

### Step 2: Get Static Web App Deployment Token

1. In your Static Web App, go to **Overview**
2. Click **"Manage deployment token"**
3. Copy the token (looks like: `abc123...xyz`)
4. Add to GitHub Secrets:
   - Go to your GitHub repo → **Settings** → **Secrets and variables** → **Actions**
   - Click **"New repository secret"**
   - Name: `AZURE_STATIC_WEB_APPS_API_TOKEN`
   - Value: [paste your token]

### Step 3: Configure Environment Variables

In your Static Web App, go to **Configuration** → **Application settings**, add:

```
VITE_API_BASE_URL = https://cpsu-health-assistant-backend.azurewebsites.net/api
VITE_APP_NAME = CPSU Health Assistant
VITE_APP_VERSION = 1.0.0
```

### Step 4: Update CORS in Backend

Go back to your **Web App (backend)** → **Configuration**, update:

```
CORS_ALLOWED_ORIGINS = https://cpsu-health-assistant-frontend.azurestaticapps.net
```

Or add to your backend's Django settings if using regex patterns:
```python
CORS_ALLOWED_ORIGIN_REGEXES = [
    r"^https://.*\.azurestaticapps\.net$",
]
```

### Step 5: Deploy via GitHub Actions

The workflow `azure-vue-frontend.yml` will automatically:
1. ✅ Build Vue app
2. ✅ Run type checks
3. ✅ Deploy to Azure Static Web Apps

**Push to main branch to trigger deployment:**
```bash
git add .
git commit -m "Deploy Vue frontend"
git push origin main
```

### Step 6: Verify Frontend Deployment

Your app will be available at:
```
https://cpsu-health-assistant-frontend.azurestaticapps.net
```

Or the custom domain shown in Azure Portal.

## 🔐 Part 4: Security Checklist

### Backend Security
- [x] `DEBUG = False` in production
- [x] Strong `DJANGO_SECRET_KEY` (50+ random characters)
- [x] URL-encoded database password
- [x] HTTPS enabled (automatic with Azure)
- [x] CORS properly configured
- [x] Allowed hosts set correctly
- [x] Security headers enabled

### Database Security
- [x] Use Supabase connection pooler (port 6543) for better performance
- [x] Direct connection (port 5432) only for migrations if needed
- [x] Database password never committed to Git
- [x] Row Level Security (RLS) enabled in Supabase (optional but recommended)

### Frontend Security
- [x] API URLs use HTTPS
- [x] CSP headers configured in `staticwebapp.config.json`
- [x] No sensitive data in frontend code
- [x] Environment variables set correctly

## 🔧 Troubleshooting

### Backend Issues

**Problem**: "Application Error" or 500 errors
```bash
# Check logs
az webapp log tail --name cpsu-health-assistant-backend --resource-group cpsu-health-rg

# Common fixes:
# 1. Verify DATABASE_URL is correct (check special character encoding)
# 2. Verify DJANGO_SECRET_KEY is set
# 3. Check startup.sh is executable
# 4. Verify ML model was deployed (check deployment logs)
```

**Problem**: Database connection failed
```bash
# Test connection string locally
python -c "import psycopg2; conn = psycopg2.connect('YOUR_DATABASE_URL'); print('Connected!')"

# Common issues:
# - Special characters in password not encoded
# - Wrong port (use 6543 for pooler, 5432 for direct)
# - IP not whitelisted in Supabase (check Settings → Database → Connection Pooling)
```

**Problem**: ML model not found
```bash
# Check if model exists in deployment
az webapp ssh --name cpsu-health-assistant-backend --resource-group cpsu-health-rg
ls -la /home/site/wwwroot/ML/models/

# If missing, re-run GitHub Actions workflow
```

### Frontend Issues

**Problem**: Cannot connect to backend API
```
# Verify CORS settings in backend
# Check VITE_API_BASE_URL in Static Web App configuration
# Test backend directly:
curl https://cpsu-health-assistant-backend.azurewebsites.net/api/health/
```

**Problem**: 404 errors on page refresh
```
# Solution: Verify staticwebapp.config.json is deployed
# It should have navigationFallback configured
```

## 📊 Monitoring & Logs

### Backend Logs (Django)
```bash
# Real-time logs
az webapp log tail --name cpsu-health-assistant-backend --resource-group cpsu-health-rg

# Download logs
az webapp log download --name cpsu-health-assistant-backend --resource-group cpsu-health-rg
```

### Frontend Logs (Static Web App)
- Go to Azure Portal → Your Static Web App → **Monitoring** → **Application Insights**
- View requests, errors, and performance metrics

### Database Logs (Supabase)
- Go to Supabase Dashboard → **Logs** → **Postgres Logs**
- Monitor queries, connections, and errors

## 💰 Cost Estimate

| Service | Tier | Monthly Cost (USD) |
|---------|------|--------------------|
| Azure Web App (Backend) | B1 Basic | ~$13/month |
| Azure Static Web Apps (Frontend) | Free | $0 |
| Supabase Database | Free (up to 500MB) | $0 |
| **Total** | | **~$13/month** |

*Upgrade to B2 ($26/month) or B3 ($52/month) for better performance if needed.*

## 🔄 CI/CD Pipeline

Every push to `main` branch triggers:

1. **Backend Workflow** (`azure-django-backend.yml`):
   - Builds Django app
   - Trains ML model
   - Deploys to Azure Web App

2. **Frontend Workflow** (`azure-vue-frontend.yml`):
   - Builds Vue app
   - Deploys to Azure Static Web Apps

3. **CI/CD Workflow** (`ci-cd.yml`):
   - Runs tests (backend & frontend)
   - Linting and security scans

## 📚 Additional Resources

- [Azure Web Apps Documentation](https://docs.microsoft.com/en-us/azure/app-service/)
- [Azure Static Web Apps Documentation](https://docs.microsoft.com/en-us/azure/static-web-apps/)
- [Supabase Documentation](https://supabase.com/docs)
- [Django Deployment Checklist](https://docs.djangoproject.com/en/4.2/howto/deployment/checklist/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## 🆘 Support

If you encounter issues:
1. Check GitHub Actions logs for deployment errors
2. Review Azure Application Insights for runtime errors
3. Check Supabase logs for database issues
4. Consult the documentation above

---

**Last Updated**: February 2026
**Maintainer**: CPSU Virtual Health Assistant Team
