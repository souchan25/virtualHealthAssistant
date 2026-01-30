# 🚀 Deployment Guide for GitHub Student Developer Pack

## Overview

This guide will help you deploy the **CPSU Virtual Health Assistant** using **FREE** services available through the GitHub Student Developer Pack. The project consists of:

- **Backend**: Django REST API with ML models
- **Frontend**: Vue.js SPA
- **Database**: PostgreSQL
- **ML Models**: Pre-trained disease prediction models

## 📦 What's Included in GitHub Student Developer Pack

The GitHub Student Developer Pack provides FREE access to:
- **Railway**: $5/month credit (enough for backend + database)
- **Vercel**: Unlimited personal projects
- **Netlify**: 300 build minutes/month
- **DigitalOcean**: $200 credit for 1 year
- **Heroku**: 1000 free dyno hours/month (if available)
- **Azure for Students**: $100 credit
- **AWS Educate**: Free tier credits
- **MongoDB Atlas**: $50 credit

**Get your pack**: https://education.github.com/pack

---

## 🎯 Recommended Deployment Strategy (100% FREE)

### Option 1: Railway + Vercel (Easiest)
- **Backend + DB**: Railway ($5/month credit covers this)
- **Frontend**: Vercel (unlimited free)
- **Total Cost**: $0/month

### Option 2: Render + Vercel
- **Backend + DB**: Render (free tier)
- **Frontend**: Vercel (unlimited free)
- **Total Cost**: $0/month

### Option 3: DigitalOcean (Most Powerful)
- **Everything**: DigitalOcean App Platform ($200 credit)
- **Total Cost**: $0 for first year

---

## 🚀 Deployment Instructions

### A. Backend Deployment (Django)

#### Option A1: Railway (Recommended)

**Step 1: Sign up and connect GitHub**
```bash
1. Go to https://railway.app/
2. Sign in with GitHub
3. Verify GitHub Student Pack benefits
```

**Step 2: Create new project**
```bash
1. Click "New Project"
2. Select "Deploy from GitHub repo"
3. Choose your repository
4. Railway will auto-detect Django
```

**Step 3: Configure environment variables**

In Railway dashboard, go to Variables and add:

```env
# Required
SECRET_KEY=your-generated-secret-key-here
DEBUG=False
ALLOWED_HOSTS=your-app-name.railway.app
DATABASE_URL=${{Postgres.DATABASE_URL}}

# CORS (add your frontend URL)
CORS_ALLOWED_ORIGINS=https://your-frontend.vercel.app

# Optional: LLM APIs (for AI features)
GEMINI_API_KEY=your-gemini-key
OPENROUTER_API_KEY=your-openrouter-key
COHERE_API_KEY=your-cohere-key

# Rasa (optional - can deploy later)
RASA_ENABLED=False
RASA_SERVER_URL=http://localhost:5005
```

**Step 4: Add PostgreSQL database**
```bash
1. In Railway project, click "New"
2. Select "Database" → "PostgreSQL"
3. Railway automatically links DATABASE_URL
```

**Step 5: Deploy**
```bash
# Railway will automatically:
# 1. Install dependencies from requirements.txt
# 2. Train ML model (via buildCommand in railway.json)
# 3. Run migrations
# 4. Start gunicorn server

# Check deployment logs for any errors
```

**Step 6: Create superuser (admin)**
```bash
# In Railway, go to your service → Settings → Terminal
# Run:
python Django/manage.py createsuperuser
```

Your backend is now live at: `https://your-app-name.railway.app`

---

#### Option A2: Render (Alternative)

**Step 1: Sign up**
```bash
1. Go to https://render.com/
2. Sign in with GitHub
```

**Step 2: Create Web Service**
```bash
1. Click "New +" → "Web Service"
2. Connect your GitHub repository
3. Configure:
   - Name: cpsu-health-backend
   - Environment: Python 3
   - Build Command: cd ML/scripts && python train_model_realistic.py && cd ../../Django && pip install -r requirements.txt && python manage.py collectstatic --noinput
   - Start Command: cd Django && gunicorn health_assistant.wsgi:application --bind 0.0.0.0:$PORT
```

**Step 3: Add PostgreSQL**
```bash
1. Click "New +" → "PostgreSQL"
2. Name: cpsu-health-db
3. Copy Internal Database URL
```

**Step 4: Environment Variables**

Same as Railway (see above), but use Render's database URL.

**Step 5: Deploy**

Render will build and deploy automatically.

---

### B. Frontend Deployment (Vue.js)

#### Option B1: Vercel (Recommended)

**Step 1: Install Vercel CLI (optional)**
```bash
npm install -g vercel
```

**Step 2: Deploy via GitHub**
```bash
1. Go to https://vercel.com/
2. Sign in with GitHub
3. Click "Add New..." → "Project"
4. Import your repository
5. Configure:
   - Framework Preset: Vite
   - Root Directory: Vue
   - Build Command: npm run build
   - Output Directory: dist
```

**Step 3: Environment Variables**

In Vercel project settings → Environment Variables:

```env
VITE_API_BASE_URL=https://your-backend.railway.app/api
VITE_RASA_URL=https://your-rasa-server.railway.app
VITE_APP_NAME=CPSU Health Assistant
VITE_APP_VERSION=1.0.0
```

**Step 4: Deploy**

Vercel will automatically deploy on every push to main branch.

Your frontend is now live at: `https://your-project.vercel.app`

---

#### Option B2: Netlify (Alternative)

**Step 1: Sign up**
```bash
1. Go to https://netlify.com/
2. Sign in with GitHub
```

