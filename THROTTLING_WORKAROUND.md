# 🚨 Azure Throttling Workaround Guide

Your Azure Student subscription is being throttled for App Service Plan creation. Here are your options:

---

## ✅ Option 1: Wait & Retry (Recommended)

Azure throttling is usually temporary (15-30 minutes). 

**Wait 30 minutes**, then retry:

```bash
# Create App Service Plan (retry after waiting)
az appservice plan create \
  --name cpsu-health-plan \
  --resource-group cpsu-health-rg \
  --location southeastasia \
  --is-linux \
  --sku F1

# If successful, create Web App
az webapp create \
  --name cpsu-health-backend-$(openssl rand -hex 3) \
  --resource-group cpsu-health-rg \
  --plan cpsu-health-plan \
  --runtime "PYTHON:3.11"
```

---

## ✅ Option 2: Use Azure Portal (Web UI)

The web portal might bypass CLI throttling limits.

### Step-by-Step:

1. **Go to Azure Portal**: https://portal.azure.com

2. **Create App Service Plan**:
   - Click **"Create a resource"**
   - Search **"App Service"**
   - Click **Create** → **Web App**
   
3. **Fill in details**:
   ```
   Resource Group: cpsu-health-rg (select existing)
   Name: cpsu-health-backend (must be globally unique)
   Publish: Code
   Runtime stack: Python 3.11
   Operating System: Linux
   Region: Southeast Asia
   
   App Service Plan:
   - Create new: cpsu-health-plan
   - Pricing Plan: Free F1 (or Basic B1 if F1 unavailable)
   ```

4. **Click "Review + Create"** then **"Create"**

5. **Once created**, configure environment variables:
   - Go to your Web App
   - **Configuration** → **Application settings** → **New application setting**
   
   Add these one by one:
   ```
   DATABASE_URL = postgresql://postgres.feqjblkohmlmaifqbhbf:pausadionzon123s@aws-1-ap-south-1.pooler.supabase.com:5432/postgres
   DJANGO_SECRET_KEY = [generate with: python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"]
   DEBUG = False
   DJANGO_ALLOWED_HOSTS = .azurewebsites.net
   PYTHONPATH = /home/site/wwwroot/Django
   SCM_DO_BUILD_DURING_DEPLOYMENT = true
   POST_BUILD_COMMAND = cd Django && python manage.py migrate && python manage.py collectstatic --noinput
   ```

6. **Click "Save"** (app will restart)

7. **Deploy your code**:
   - Go to **Deployment Center**
   - Select **GitHub** → Authorize → Select your repo
   - Branch: **main**
   - Click **Save**

---

## ✅ Option 3: Check Quotas & Contact Support

Check your current quota usage:

```bash
# Check App Service Plan quota
az vm list-usage --location southeastasia --output table | grep -i "app"
```

If you're hitting limits, you can:

1. **Request quota increase**: 
   - Azure Portal → **Help + Support** → **New support request**
   - Issue type: **Service and subscription limits (quotas)**

2. **Use Azure for Students credits differently**:
   - Your subscription has $100 credit
   - Check usage: https://www.microsoftazuresponsorships.com/Balance

---

## ✅ Option 4: Try Different Region

Sometimes throttling is region-specific:

```bash
# Try East US instead
az appservice plan create \
  --name cpsu-health-plan \
  --resource-group cpsu-health-rg \
  --location eastus \
  --is-linux \
  --sku F1
```

---

## ✅ Option 5: Manual Deployment (No Script)

Create resources manually step-by-step:

```bash
# 1. Resource group (already exists ✓)
az group show --name cpsu-health-rg

# 2. Wait 30 minutes, then create plan
az appservice plan create \
  --name cpsu-health-plan \
  --resource-group cpsu-health-rg \
  --location southeastasia \
  --is-linux \
  --sku F1

# 3. Create web app
az webapp create \
  --name cpsu-health-backend \
  --resource-group cpsu-health-rg \
  --plan cpsu-health-plan \
  --runtime "PYTHON:3.11"

# 4. Set environment variables
az webapp config appsettings set \
  --resource-group cpsu-health-rg \
  --name cpsu-health-backend \
  --settings \
    DATABASE_URL="postgresql://postgres.feqjblkohmlmaifqbhbf:pausadionzon123s@aws-1-ap-south-1.pooler.supabase.com:5432/postgres" \
    DJANGO_SECRET_KEY="$(python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')" \
    DEBUG="False" \
    DJANGO_ALLOWED_HOSTS=".azurewebsites.net" \
    PYTHONPATH="/home/site/wwwroot/Django" \
    SCM_DO_BUILD_DURING_DEPLOYMENT="true" \
    POST_BUILD_COMMAND="cd Django && python manage.py migrate && python manage.py collectstatic --noinput"

# 5. Deploy code
git archive --format=zip --output=deploy.zip HEAD
az webapp deployment source config-zip \
  --resource-group cpsu-health-rg \
  --name cpsu-health-backend \
  --src deploy.zip
```

---

## 🕒 What is Throttling?

Azure throttles (rate-limits) API calls to prevent abuse:
- **Student subscriptions** have stricter limits
- Creating multiple resources quickly triggers throttling
- Throttling usually **resets after 15-30 minutes**

---

## 📊 Current Status

✅ Resource Group: `cpsu-health-rg` (created)  
❌ App Service Plan: Throttled  
⏳ Web App: Pending plan creation  

**Next Action**: Wait 30 minutes or use Azure Portal (Option 2)

---

## 🎯 Recommended Action

**Use Azure Portal (Option 2)** - It's the most reliable when CLI is throttled:

1. Go to: https://portal.azure.com
2. Create a Web App (follows GUI wizard)
3. Select existing resource group: `cpsu-health-rg`
4. Configure app settings (paste your DATABASE_URL)
5. Deploy from GitHub

**⏱️ Portal deployment time**: 10-15 minutes

---

## 🆘 Quick Help

**Question**: How long should I wait?  
**Answer**: 30 minutes is usually enough for throttling to reset.

**Question**: Can I use a different Azure account?  
**Answer**: Yes, but you'll need another email with Azure for Students eligibility.

**Question**: Will this cost money?  
**Answer**: F1 tier is FREE. B1 tier is $13/month (deducted from your $100 credit).

---

**Next**: Try **Option 2 (Azure Portal)** or wait 30 minutes for **Option 1 (CLI retry)**
