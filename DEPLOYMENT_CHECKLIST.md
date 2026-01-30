# 🚀 Quick Deployment Checklist

Use this checklist to ensure smooth deployment of CPSU Virtual Health Assistant.

## Pre-Deployment

- [ ] **GitHub Student Developer Pack activated**
  - Go to https://education.github.com/pack
  - Verify your student status
  - Access benefits (Railway, Vercel, DigitalOcean, etc.)

- [ ] **Repository is on GitHub**
  - Code is committed and pushed
  - All sensitive data removed from code
  - .env files not committed

- [ ] **ML Model trained**
  - Run: `cd ML/scripts && python train_model_realistic.py`
  - Verify: `ML/models/disease_predictor_v2.pkl` exists
  - Model should be ~2-5MB in size

- [ ] **Local testing completed**
  - Backend runs: `cd Django && python manage.py runserver`
  - Frontend builds: `cd Vue && npm run build`
  - API endpoints working
  - Database migrations successful

## Backend Deployment (Railway/Render)

- [ ] **Platform account created**
  - [ ] Railway: https://railway.app/
  - [ ] OR Render: https://render.com/

- [ ] **Project created from GitHub repo**
  - Connected repository
  - Auto-detected Django/Python

- [ ] **PostgreSQL database added**
  - Database provisioned
  - DATABASE_URL auto-configured

- [ ] **Environment variables configured**
  ```
  Required:
  - [ ] SECRET_KEY (generate new one!)
  - [ ] DEBUG=False
  - [ ] ALLOWED_HOSTS=your-domain.railway.app
  - [ ] DATABASE_URL (auto-configured)
  - [ ] CORS_ALLOWED_ORIGINS=https://your-frontend.vercel.app
  
  Optional (for LLM features):
  - [ ] GEMINI_API_KEY
  - [ ] OPENROUTER_API_KEY
  - [ ] COHERE_API_KEY
  ```

- [ ] **Build configuration verified**
  - railway.json or render.yaml present
  - Build command includes ML model training
  - Migrations run automatically

- [ ] **Backend deployed successfully**
  - [ ] Check deployment logs
  - [ ] Visit: https://your-backend.railway.app/api/
  - [ ] Admin panel accessible: /admin/

- [ ] **Create superuser**
  - Use platform terminal/SSH
  - Run: `python Django/manage.py createsuperuser`
  - Use school_id (not username!)

## Frontend Deployment (Vercel/Netlify)

- [ ] **Platform account created**
  - [ ] Vercel: https://vercel.com/
  - [ ] OR Netlify: https://netlify.com/

- [ ] **Project imported from GitHub**
  - Framework: Vite
  - Root directory: Vue
  - Build command: npm run build
  - Output directory: dist

- [ ] **Environment variables configured**
  ```
  - [ ] VITE_API_BASE_URL=https://your-backend.railway.app/api
  - [ ] VITE_RASA_URL=https://your-rasa.railway.app
  - [ ] VITE_APP_NAME=CPSU Health Assistant
  - [ ] VITE_APP_VERSION=1.0.0
  ```

- [ ] **Frontend deployed successfully**
  - [ ] Build completed without errors
  - [ ] Visit: https://your-frontend.vercel.app
  - [ ] All pages load correctly
  - [ ] API calls working

## Post-Deployment Configuration

- [ ] **Update CORS settings**
  - Add frontend URL to backend CORS_ALLOWED_ORIGINS
  - Redeploy backend if needed

- [ ] **Test all features**
  - [ ] User registration works
  - [ ] Login/logout works
  - [ ] Symptom checker predicts diseases
  - [ ] ML predictions accurate
  - [ ] Chat functionality works
  - [ ] Profile updates work
  - [ ] Admin panel accessible

- [ ] **LLM APIs configured (optional)**
  - [ ] Gemini API key added and tested
  - [ ] OpenRouter API key added and tested
  - [ ] Cohere API key added and tested
  - [ ] Hybrid ML+LLM predictions working

- [ ] **Database backup enabled**
  - Railway: Automatic with PostgreSQL
  - Render: Enable in database settings
  - Test restore process

## Security Checklist

- [ ] **Production settings active**
  - [ ] DEBUG=False
  - [ ] Strong SECRET_KEY generated
  - [ ] HTTPS enabled (automatic)
  - [ ] Security headers configured

- [ ] **Sensitive data protected**
  - [ ] No API keys in code
  - [ ] .env files not committed
  - [ ] Environment variables secured

- [ ] **CORS properly configured**
  - Only allowed origins listed
  - Credentials allowed only for trusted origins

- [ ] **Admin access secured**
  - [ ] Strong admin password
  - [ ] 2FA enabled (if supported)
  - [ ] Limited admin users

## Monitoring & Maintenance

- [ ] **Set up monitoring**
  - [ ] Railway/Render dashboard monitoring
  - [ ] Email alerts enabled
  - [ ] Error logging configured

- [ ] **Document deployment**
  - [ ] URLs documented
  - [ ] Credentials stored securely (1Password, etc.)
  - [ ] Team members have access

- [ ] **Plan for updates**
  - [ ] Auto-deploy on push configured
  - [ ] Staging environment considered
  - [ ] Rollback procedure documented

## Cost Verification

- [ ] **Verify FREE tier usage**
  - [ ] Railway: Under $5/month credit
  - [ ] Vercel: Unlimited personal projects
  - [ ] Database: Within free tier limits

- [ ] **Set up billing alerts**
  - [ ] Railway: Monitor credit usage
  - [ ] Set alerts before credit exhausted

## Final Testing

- [ ] **Create test accounts**
  - [ ] Student account
  - [ ] Staff account
  - [ ] Test permissions

- [ ] **End-to-end testing**
  - [ ] Register → Login → Symptom Check → View Results
  - [ ] Chat with assistant
  - [ ] View history
  - [ ] Update profile
  - [ ] Staff dashboard (if staff)

- [ ] **Performance testing**
  - [ ] Page load times acceptable
  - [ ] API response times < 500ms
  - [ ] ML predictions < 200ms

- [ ] **Mobile testing**
  - [ ] Responsive design works
  - [ ] Touch interactions work
  - [ ] All features accessible

## Launch

- [ ] **Share with stakeholders**
  - [ ] Send frontend URL
  - [ ] Provide user guide
  - [ ] Demo the system

- [ ] **Monitor initial usage**
  - [ ] Watch error logs
  - [ ] Monitor performance
  - [ ] Collect feedback

---

## Quick URLs Reference

```bash
# Backend
Production API: https://__________.railway.app/api/
Admin Panel:    https://__________.railway.app/admin/

# Frontend
Production:     https://__________.vercel.app

# Monitoring
Railway:        https://railway.app/project/__________
Vercel:         https://vercel.com/__________/projects/__________
```

---

## Emergency Contacts

- **Railway Support**: https://railway.app/help
- **Vercel Support**: https://vercel.com/support
- **GitHub Issues**: [Your repo issues URL]

---

**Deployment Date**: _________________  
**Deployed By**: _________________  
**Production URLs Verified**: ☐ Yes ☐ No

---

**🎉 Congratulations on your deployment!**
