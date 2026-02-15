# 🚀 CPSU Virtual Health Assistant - Deployment Guide

## 📋 Pre-Deployment Checklist

### ⚠️ CRITICAL SECURITY STEPS (Do These First!)

- [ ] **1. Rotate ALL API Keys** (current keys are exposed in git history)
  - Get new Gemini API key: https://ai.google.dev/
  - Get new OpenRouter API key: https://openrouter.ai/
  - Get new Groq API key: https://console.groq.com/
  - Get new Cohere API key: https://dashboard.cohere.ai/

- [ ] **2. Generate New Django Secret Key**
  ```bash
  cd Django
  python generate_secret_key.py
  ```
  Copy the output to your `.env` file

- [ ] **3. Remove .env from Git History**
  ```bash
  # Remove .env from current commit
  git rm --cached Django/.env
  
  # Verify .env is in .gitignore (already done)
  cat .gitignore | grep ".env"
  
  # Commit the removal
  git add .gitignore
  git commit -m "security: remove .env from version control"
  ```

- [ ] **4. Create Production .env Files**
  ```bash
  # Copy templates
  cp .env.example .env
  cp Django/.env.example Django/.env
  cp Vue/.env.example Vue/.env
  
  # Edit each .env file with your actual values
  ```

---

## 🐳 Docker Deployment (Recommended)

### Prerequisites
- Docker & Docker Compose installed
- PostgreSQL (handled by Docker)

### Setup Steps

1. **Configure Environment Variables**
   ```bash
   # Edit Django/.env with your production values
   nano Django/.env
   ```

2. **Set Database Password**
   ```bash
   # Create a strong database password
   export DB_PASSWORD="your-strong-password-here"
   ```

3. **Build and Start Services**
   ```bash
   # Build containers
   docker-compose build
   
   # Start all services
   docker-compose up -d
   
   # Check status
   docker-compose ps
   ```

4. **Run Database Migrations**
   ```bash
   docker-compose exec backend python manage.py migrate
   ```

5. **Create Superuser**
   ```bash
   docker-compose exec backend python manage.py createsuperuser
   ```

6. **Verify Health**
   ```bash
   curl http://localhost/health
   ```

### Docker Services

- **Backend**: Django API on port 8000
- **Database**: PostgreSQL on port 5432
- **Nginx**: Reverse proxy on port 80/443
- **Volumes**: Persistent storage for database, static files, media, and logs

### Docker Commands

```bash
# View logs
docker-compose logs -f backend

# Restart services
docker-compose restart

# Stop all services
docker-compose down

# Stop and remove volumes (WARNING: deletes data)
docker-compose down -v

# Update after code changes
docker-compose build backend
docker-compose up -d backend
```

---

## 🖥️ Manual Deployment (Without Docker)

### 1. System Requirements

- Python 3.11+
- PostgreSQL 15+ (or SQLite for dev)
- Node.js 18+ (for Vue frontend)
- Nginx (for production)

### 2. Backend Setup

```bash
# Clone repository
git clone <your-repo-url>
cd VirtualAssistant

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
cd Django
pip install -r requirements.txt

# Configure environment
cp .env.example .env
nano .env  # Edit with your values

# Generate secret key
python generate_secret_key.py

# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Collect static files
python manage.py collectstatic --noinput

# Train ML model (first time only)
cd ../ML/scripts
python train_model_realistic.py
```

### 3. Frontend Setup

```bash
cd Vue

# Install dependencies
npm install

# Configure environment
cp .env.example .env
nano .env  # Update API URLs

# Build for production
npm run build

# Output will be in Vue/dist/
```

### 4. Database Setup (PostgreSQL)

```bash
# Install PostgreSQL
sudo apt-get install postgresql postgresql-contrib

# Create database and user
sudo -u postgres psql
```

```sql
CREATE DATABASE cpsu_health;
CREATE USER cpsu_admin WITH PASSWORD 'your-strong-password';
ALTER ROLE cpsu_admin SET client_encoding TO 'utf8';
ALTER ROLE cpsu_admin SET default_transaction_isolation TO 'read committed';
ALTER ROLE cpsu_admin SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE cpsu_health TO cpsu_admin;
\q
```

```bash
# Update Django/.env with database URL
DATABASE_URL=postgresql://cpsu_admin:your-strong-password@localhost:5432/cpsu_health
```

### 5. Nginx Configuration

```nginx
# /etc/nginx/sites-available/cpsu-health

server {
    listen 80;
    server_name your-domain.com;

    client_max_body_size 10M;

    # Frontend (Vue)
    root /path/to/VirtualAssistant/Vue/dist;
    index index.html;

    # Static files
    location /static/ {
        alias /path/to/VirtualAssistant/Django/staticfiles/;
        expires 30d;
    }

    # Media files
    location /media/ {
        alias /path/to/VirtualAssistant/Django/media/;
        expires 7d;
    }

    # API requests to Django
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Admin panel
    location /admin/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # Vue router (SPA)
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/cpsu-health /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 6. Systemd Service (Django)

```bash
# Create service file
sudo nano /etc/systemd/system/cpsu-health.service
```

```ini
[Unit]
Description=CPSU Health Assistant Django Backend
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/path/to/VirtualAssistant/Django
Environment="PATH=/path/to/VirtualAssistant/venv/bin"
ExecStart=/path/to/VirtualAssistant/venv/bin/gunicorn \
    --workers 3 \
    --bind 127.0.0.1:8000 \
    --timeout 60 \
    --access-logfile /var/log/cpsu-health/access.log \
    --error-logfile /var/log/cpsu-health/error.log \
    health_assistant.wsgi:application

