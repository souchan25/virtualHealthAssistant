# 🚀 Quick Deployment Guide

**Deploy CPSU Virtual Health Assistant in 15 minutes using FREE student benefits!**

---

## Prerequisites ✅

- [ ] GitHub account
- [ ] GitHub Student Developer Pack activated ([Get it here](https://education.github.com/pack))
- [ ] Repository forked/cloned

---

## Option 1: Railway + Vercel (Easiest - Recommended) ⭐

**Total time: ~10 minutes | Cost: $0/month**

### Step 1: Backend (Railway) - 5 minutes

1. **Sign up**: Go to [railway.app](https://railway.app/)
   - Click "Login with GitHub"
   - Student benefits auto-apply ($5/month credit)

2. **Deploy Backend**:
   - Click "New Project" → "Deploy from GitHub repo"
   - Select your repository
   - Railway auto-detects Django ✨

3. **Add Database**:
   - In your project, click "New" → "Database" → "Add PostgreSQL"
   - Railway automatically links `DATABASE_URL`

4. **Set Environment Variables**:
   ```bash
   # Required
   SECRET_KEY=<generate-new-key>  # See below how to generate
   DEBUG=False
   ALLOWED_HOSTS=<your-app>.railway.app
   CORS_ALLOWED_ORIGINS=https://<your-frontend>.vercel.app
   
   # Optional (for AI features)
   GEMINI_API_KEY=<your-key>
   OPENROUTER_API_KEY=<your-key>
   COHERE_API_KEY=<your-key>
   ```
   
   **Generate SECRET_KEY**:
   ```python
   python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
   ```

5. **Deploy!**
   - Railway builds and deploys automatically
   - Wait 3-5 minutes for first deployment
   - ✅ Backend is live at: `https://<your-app>.railway.app`

6. **Create Admin User**:
   - In Railway dashboard, click your service → "Settings" → Terminal
   - Run: `python Django/manage.py createsuperuser`
   - Enter school_id (not username!), password, etc.

### Step 2: Frontend (Vercel) - 5 minutes

1. **Sign up**: Go to [vercel.com](https://vercel.com/)
   - Click "Sign Up" → "Continue with GitHub"
   - Free unlimited projects!

2. **Deploy Frontend**:
   - Click "Add New..." → "Project"
   - Import your GitHub repository
   - Configure:
     - **Framework Preset**: Vite
     - **Root Directory**: `Vue`
     - **Build Command**: `npm run build`
     - **Output Directory**: `dist`

3. **Set Environment Variables**:
   ```bash
   VITE_API_BASE_URL=https://<your-backend>.railway.app/api
   VITE_RASA_URL=https://<your-rasa>.railway.app
   VITE_APP_NAME=CPSU Health Assistant
   VITE_APP_VERSION=1.0.0
   ```

4. **Deploy!**
   - Vercel builds and deploys automatically
   - Wait 2-3 minutes
   - ✅ Frontend is live at: `https://<your-app>.vercel.app`

### Step 3: Update CORS

1. **Go back to Railway**
2. **Update environment variable**:
   ```bash
   CORS_ALLOWED_ORIGINS=https://<your-frontend>.vercel.app
   ```
3. **Redeploy** (Railway auto-redeploys on env change)

### Step 4: Test! 🎉

1. Visit your frontend: `https://<your-app>.vercel.app`
2. Register a new user
3. Try symptom checker
4. Check predictions work!

---

## Option 2: Render + Vercel (100% Free Forever)

**Total time: ~15 minutes | Cost: $0/month**

### Backend (Render)

1. Sign up at [render.com](https://render.com/)
2. Click "New +" → "Web Service"
3. Connect GitHub repository
4. Configure:
   ```
   Name: cpsu-health-backend
   Environment: Python 3
   Build Command: cd ML/scripts && python train_model_realistic.py && cd ../../Django && pip install -r requirements.txt && python manage.py collectstatic --noinput
   Start Command: cd Django && gunicorn health_assistant.wsgi:application
   ```
5. Add PostgreSQL: "New +" → "PostgreSQL" → Copy connection URL
6. Set environment variables (same as Railway above)
7. Deploy!

### Frontend (Vercel)

Same as Option 1, Step 2 above.

---

## Option 3: DigitalOcean (Most Control)

**Total time: ~20 minutes | Cost: $0 for first year**

1. Get promo code from [Student Pack](https://education.github.com/pack)
2. Sign up at [digitalocean.com](https://www.digitalocean.com/)
3. Apply promo code → Get $200 credit
4. Deploy using App Platform (similar to Heroku)
5. Follow detailed guide in [DEPLOYMENT.md](DEPLOYMENT.md)

---

## Environment Variables Reference

### Required (Backend)
```bash
SECRET_KEY=<generate-new-unique-key>
DEBUG=False
ALLOWED_HOSTS=<your-backend-domain>
DATABASE_URL=<auto-configured-by-platform>
CORS_ALLOWED_ORIGINS=<your-frontend-url>
```

### Optional (Backend - for AI features)
```bash
GEMINI_API_KEY=<get-free-at-ai.google.dev>
OPENROUTER_API_KEY=<get-free-at-openrouter.ai>
COHERE_API_KEY=<get-free-at-cohere.com>
RASA_ENABLED=False
```

### Required (Frontend)
```bash
VITE_API_BASE_URL=<your-backend-url>/api
VITE_APP_NAME=CPSU Health Assistant
VITE_APP_VERSION=1.0.0
```

---

## Troubleshooting 🔧

### Backend won't start?
- Check deployment logs
- Verify all required env vars are set
- Ensure SECRET_KEY is set
- Check DATABASE_URL is connected

### Frontend can't connect to backend?
- Verify `VITE_API_BASE_URL` is correct
- Check CORS settings in backend
- Ensure backend CORS includes frontend URL
- Check browser console for errors

### ML predictions fail?
- Check build logs for "Training ML model..."
- Model should be trained during deployment
- If not, manually train: `cd ML/scripts && python train_model_realistic.py`

### Database errors?
- Verify DATABASE_URL is set
- Check if migrations ran
- Manually run: `python manage.py migrate`

---

## Cost Breakdown 💰

| Service | Regular Price | With Student Pack | Your Cost |
|---------|---------------|-------------------|-----------|
| Railway Backend | $5/month | $5 credit/month | **$0** |
| Railway Database | Included | Included | **$0** |
| Vercel Frontend | Free | Free | **$0** |
| **Total** | **$5/month** | **$5 credit** | **$0/month** ✅ |

**Duration**: As long as you're a student (credit renews monthly)!

---

## Next Steps 🎯

1. ✅ **Set up custom domain** (optional)
   - Get free .me domain from Namecheap (Student Pack)
   - Point to Vercel/Railway

2. ✅ **Enable monitoring**
   - Check Railway/Vercel dashboards
   - Set up email alerts

3. ✅ **Get API keys** (optional - for best AI accuracy)
   - Gemini: https://ai.google.dev/
   - OpenRouter: https://openrouter.ai/
   - Cohere: https://cohere.com/

4. ✅ **Test thoroughly**
   - Create test accounts
   - Try all features
   - Check mobile responsive

5. ✅ **Share with users**
   - Give them the frontend URL
   - Create user guide
   - Collect feedback

---

## Support 🆘

- **Detailed Guide**: [DEPLOYMENT.md](DEPLOYMENT.md)
- **Student Pack Benefits**: [STUDENT_PACK_GUIDE.md](STUDENT_PACK_GUIDE.md)
- **Deployment Checklist**: [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)
- **Railway Docs**: https://docs.railway.app/
- **Vercel Docs**: https://vercel.com/docs
- **GitHub Issues**: [Open an issue](https://github.com/souchan25/virtualHealthAssistant/issues)

---

## Success! 🎉

Your app is now deployed and accessible worldwide!

**URLs to save:**
- 🌐 Frontend: `https://<your-app>.vercel.app`
- 🔌 Backend API: `https://<your-app>.railway.app/api/`
- 👨‍💼 Admin Panel: `https://<your-app>.railway.app/admin/`

**Total deployment time**: ~10-15 minutes  
**Total cost**: $0/month  
**Uptime**: 99.9%  

**Well done! 🚀**

---

*Last updated: 2026 | Built with ❤️ for CPSU Students*
