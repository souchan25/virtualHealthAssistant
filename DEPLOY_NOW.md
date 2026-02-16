# ✅ Azure Deployment Ready!

Your Django backend with ML models is ready to deploy to Azure with your Supabase database.

---

## 🎯 What's Been Prepared

✅ **ML Models** - Added to git (`disease_predictor_v2.pkl` - 3.2MB)  
✅ **Deployment Scripts** - Windows (.bat) and Linux (.sh) versions  
✅ **Configuration** - Settings optimized for Azure App Service  
✅ **Startup Script** - Auto-runs migrations and collects static files  
✅ **Documentation** - Complete guides created  

---

## 🚀 Deploy Now (3 Easy Steps)

### Step 1: Get Your Supabase Connection String

Go to [Supabase Dashboard](https://app.supabase.com/) → Your Project → Settings → Database

Copy the **Connection string (URI)** with **Connection Pooling** enabled.

Example:
```
postgresql://postgres.abcde12345:YourPassword@aws-0-us-east-1.pooler.supabase.com:6543/postgres
```

**⚠️ Important**: If your password has special characters `@#$%`, encode them:
```bash
python -c "from urllib.parse import quote; print(quote('YourP@ssw0rd', safe=''))"
```

### Step 2: Run Deployment Script

**Windows (Command Prompt or PowerShell):**
```cmd
deploy-azure-supabase.bat
```

**Git Bash or Linux/Mac:**
```bash
chmod +x deploy-azure-supabase.sh
./deploy-azure-supabase.sh
```

### Step 3: Follow Prompts

The script will ask:
1. ✅ DATABASE_URL (paste your Supabase connection string)
2. ✅ Resource group name (press Enter for default: `cpsu-health-rg`)
3. ✅ App name (press Enter for default: `cpsu-health-backend-XXXXXX`)
4. ✅ Region (press Enter for default: `eastus`)

**Deployment time**: 5-7 minutes

---

## 📋 What Happens During Deployment

1. ✅ **Checks prerequisites** (Azure CLI, Python, ML model)
2. ✅ **Logs into Azure** (opens browser if needed)
3. ✅ **Creates App Service** (B1 tier - ~$13/month)
4. ✅ **Deploys Django + ML** (including 3.2MB model file)
5. ✅ **Configures environment** (DATABASE_URL, Django settings)
6. ✅ **Runs migrations** (on your Supabase database)
7. ✅ **Tests deployment** (health endpoint check)

---

## 🎉 After Deployment

You'll get output like:
```
========================================
Deployment Complete!
========================================

Backend URL: https://cpsu-health-backend-a1b2c3.azurewebsites.net

Test endpoints:
  Health: https://cpsu-health-backend-a1b2c3.azurewebsites.net/api/health/
  Predict: https://cpsu-health-backend-a1b2c3.azurewebsites.net/api/rasa/predict/
```

### Test Your Deployment

```bash
# Replace with your actual URL
BACKEND_URL="https://cpsu-health-backend-a1b2c3.azurewebsites.net"

# Health check
curl $BACKEND_URL/api/health/

# ML prediction test
curl -X POST $BACKEND_URL/api/rasa/predict/ \
  -H "Content-Type: application/json" \
  -d '{"symptoms":["fever","cough","fatigue"]}'
```

### Create Admin Account

```bash
# SSH into your app (replace with your resource group and app name)
az webapp ssh --resource-group cpsu-health-rg --name cpsu-health-backend-XXXXXX

# Create superuser
cd Django
python manage.py createsuperuser
# Use school_id (not username), e.g., "admin-001"
```

---

## 💰 Cost Breakdown

| Service | Tier | Monthly Cost |
|---------|------|-------------|
| Azure App Service | B1 Basic | ~$13 |
| Supabase | Free Tier | $0 |
| **Total** | | **~$13/month** |

**💡 Tip**: Azure for Students gives $100 free credits/year!  
[Apply here](https://azure.microsoft.com/en-us/free/students/)

---

## 📚 Documentation

- **Quick Guide**: [QUICK_DEPLOY_SUPABASE.md](./QUICK_DEPLOY_SUPABASE.md) ⭐ Start here
- **Full CLI Guide**: [DEPLOY_CLI_GUIDE.md](./DEPLOY_CLI_GUIDE.md)
- **Architecture**: [DEPLOYMENT_ARCHITECTURE.md](./DEPLOYMENT_ARCHITECTURE.md)
- **Portal Guide**: [QUICKSTART_AZURE.md](./QUICKSTART_AZURE.md)

---

## 🔧 Useful Commands

### View Logs
```bash
az webapp log tail --resource-group cpsu-health-rg --name cpsu-health-backend-XXXXXX
```

### Restart App
```bash
az webapp restart --resource-group cpsu-health-rg --name cpsu-health-backend-XXXXXX
```

### Update Environment Variable
```bash
az webapp config appsettings set \
  --resource-group cpsu-health-rg \
  --name cpsu-health-backend-XXXXXX \
  --settings GEMINI_API_KEY="your-key-here"
```

### Delete Everything (Clean Up)
```bash
az group delete --name cpsu-health-rg --yes
```

---

## 🐛 Troubleshooting

### "azure-cli: command not found"

**Install Azure CLI:**
- Windows: https://aka.ms/installazurecliwindows
- Linux: https://aka.ms/installazureclilinux
- Mac: `brew install azure-cli`

Then run: `az login`

### "ML model not found"

Already fixed! Model is now tracked in git:
```bash
git ls-files | grep disease_predictor_v2.pkl
# Shows: ML/models/disease_predictor_v2.pkl
```

### "Application Error" after deployment

**Check logs:**
```bash
az webapp log tail --resource-group cpsu-health-rg --name cpsu-health-backend-XXXXXX
```

Common issues:
- DATABASE_URL incorrect (test locally first)
- Password has special characters (URL-encode them)
- App still starting up (wait 2-3 minutes)

### Database connection errors

**Test connection string locally:**
```bash
cd Django
export DATABASE_URL="your-supabase-url"
python manage.py migrate
```

If this fails, your connection string needs fixing.

---

## 🎯 Next Steps After Deployment

1. ✅ **Test all endpoints** (health, auth, prediction)
2. ✅ **Create superuser account** (for Django admin)
3. ✅ **Add LLM API keys** (optional, for AI features)
4. ✅ **Deploy Vue.js frontend** (to Azure Static Web Apps)
5. ✅ **Configure custom domain** (optional)

---

## 🆘 Need Help?

**Quick Diagnostics:**
```bash
# Check Azure resources
az group show --name cpsu-health-rg

# Check app status
az webapp show --resource-group cpsu-health-rg --name cpsu-health-backend-XXXXXX --query "state"

# View logs
az webapp log tail --resource-group cpsu-health-rg --name cpsu-health-backend-XXXXXX
```

**Review deployment guides:**
- [QUICK_DEPLOY_SUPABASE.md](./QUICK_DEPLOY_SUPABASE.md) - Step-by-step
- [DEPLOY_CLI_GUIDE.md](./DEPLOY_CLI_GUIDE.md) - Advanced options

---

## ✅ Pre-Deployment Checklist

- [ ] Supabase database created
- [ ] Connection string obtained and password URL-encoded (if needed)
- [ ] Azure CLI installed (`az --version` works)
- [ ] Logged into Azure (`az login`)
- [ ] ML model exists (`ML/models/disease_predictor_v2.pkl` ✓)
- [ ] Git changes committed ✓
- [ ] Ready to deploy!

---

## 🚀 Ready to Deploy?

Run this now:

**Windows:**
```cmd
deploy-azure-supabase.bat
```

**Linux/Mac/Git Bash:**
```bash
./deploy-azure-supabase.sh
```

**Deployment time**: 5-7 minutes ⏱️

---

**Questions?** Check [QUICK_DEPLOY_SUPABASE.md](./QUICK_DEPLOY_SUPABASE.md) for detailed instructions.

**🎊 Good luck with your deployment!**
