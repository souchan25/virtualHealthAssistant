# ⚡ Quick Deployment Guide

## 🚨 Before Deploying - Critical Steps

### 1. **Rotate ALL API Keys** (5 minutes)
Your keys are exposed in git! Get new ones:
- Gemini: https://ai.google.dev/
- OpenRouter: https://openrouter.ai/
- Groq: https://console.groq.com/
- Cohere: https://dashboard.cohere.ai/

### 2. **Remove .env from Git** (2 minutes)
```bash
git rm --cached Django/.env
git add .gitignore
git commit -m "security: remove .env from version control"
```

### 3. **Generate Secret Key** (1 minute)
```bash
cd Django
python generate_secret_key.py
# Copy output to Django/.env
```

---

## 🐳 Docker Deployment (Fastest)

```bash
# 1. Configure environment
cp Django/.env.example Django/.env
nano Django/.env  # Add your NEW API keys

# 2. Set database password
export DB_PASSWORD="YourStrongPassword123!"

# 3. Deploy
docker-compose up -d

# 4. Setup database
docker-compose exec backend python manage.py migrate
docker-compose exec backend python manage.py createsuperuser

# 5. Test
curl http://localhost/health
```

**Done!** Access at http://localhost

---

## 🖥️ Manual Deployment (Traditional)

```bash
# 1. Setup
bash setup.sh  # Or setup.bat on Windows

# 2. Configure .env files
# Edit Django/.env with your values

# 3. Create superuser
cd Django
python manage.py createsuperuser

# 4. Train ML model (first time)
cd ../ML/scripts
python train_model_realistic.py

# 5. Run server
cd ../../Django
python manage.py runserver 0.0.0.0:8000
```

---

## ✅ Post-Deployment Checklist

- [ ] Health check works: `curl http://your-ip/api/health/`
- [ ] Can create user account
- [ ] Can login
- [ ] ML predictions work
- [ ] LLM chat responds
- [ ] All API keys are NEW (not the exposed ones)

---

## 📊 URLs After Deployment

- **API**: http://your-ip:8000/api/
- **Admin**: http://your-ip:8000/admin/
- **Health Check**: http://your-ip:8000/api/health/
- **Frontend**: http://your-ip:5173/ (if Vue is running)

---

## 🔧 Troubleshooting

### Health check fails
```bash
# Check if service is running
docker-compose ps  # Docker
# OR
ps aux | grep gunicorn  # Manual

# Check logs
docker-compose logs backend  # Docker
# OR
tail -f Django/logs/django.log  # Manual
```

### Can't connect from phone
```bash
# 1. Check IP address
ipconfig  # Windows
ifconfig  # Linux/Mac

# 2. Update Vue/.env
VITE_API_BASE_URL=http://YOUR_IP:8000/api

# 3. Run with network access
python manage.py runserver 0.0.0.0:8000  # Backend
npm run dev -- --host  # Frontend
```

### Database errors
```bash
# Reset database
rm Django/db.sqlite3
python manage.py migrate
python manage.py createsuperuser
```

---

## 📱 Network Configuration

Update these files with your IP (from `ipconfig`):

**Django/.env:**
```env
DJANGO_ALLOWED_HOSTS=YOUR_IP,localhost,127.0.0.1
CORS_ALLOWED_ORIGINS=http://YOUR_IP:5173,http://localhost:5173
```

**Vue/.env:**
```env
VITE_API_BASE_URL=http://YOUR_IP:8000/api
VITE_RASA_URL=http://YOUR_IP:5005
```

---

## 🆘 Emergency Commands

```bash
# Stop everything
docker-compose down  # Docker
# OR
Ctrl+C  # Manual

# View logs
docker-compose logs -f backend  # Docker
tail -f Django/logs/django.log  # Manual

# Restart
docker-compose restart  # Docker
# OR manually restart the process

# Reset everything
docker-compose down -v  # WARNING: Deletes data!
rm -rf Django/db.sqlite3
```

---

## 📖 Full Documentation

- **Complete Guide**: [DEPLOYMENT.md](DEPLOYMENT.md)
- **Security**: [SECURITY.md](SECURITY.md)
- **Network Setup**: [docs/guides/NETWORK_CHANGE_GUIDE.md](docs/guides/NETWORK_CHANGE_GUIDE.md)

---

**Need Help?** Check logs first, then review the full DEPLOYMENT.md guide.
