# 🚀 Quick Start: Azure Deployment

This is a condensed guide to get your app deployed to Azure quickly. For detailed instructions, see [AZURE_DEPLOYMENT_GUIDE.md](./AZURE_DEPLOYMENT_GUIDE.md).

## ⚡ 5-Minute Setup

### Prerequisites
- Azure account
- GitHub account
- Supabase account (or create one at [supabase.com](https://supabase.com))

---

## Step 1: Supabase Database (2 minutes)

1. Go to [Supabase Dashboard](https://app.supabase.com/)
2. Click **New Project**
3. Set name: `cpsu-health-assistant`
4. Generate & save database password securely
5. Choose region closest to Azure region
6. Wait ~2 minutes for project creation
7. Go to **Settings** → **Database** → **Connection String**
8. Copy URI connection string (select "Connection Pooling")
9. Replace `[YOUR-PASSWORD]` with your actual password

Your connection string looks like:
```
postgresql://postgres.abcde12345:[YOUR-PASSWORD]@aws-0-us-east-1.pooler.supabase.com:6543/postgres
```

**⚠️ Important**: If password has special characters (@#$%), encode them:
```bash
python -c "from urllib.parse import quote; print(quote('your-password', safe=''))"
```

---

## Step 2: Azure Backend (3 minutes)

### Create Web App

**Using Azure Portal**:
1. [Create Web App](https://portal.azure.com/#create/Microsoft.WebSite)
2. Settings:
   - **Name**: `cpsu-health-assistant-backend` (must be unique)
   - **Runtime**: Python 3.11
   - **Region**: Same as Supabase (e.g., East US)
   - **Plan**: B1 Basic ($13/month)
3. Click **Create**

### Configure GitHub Deployment

1. In your Web App → **Deployment Center**
2. Select **GitHub** → Authorize → Choose:
   - Repo: `virtualHealthAssistant`
   - Branch: `main`
3. **Save** (Azure creates GitHub secrets automatically)

### Add Environment Variables

In Web App → **Configuration** → **Application settings**, click **New** and add:

```
DATABASE_URL = [paste your Supabase connection string]
DJANGO_SECRET_KEY = [generate random 50-char string]
DEBUG = False
DJANGO_ALLOWED_HOSTS = cpsu-health-assistant-backend.azurewebsites.net,.azurewebsites.net
PYTHONPATH = /home/site/wwwroot/Django
```

Generate secret key:
```bash
python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
```

**Save** and wait for restart (~30 seconds)

---

## Step 3: Azure Frontend (3 minutes)

### Create Static Web App

**Using Azure Portal**:
1. [Create Static Web App](https://portal.azure.com/#create/Microsoft.StaticApp)
2. Settings:
   - **Name**: `cpsu-health-assistant-frontend`
   - **Plan**: Free
   - **Region**: East US 2
   - **Source**: GitHub
   - **Repo**: `virtualHealthAssistant`
   - **Branch**: `main`
   - **Build Presets**: Custom
   - **App location**: `/Vue`
   - **Output location**: `dist`
3. Click **Create**

### Get Deployment Token

1. In Static Web App → **Manage deployment token**
2. **Copy** the token
3. Go to GitHub repo → **Settings** → **Secrets** → **Actions**
4. Click **New secret**:
   - Name: `AZURE_STATIC_WEB_APPS_API_TOKEN`
   - Value: [paste token]

### Configure Frontend Settings

In Static Web App → **Configuration** → **Application settings**:

```
VITE_API_BASE_URL = https://cpsu-health-assistant-backend.azurewebsites.net/api
```

---

## Step 4: Update Backend CORS (1 minute)

Go back to **Backend Web App** → **Configuration**, update:

```
CORS_ALLOWED_ORIGINS = https://cpsu-health-assistant-frontend.azurestaticapps.net
```

**Save** and restart.

---

## Step 5: Deploy! (1 command)

```bash
git push origin main
```

This triggers two GitHub Actions workflows:
1. **Backend deployment** (~5 minutes)
   - Builds Django
   - Trains ML model
   - Deploys to Azure Web App

2. **Frontend deployment** (~2 minutes)
   - Builds Vue app
   - Deploys to Static Web App

### Monitor Progress

1. Go to GitHub repo → **Actions** tab
2. Watch workflows run (green ✓ = success)

---

## ✅ Verify Deployment

### Test Backend
```bash
curl https://cpsu-health-assistant-backend.azurewebsites.net/api/health/
# Should return: {"status": "ok", ...}
```

### Test Frontend
Open browser:
```
https://cpsu-health-assistant-frontend.azurestaticapps.net
```

You should see the CPSU Health Assistant login page!

---

## 🎉 You're Done!

Your app is now live on Azure with Supabase database!

**URLs**:
- Frontend: `https://cpsu-health-assistant-frontend.azurestaticapps.net`
- Backend API: `https://cpsu-health-assistant-backend.azurewebsites.net/api`
- Admin Panel: `https://cpsu-health-assistant-backend.azurewebsites.net/admin`

---

## 🔧 Troubleshooting

### Backend shows "Application Error"
1. Check Azure logs: Web App → **Log Stream**
2. Verify `DATABASE_URL` is correct
3. Verify `DJANGO_SECRET_KEY` is set
4. Check GitHub Actions logs for deployment errors

### Frontend can't connect to backend
1. Check `CORS_ALLOWED_ORIGINS` includes your frontend URL
2. Check `VITE_API_BASE_URL` in Static Web App configuration
3. Test backend directly with curl

### Database connection failed
1. Verify password encoding (use URL-encoded version)
2. Test connection string locally:
   ```bash
   python -c "import psycopg2; conn = psycopg2.connect('YOUR_URL'); print('OK')"
   ```
3. Use port 6543 (pooler) not 5432 for production

### ML model not found
1. Check backend deployment logs
2. Verify ML training step succeeded in GitHub Actions
3. SSH into Web App and check `/home/site/wwwroot/ML/models/`

---

## 📚 Next Steps

- [Full Deployment Guide](./AZURE_DEPLOYMENT_GUIDE.md) - Detailed instructions
- [GitHub Secrets Guide](./GITHUB_SECRETS_GUIDE.md) - Managing secrets
- [Workflows README](./.github/workflows/README.md) - CI/CD details

---

## 💰 Cost Estimate

- **Azure Web App (B1)**: ~$13/month
- **Azure Static Web Apps (Free)**: $0/month
- **Supabase (Free tier)**: $0/month up to 500MB

**Total**: ~$13/month

---

## 🆘 Need Help?

1. Check [Troubleshooting section](./AZURE_DEPLOYMENT_GUIDE.md#troubleshooting) in full guide
2. Review GitHub Actions logs
3. Check Azure Application Insights
4. Review Supabase logs

---

**Created**: February 2026  
**Last Updated**: February 2026