[Install]
WantedBy=multi-user.target
```

```bash
# Create log directory
sudo mkdir -p /var/log/cpsu-health
sudo chown www-data:www-data /var/log/cpsu-health

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable cpsu-health
sudo systemctl start cpsu-health
sudo systemctl status cpsu-health
```

---

## 🔒 SSL/HTTPS Setup (Let's Encrypt)

```bash
# Install Certbot
sudo apt-get install certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d your-domain.com

# Auto-renewal is set up automatically
sudo certbot renew --dry-run
```

---

## 🧪 Testing Deployment

### 1. Health Check
```bash
curl http://your-domain.com/api/health/
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T00:00:00Z",
  "version": "1.0.0",
  "components": {
    "database": "healthy",
    "ml_model": "healthy",
    "llm_providers": ["gemini", "groq"],
    "rasa": "healthy"
  }
}
```

### 2. Test ML Prediction
```bash
curl -X POST http://your-domain.com/api/symptoms/submit/ \
  -H "Authorization: Token your-auth-token" \
  -H "Content-Type: application/json" \
  -d '{
    "symptoms": ["fever", "cough", "fatigue"],
    "generate_insights": true
  }'
```

### 3. Test Authentication
```bash
# Register user
curl -X POST http://your-domain.com/api/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "school_id": "2024-00001",
    "email": "test@student.cpsu.edu.ph",
    "password": "SecurePass123!",
    "first_name": "Test",
    "last_name": "User",
    "role": "student"
  }'
```

---

## 📊 Monitoring & Maintenance

### Log Files

```bash
# Django logs
tail -f Django/logs/django.log

# Nginx access logs
tail -f /var/log/nginx/access.log

# Nginx error logs
tail -f /var/log/nginx/error.log

# Systemd service logs
sudo journalctl -u cpsu-health -f
```

### Database Backup

```bash
# Manual backup
docker-compose exec db pg_dump -U cpsu_admin cpsu_health > backup_$(date +%Y%m%d).sql

# Or without Docker
pg_dump -U cpsu_admin cpsu_health > backup_$(date +%Y%m%d).sql

# Restore
psql -U cpsu_admin cpsu_health < backup_20240101.sql
```

### Performance Monitoring

```bash
# Check Django response time
curl -w "@curl-format.txt" -o /dev/null -s http://your-domain.com/api/health/

# curl-format.txt:
# time_total: %{time_total}s
```

---

## 🔄 Update & Rollback

### Update Application

```bash
# With Docker
git pull
docker-compose build backend
docker-compose up -d backend
docker-compose exec backend python manage.py migrate

# Without Docker
git pull
source venv/bin/activate
pip install -r Django/requirements.txt
python manage.py migrate
python manage.py collectstatic --noinput
sudo systemctl restart cpsu-health
```

### Rollback

```bash
# With Docker
git checkout <previous-commit>
docker-compose down
docker-compose up -d

# Without Docker
git checkout <previous-commit>
sudo systemctl restart cpsu-health
```

---

## ⚡ Performance Tuning

### Django Settings for Production

```python
# In Django/.env
DEBUG=False
SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
```

### Gunicorn Workers

```bash
# Calculate optimal workers: (2 * CPU_CORES) + 1
# For 2 CPUs: 5 workers
--workers 5
```

### Database Connection Pooling

```python
# Django settings.py
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'CONN_MAX_AGE': 600,  # 10 minutes
    }
}
```

---

## 🆘 Troubleshooting

### Service Won't Start

```bash
# Check service status
sudo systemctl status cpsu-health

# Check logs
sudo journalctl -u cpsu-health -n 50

# Check Django errors
tail -f Django/logs/django.log
```

### Database Connection Issues

```bash
# Test PostgreSQL connection
psql -U cpsu_admin -h localhost cpsu_health

# Check if PostgreSQL is running
sudo systemctl status postgresql
```

### 502 Bad Gateway

```bash
# Check if gunicorn is running
ps aux | grep gunicorn

# Check nginx error logs
tail -f /var/log/nginx/error.log

# Restart services
sudo systemctl restart cpsu-health
sudo systemctl restart nginx
```

### Static Files Not Loading

```bash
# Recollect static files
python manage.py collectstatic --noinput --clear

# Check nginx configuration
sudo nginx -t

# Verify permissions
ls -la Django/staticfiles/
```

### CSS Post-Processing Errors (collectstatic fails)

If you see errors like `Post-processing 'vendor/bootswatch/yeti/bootstrap.min.css' failed!`:

**Solution**: The project uses `CompressedStaticFilesStorage` instead of `CompressedManifestStaticFilesStorage` to avoid strict manifest checking that can fail with third-party CSS files.

**Already Fixed**: This is already configured in `Django/health_assistant/settings.py`:
```python
STATICFILES_STORAGE = 'whitenoise.storage.CompressedStaticFilesStorage'
```

If you still encounter issues:
```bash
# 1. Clear existing static files
rm -rf Django/staticfiles/*

# 2. Recollect without compression (for debugging)
cd Django
WHITENOISE_AUTOREFRESH=1 python manage.py collectstatic --noinput

# 3. Check for missing files in error message
# and remove problematic third-party packages if necessary
```

---

## 📞 Support

For deployment issues:
1. Check logs first
2. Review this guide
3. Check GitHub issues
4. Contact CPSU IT team

---

## 📝 Post-Deployment Checklist

- [ ] Health check endpoint returns "healthy"
- [ ] Can create and authenticate users
- [ ] ML predictions work correctly
- [ ] LLM insights generate properly
- [ ] Static files load correctly
- [ ] SSL certificate is valid
- [ ] Database backups are automated
- [ ] Monitoring is set up
- [ ] Logs are rotating properly
- [ ] Rate limiting is active

---

**Last Updated**: 2024
**Deployment Status**: ✅ Production Ready
