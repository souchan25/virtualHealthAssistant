# Azure Deployment Checklist

Use this checklist to ensure successful deployment to Azure with Supabase.

## ✅ Pre-Deployment Checklist

### 1. Prerequisites
- [ ] Azure account with active subscription
- [ ] GitHub account with repository access
- [ ] Supabase account (create at [supabase.com](https://supabase.com))

### 2. Documentation Review
- [ ] Read [QUICKSTART_AZURE.md](./QUICKSTART_AZURE.md) (5-minute guide)
- [ ] Skim [AZURE_DEPLOYMENT_GUIDE.md](./AZURE_DEPLOYMENT_GUIDE.md) (reference)
- [ ] Review [GITHUB_SECRETS_GUIDE.md](./GITHUB_SECRETS_GUIDE.md) (secrets)

## 📋 Deployment Steps

### Phase 1: Supabase Database Setup (5 minutes)

- [ ] **Step 1.1**: Create Supabase project
  - Go to [Supabase Dashboard](https://app.supabase.com/)
  - Click "New Project"
  - Project name: `cpsu-health-assistant`
  - Generate strong password (save securely!)
  - Choose region closest to Azure region
  
- [ ] **Step 1.2**: Get database connection string
  - Go to Settings → Database
  - Find "Connection String" section
  - Select "Connection Pooling" mode
  - Copy URI connection string
  
- [ ] **Step 1.3**: Handle special characters in password (if needed)
  ```bash
  # If password has @#$%: special characters, encode them:
  python -c "from urllib.parse import quote; print(quote('your-password', safe=''))"
  ```
  
- [ ] **Step 1.4**: Save connection string securely
  ```
  postgresql://postgres.[ref]:[password]@aws-0-us-east-1.pooler.supabase.com:6543/postgres
  ```

### Phase 2: Azure Backend Setup (10 minutes)

- [ ] **Step 2.1**: Create Azure Web App
  - Go to [Azure Portal](https://portal.azure.com/)
  - Create Resource → Web App
  - Name: `cpsu-health-assistant-backend` (must be unique)
  - Runtime: Python 3.11
  - OS: Linux
  - Region: Same as Supabase (e.g., East US)
  - Plan: B1 Basic ($13/month)
  - Click "Review + Create" → "Create"
  
- [ ] **Step 2.2**: Configure GitHub deployment
  - In Web App → Deployment Center
  - Source: GitHub
  - Authorize GitHub
  - Repository: `virtualHealthAssistant`
  - Branch: `main`
  - Save (Azure creates secrets automatically)
  
- [ ] **Step 2.3**: Generate Django secret key
  ```bash
  python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
  ```
  Copy the output
  
- [ ] **Step 2.4**: Add environment variables in Azure
  - Go to Web App → Configuration → Application settings
  - Add the following (click "New application setting" for each):
  
  ```
  DATABASE_URL = [paste Supabase connection string]
  DJANGO_SECRET_KEY = [paste generated key]
  DEBUG = False
  DJANGO_ALLOWED_HOSTS = cpsu-health-assistant-backend.azurewebsites.net,.azurewebsites.net
  PYTHONPATH = /home/site/wwwroot/Django
  WEBSITE_HTTPLOGGING_RETENTION_DAYS = 7
  ```
  
- [ ] **Step 2.5**: Set startup command
  - Go to Configuration → General settings
  - Startup Command: `bash startup.sh`
  - Save and restart
  
- [ ] **Step 2.6**: Verify backend secrets in GitHub
  - Go to GitHub repo → Settings → Secrets → Actions
  - Verify these exist (auto-created by Azure):
    - `AZUREAPPSERVICE_CLIENTID_...`
    - `AZUREAPPSERVICE_TENANTID_...`
    - `AZUREAPPSERVICE_SUBSCRIPTIONID_...`

### Phase 3: Azure Frontend Setup (10 minutes)

- [ ] **Step 3.1**: Create Azure Static Web App
  - Go to Azure Portal
  - Create Resource → Static Web App
  - Name: `cpsu-health-assistant-frontend`
  - Plan: Free
  - Region: East US 2
  - Source: GitHub
  - Repository: `virtualHealthAssistant`
  - Branch: `main`
  - Build Presets: Custom
  - App location: `/Vue`
  - Output location: `dist`
  - Click "Review + Create" → "Create"
  
- [ ] **Step 3.2**: Get deployment token
  - In Static Web App → Manage deployment token
  - Copy the token
  
- [ ] **Step 3.3**: Add GitHub secret
  - Go to GitHub repo → Settings → Secrets → Actions
  - Click "New repository secret"
  - Name: `AZURE_STATIC_WEB_APPS_API_TOKEN`
  - Secret: [paste token]
  - Click "Add secret"
  
- [ ] **Step 3.4**: Configure frontend environment
  - In Static Web App → Configuration → Application settings
  - Add:
  ```
  VITE_API_BASE_URL = https://cpsu-health-assistant-backend.azurewebsites.net/api
  VITE_APP_NAME = CPSU Health Assistant
  VITE_APP_VERSION = 1.0.0
  ```
  
- [ ] **Step 3.5**: Update backend CORS
  - Go back to Web App (backend)
  - Configuration → Application settings
  - Update or add:
  ```
  CORS_ALLOWED_ORIGINS = https://cpsu-health-assistant-frontend.azurestaticapps.net
  ```
  - Save and restart

### Phase 4: Deploy (2 minutes)

- [ ] **Step 4.1**: Trigger deployment
  ```bash
  git push origin main
  ```
  
- [ ] **Step 4.2**: Monitor GitHub Actions
  - Go to GitHub → Actions tab
  - Watch workflows run:
    - "Deploy Django Backend to Azure Web App"
    - "Deploy Vue Frontend to Azure Static Web Apps"
  - Both should show green checkmarks ✓
  
- [ ] **Step 4.3**: Check deployment logs
  - Click on workflow runs to see detailed logs
  - Verify ML model training completed
  - Verify migrations ran successfully

### Phase 5: Verification (5 minutes)

- [ ] **Step 5.1**: Test backend health
  ```bash
  curl https://cpsu-health-assistant-backend.azurewebsites.net/api/health/
  # Should return: {"status": "ok", ...}
  ```
  
- [ ] **Step 5.2**: Test frontend
  - Open browser: `https://cpsu-health-assistant-frontend.azurestaticapps.net`
  - Should see CPSU Health Assistant login page
  - Check browser console for errors
  
- [ ] **Step 5.3**: Test API connection
  - Try registering a new account
  - Try logging in
  - Submit a symptom check
  
- [ ] **Step 5.4**: Test admin panel
  - Go to: `https://cpsu-health-assistant-backend.azurewebsites.net/admin`
  - Login with superuser credentials
  - Verify database connection working
  
- [ ] **Step 5.5**: Check Azure logs
  - Backend: Web App → Log Stream
  - Frontend: Static Web App → Functions (if any errors)

## 🔍 Post-Deployment Checklist

### Monitoring Setup
- [ ] Enable Application Insights on Web App
- [ ] Set up email alerts for errors
- [ ] Configure log retention period

### Security Audit
- [ ] Verify HTTPS is working (both frontend and backend)
- [ ] Check CORS settings are correct
- [ ] Verify database password is secure
- [ ] Confirm DEBUG=False in production
- [ ] Test authentication flow

### Performance
- [ ] Test page load times
- [ ] Check ML prediction response time
- [ ] Verify static files are cached
- [ ] Test from different geographic locations

### Backups
- [ ] Verify Supabase automatic backups are enabled
- [ ] Document backup restoration procedure
- [ ] Test database backup download

### Documentation
- [ ] Update any custom domain settings (if applicable)
- [ ] Document production URLs
- [ ] Share credentials with team securely
- [ ] Update internal wiki/docs

## 🚨 Troubleshooting

### Issue: Backend shows "Application Error"
- [ ] Check Azure Web App → Log Stream
- [ ] Verify DATABASE_URL is correct
- [ ] Verify DJANGO_SECRET_KEY is set
- [ ] Check GitHub Actions deployment logs
- [ ] Try restarting the Web App

### Issue: Frontend can't connect to backend
- [ ] Verify CORS_ALLOWED_ORIGINS includes frontend URL
- [ ] Check VITE_API_BASE_URL in Static Web App config
- [ ] Test backend directly with curl
- [ ] Check browser console for CORS errors

### Issue: Database connection failed
- [ ] Verify password encoding (special characters)
- [ ] Test connection string locally:
  ```bash
  python -c "import psycopg2; conn = psycopg2.connect('YOUR_URL'); print('OK')"
  ```
- [ ] Check Supabase connection pooling settings
- [ ] Try direct connection (port 5432) vs pooler (port 6543)

### Issue: ML model not found
- [ ] Check GitHub Actions logs for training step
- [ ] Verify ML/models/ directory was deployed
- [ ] SSH into Web App and check file:
  ```bash
  ls -la /home/site/wwwroot/ML/models/
  ```

### Issue: GitHub Actions failing
- [ ] Verify all secrets are configured
- [ ] Check workflow syntax
- [ ] Review error messages in Actions logs
- [ ] Try running workflow manually

## 📞 Support Resources

- [ ] Review [AZURE_DEPLOYMENT_GUIDE.md](./AZURE_DEPLOYMENT_GUIDE.md)
- [ ] Check [GITHUB_SECRETS_GUIDE.md](./GITHUB_SECRETS_GUIDE.md)
- [ ] Consult [Azure Documentation](https://docs.microsoft.com/azure)
- [ ] Check [Supabase Docs](https://supabase.com/docs)

## ✅ Deployment Complete!

Once all items are checked, your application is successfully deployed! 🎉

**Production URLs**:
- Frontend: `https://cpsu-health-assistant-frontend.azurestaticapps.net`
- Backend: `https://cpsu-health-assistant-backend.azurewebsites.net`
- Admin: `https://cpsu-health-assistant-backend.azurewebsites.net/admin`

**Next Steps**:
1. Share URLs with stakeholders
2. Set up monitoring alerts
3. Document any custom configurations
4. Plan regular maintenance schedule

---

**Checklist Version**: 1.0  
**Last Updated**: February 2026
