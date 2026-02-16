# 🚀 Quick Deploy to Azure (with Supabase)

**5-minute deployment** of Django backend + ML models to Azure using your existing Supabase database.

---

## ✅ Prerequisites

- [x] **Supabase database** with connection string
- [x] **Azure account** (free tier works)
- [x] **Azure CLI** installed (verify: `az --version`)

---

## 📝 Step 1: Get Supabase Connection String

1. Go to [Supabase Dashboard](https://app.supabase.com/)
2. Select your project
3. Go to **Settings** → **Database**
4. Copy **Connection string** (URI mode, **Connection Pooling**)
5. Replace `[YOUR-PASSWORD]` with your actual password

Example:
```
postgresql://postgres.abcde12345:MyPassword@aws-0-us-east-1.pooler.supabase.com:6543/postgres
```

**⚠️ Important**: If password has special characters `(@#$%)`, encode them:
```bash
python -c "from urllib.parse import quote; print(quote('MyP@ss#word', safe=''))"
# Result: MyP%40ss%23word
```

---

## 🚀 Step 2: Run Deployment Script

### Option A: Windows

```cmd
cd c:\Users\Souchan\OneDrive\Desktop\VirtualAssistant
deploy-azure-supabase.bat
```

### Option B: Linux/Mac/Git Bash

```bash
cd ~/OneDrive/Desktop/VirtualAssistant  # or your path
chmod +x deploy-azure-supabase.sh
./deploy-azure-supabase.sh
```

**The script will:**
1. ✅ Check prerequisites (Azure CLI, Python, ML model)
2. ✅ Prompt for Supabase DATABASE_URL
3. ✅ Create Azure resources (App Service only - no database)
4. ✅ Deploy Django + ML models
5. ✅ Configure environment variables
6. ✅ Run migrations on your Supabase database

**Deployment time**: ~5-7 minutes

---

## ✅ What You'll Be Asked

1. **DATABASE_URL**: Your Supabase connection string
2. **Resource group name**: (default: `cpsu-health-rg`)
3. **App Service name**: (default: `cpsu-health-backend-XXXXX`)
4. **Region**: (default: `eastus` - choose same as Supabase)

---

## 🔍 Step 3: Verify Deployment

After deployment completes, you'll get a URL like:
```
https://cpsu-health-backend-a1b2c3.azurewebsites.net
```

Test endpoints:

```bash
# Health check
curl https://your-app.azurewebsites.net/api/health/

# ML prediction
curl -X POST https://your-app.azurewebsites.net/api/rasa/predict/ \
  -H "Content-Type: application/json" \
  -d '{"symptoms":["fever","cough"]}'
```

---

## 👤 Step 4: Create Admin User

```bash
# SSH into your app
az webapp ssh --resource-group cpsu-health-rg --name cpsu-health-backend-XXXXX

# Create superuser
cd Django
python manage.py createsuperuser
# Use school_id (not username), e.g., "admin-001"
```

---

## 📊 Cost Breakdown (with Supabase)

| Service | Tier | Monthly Cost |
|---------|------|-------------|
| Azure App Service B1 | Basic | ~$13 |
| Supabase Free Tier | Free | $0 |
| **Total** | | **~$13/month** |

**💰 Savings**: $25/month vs full Azure stack (no Azure PostgreSQL or Redis needed)

---

## 🔧 Common Tasks

### View Logs
```bash
az webapp log tail --resource-group cpsu-health-rg --name cpsu-health-backend-XXXXX
```

### Update Environment Variable
```bash
az webapp config appsettings set \
  --resource-group cpsu-health-rg \
  --name cpsu-health-backend-XXXXX \
  --settings GEMINI_API_KEY="your-key-here"
```

### Restart App
```bash
az webapp restart --resource-group cpsu-health-rg --name cpsu-health-backend-XXXXX
```

### Redeploy After Code Changes
```bash
# Commit changes
git add .
git commit -m "Update backend"
git push

# Redeploy (if using GitHub deployment)
# Azure auto-deploys on push

# OR manual ZIP deploy:
git archive --format=zip --output=deploy.zip HEAD
az webapp deployment source config-zip \
  --resource-group cpsu-health-rg \
  --name cpsu-health-backend-XXXXX \
  --src deploy.zip
```

### Delete Everything
```bash
az group delete --name cpsu-health-rg --yes --no-wait
```

---

## 🐛 Troubleshooting

### Issue: "Application Error" on website

**Solution**: Check logs for errors
```bash
az webapp log tail --resource-group cpsu-health-rg --name cpsu-health-backend-XXXXX
```

### Issue: "ML model not found"

**Solution**: Verify model is in git
```bash
git ls-files | grep disease_predictor_v2.pkl
# Should show: ML/models/disease_predictor_v2.pkl

# If not found, add it:
git add -f ML/models/disease_predictor_v2.pkl
git commit -m "Add ML model"
git push
```

### Issue: Database connection errors

**Solution**: Test connection string locally
```bash
cd Django
export DATABASE_URL="your-supabase-url"
python manage.py migrate
# If successful, connection string is correct
```

### Issue: "Password authentication failed"

**Solution**: URL-encode special characters in password
```python
from urllib.parse import quote
password = "MyP@ss#word"
encoded = quote(password, safe='')
print(encoded)  # MyP%40ss%23word
```

---

## 🎯 Next Steps

1. **Deploy Vue.js frontend** to Azure Static Web Apps
2. **Configure CORS** to allow frontend domain
3. **Add LLM API keys** (optional):
   ```bash
   az webapp config appsettings set \
     --resource-group cpsu-health-rg \
     --name cpsu-health-backend-XXXXX \
     --settings \
       GEMINI_API_KEY="your-key" \
       OPENROUTER_API_KEY="your-key" \
       COHERE_API_KEY="your-key"
   ```

---

## 📚 Additional Resources

- **Full CLI Guide**: [DEPLOY_CLI_GUIDE.md](./DEPLOY_CLI_GUIDE.md)
- **Azure Portal Guide**: [QUICKSTART_AZURE.md](./QUICKSTART_AZURE.md)
- **Architecture**: [DEPLOYMENT_ARCHITECTURE.md](./DEPLOYMENT_ARCHITECTURE.md)

---

## ✅ Deployment Checklist

- [ ] Supabase database created and connection string obtained
- [ ] Special characters in password URL-encoded
- [ ] Azure CLI installed and logged in (`az login`)
- [ ] ML model exists (`ML/models/disease_predictor_v2.pkl`)
- [ ] Deployment script executed successfully
- [ ] Health endpoint responds (https://your-app.azurewebsites.net/api/health/)
- [ ] ML prediction works (test with curl)
- [ ] Superuser created
- [ ] Logs reviewed (no errors)

---

**🎊 Done!** Your Django backend with ML models is live on Azure with Supabase database.

**Backend URL**: `https://cpsu-health-backend-XXXXX.azurewebsites.net`

**Admin**: `https://cpsu-health-backend-XXXXX.azurewebsites.net/admin/`