**Step 2: Deploy**
```bash
1. Click "Add new site" → "Import an existing project"
2. Choose GitHub
3. Select your repository
4. Configure:
   - Base directory: Vue
   - Build command: npm run build
   - Publish directory: Vue/dist
```

**Step 3: Environment Variables**

Same as Vercel (see above).

---

### C. Optional: Rasa Chatbot Deployment

The Rasa chatbot can be deployed separately if needed. However, the system works without it (falls back to direct LLM chat).

**Option C1: Railway (Separate Service)**

```bash
1. Create new service in Railway
2. Add Dockerfile for Rasa:
   FROM rasa/rasa:3.6.0-full
   COPY Rasa /app
   WORKDIR /app
   RUN rasa train
   CMD ["rasa", "run", "--enable-api", "--cors", "*"]
3. Deploy and get URL
4. Update backend RASA_SERVER_URL environment variable
```

---

## 🔧 Post-Deployment Configuration

### 1. Update Backend CORS

Add your frontend URL to `CORS_ALLOWED_ORIGINS` in backend environment:

```env
CORS_ALLOWED_ORIGINS=https://your-frontend.vercel.app,https://your-custom-domain.com
```

### 2. Update Frontend API URL

Update `VITE_API_BASE_URL` in frontend environment:

```env
VITE_API_BASE_URL=https://your-backend.railway.app/api
```

### 3. Create Admin User

```bash
# Railway: Use web terminal
# Render: Use SSH
python Django/manage.py createsuperuser
# Enter school_id (not username!), password, etc.
```

### 4. Test the Deployment

**Test Backend:**
```bash
curl https://your-backend.railway.app/api/
# Should return API info
```

**Test Frontend:**
```bash
# Visit https://your-frontend.vercel.app
# Try registering a user
# Try symptom checker
```

---

## 🔑 Getting FREE API Keys for LLM Features

The system works without LLM APIs (ML-only), but for best accuracy (90-98%), add these FREE keys:

### 1. Google Gemini (FREE tier)
```bash
1. Go to https://ai.google.dev/
2. Sign in with Google account
3. Get API key
4. Add to backend env: GEMINI_API_KEY=your-key
```

### 2. OpenRouter (Grok - FREE tier)
```bash
1. Go to https://openrouter.ai/
2. Sign up
3. Get API key
4. Add to backend env: OPENROUTER_API_KEY=your-key
```

### 3. Cohere (FREE tier)
```bash
1. Go to https://cohere.com/
2. Sign up
3. Get API key
4. Add to backend env: COHERE_API_KEY=your-key
```

---

## 📊 Cost Breakdown

### Railway Deployment (Recommended)
- **Backend**: ~$3/month (covered by $5 credit)
- **Database**: ~$1/month (covered by $5 credit)
- **Frontend (Vercel)**: $0
- **Total**: $0/month ✅

### Render Deployment
- **Backend**: $0 (free tier with 750 hours/month)
- **Database**: $0 (free tier)
- **Frontend (Vercel)**: $0
- **Total**: $0/month ✅

### DigitalOcean Deployment
- **App Platform**: ~$10/month (covered by $200 credit)
- **Total**: $0 for first ~20 months ✅

---

## 🐛 Troubleshooting

### Backend doesn't start
```bash
# Check logs in Railway/Render dashboard
# Common issues:
# 1. Missing environment variables
# 2. ML model not trained (check build logs)
# 3. Database connection failed
```

### Frontend can't connect to backend
```bash
# Check CORS settings in backend
# Verify VITE_API_BASE_URL is correct
# Check browser console for errors
```

### ML predictions fail
```bash
# Check if ML model was trained during build
# Look for: "Training ML model..." in build logs
# Manually train: cd ML/scripts && python train_model_realistic.py
```

### Database migrations fail
```bash
# Manually run migrations:
python Django/manage.py migrate
```

---

## 🔒 Security Checklist

- [ ] Set `DEBUG=False` in production
- [ ] Use strong `SECRET_KEY` (generate with `python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'`)
- [ ] Set correct `ALLOWED_HOSTS`
- [ ] Configure CORS correctly
- [ ] Use HTTPS (automatic with Railway/Vercel)
- [ ] Keep API keys secret (don't commit to GitHub)
- [ ] Enable PostgreSQL backups
- [ ] Set up monitoring/alerts

---

## 📚 Additional Resources

- **Django Deployment**: https://docs.djangoproject.com/en/4.2/howto/deployment/
- **Railway Docs**: https://docs.railway.app/
- **Vercel Docs**: https://vercel.com/docs
- **Render Docs**: https://render.com/docs
- **GitHub Student Pack**: https://education.github.com/pack

---

## 🆘 Need Help?

1. **Check logs** in your deployment platform dashboard
2. **Review environment variables** - most issues are config-related
3. **Test locally first** - ensure app works with `DEBUG=False`
4. **Check GitHub Issues** for similar problems
5. **Contact support** of your deployment platform

---

## 🎉 Success!

Once deployed, your app should be accessible at:
- **Frontend**: `https://your-app.vercel.app`
- **Backend API**: `https://your-app.railway.app/api/`
- **Admin Panel**: `https://your-app.railway.app/admin/`

**Next Steps:**
1. Share the frontend URL with users
2. Create test accounts for CPSU departments
3. Monitor usage and performance
4. Set up automated backups
5. Configure custom domain (optional)

---

**Built with ❤️ for CPSU Students**

*Need a custom domain? Use Namecheap (free .me domain with Student Pack) or GitHub Pages custom domain*
