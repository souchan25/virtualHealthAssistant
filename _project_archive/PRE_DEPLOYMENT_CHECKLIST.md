# ✅ Pre-Deployment Checklist - CPSU Virtual Health Assistant

## 🚨 CRITICAL SECURITY ACTIONS (Must Do First!)

### ❌ Current Issues That MUST Be Fixed:

1. **API Keys Exposed in Git Repository**
   - Status: ❌ **CRITICAL - Not Fixed**
   - Action Required: Rotate all keys immediately
   - Time: ~10 minutes
   - Instructions: See [SECURITY.md](SECURITY.md#-urgent-current-security-issues)

2. **Django Secret Key Hardcoded**
   - Status: ✅ **FIXED** - Now uses environment variable
   - Action Required: Generate new key and add to `.env`
   - Time: ~2 minutes
   - Instructions: Run `python Django/generate_secret_key.py`

3. **DEBUG Mode**
   - Status: ✅ **FIXED** - Now environment-based
   - Action Required: Set `DEBUG=False` in production `.env`

---

## 📋 Step-by-Step Deployment Checklist

### Phase 1: Security Setup (15 minutes)

- [ ] **1.1** Rotate Gemini API Key
  - Get new key: https://ai.google.dev/
  - Add to `Django/.env`: `GEMINI_API_KEY=your-new-key`

- [ ] **1.2** Rotate OpenRouter API Key
  - Get new key: https://openrouter.ai/
  - Add to `Django/.env`: `OPENROUTER_API_KEY=your-new-key`

- [ ] **1.3** Rotate Groq API Key
  - Get new key: https://console.groq.com/
  - Add to `Django/.env`: `GROQ_API_KEY=your-new-key`

- [ ] **1.4** Rotate Cohere API Key
  - Get new key: https://dashboard.cohere.ai/
  - Add to `Django/.env`: `COHERE_API_KEY=your-new-key`

- [ ] **1.5** Generate Django Secret Key
  ```bash
  cd Django
  python generate_secret_key.py
  # Copy output to Django/.env
  ```

- [ ] **1.6** Remove .env from Git
  ```bash
  git rm --cached Django/.env
  git add .gitignore
  git commit -m "security: remove .env from version control"
  ```

### Phase 2: Environment Configuration (10 minutes)

- [ ] **2.1** Create `.env` files from templates
  ```bash
  cp Django/.env.example Django/.env
  cp Vue/.env.example Vue/.env
  ```

- [ ] **2.2** Update `Django/.env` with:
  - [ ] `DJANGO_SECRET_KEY=` (from step 1.5)
  - [ ] `DEBUG=False` (for production)
  - [ ] `DJANGO_ALLOWED_HOSTS=` (your domain/IP)
  - [ ] `CORS_ALLOWED_ORIGINS=` (your frontend URL)
  - [ ] All API keys (from steps 1.1-1.4)

- [ ] **2.3** Update `Vue/.env` with:
  - [ ] `VITE_API_BASE_URL=` (your backend URL)
  - [ ] `VITE_RASA_URL=` (your Rasa URL if using)

- [ ] **2.4** For production, set security flags in `Django/.env`:
  ```env
  SECURE_SSL_REDIRECT=True
  SESSION_COOKIE_SECURE=True
  CSRF_COOKIE_SECURE=True
  ```

### Phase 3: Database Setup (5 minutes)

Choose one:

**Option A: SQLite (Development/Testing)**
- [ ] **3.A.1** Default - no extra setup needed
- [ ] **3.A.2** Run migrations (done in Phase 4)

**Option B: PostgreSQL (Production Recommended)**
- [ ] **3.B.1** Install PostgreSQL
- [ ] **3.B.2** Create database and user
  ```sql
  CREATE DATABASE cpsu_health;
  CREATE USER cpsu_admin WITH PASSWORD 'strong-password';
  GRANT ALL PRIVILEGES ON DATABASE cpsu_health TO cpsu_admin;
  ```
- [ ] **3.B.3** Add to `Django/.env`:
  ```env
  DATABASE_URL=postgresql://cpsu_admin:strong-password@localhost:5432/cpsu_health
  ```

### Phase 4: Application Setup (10 minutes)

- [ ] **4.1** Run setup script
  ```bash
  # Windows
  setup.bat
  
  # Linux/Mac
  bash setup.sh
  ```

- [ ] **4.2** Create superuser
  ```bash
  cd Django
  python manage.py createsuperuser
  ```

- [ ] **4.3** Train ML model (first time only)
  ```bash
  cd ML/scripts
  python train_model_realistic.py
  ```

- [ ] **4.4** Test health check
  ```bash
  cd Django
  python manage.py runserver
  # In another terminal:
  curl http://localhost:8000/api/health/
  ```

### Phase 5: Docker Setup (Alternative to Phase 4)

If using Docker:

- [ ] **5.1** Set database password
  ```bash
  export DB_PASSWORD="your-strong-password"
  ```

- [ ] **5.2** Build and start containers
  ```bash
  docker-compose build
  docker-compose up -d
  ```

- [ ] **5.3** Run migrations
  ```bash
  docker-compose exec backend python manage.py migrate
  ```

- [ ] **5.4** Create superuser
  ```bash
  docker-compose exec backend python manage.py createsuperuser
  ```

- [ ] **5.5** Test health check
  ```bash
  curl http://localhost/health
  ```

### Phase 6: SSL/HTTPS Setup (Production Only)

- [ ] **6.1** Install Certbot
  ```bash
  sudo apt-get install certbot python3-certbot-nginx
  ```

- [ ] **6.2** Get SSL certificate
  ```bash
  sudo certbot --nginx -d your-domain.com
  ```

- [ ] **6.3** Test auto-renewal
  ```bash
  sudo certbot renew --dry-run
  ```

### Phase 7: Testing (15 minutes)

- [ ] **7.1** Health Check
  ```bash
  curl http://your-domain.com/api/health/
  ```
  Expected: `{"status": "healthy"}`

- [ ] **7.2** Register Test User
  ```bash
  curl -X POST http://your-domain.com/api/auth/register/ \
    -H "Content-Type: application/json" \
    -d '{
      "school_id": "2024-00001",
      "email": "test@student.cpsu.edu.ph",
      "password": "TestPass123!",
      "first_name": "Test",
      "last_name": "User",
      "role": "student"
    }'
  ```

- [ ] **7.3** Login
  ```bash
  curl -X POST http://your-domain.com/api/auth/login/ \
    -H "Content-Type: application/json" \
    -d '{
      "school_id": "2024-00001",
      "password": "TestPass123!"
    }'
  ```
  Expected: Receive authentication token

- [ ] **7.4** Test ML Prediction
  ```bash
  curl -X POST http://your-domain.com/api/symptoms/submit/ \
    -H "Authorization: Token YOUR_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "symptoms": ["fever", "cough", "fatigue"],
      "generate_insights": true
    }'
  ```
  Expected: Receive disease prediction and insights

- [ ] **7.5** Test Admin Panel
  - Visit: http://your-domain.com/admin/
  - Login with superuser credentials
  - Verify: Can see users, records, etc.

- [ ] **7.6** Test Frontend (if deployed)
  - Visit: http://your-frontend-domain.com
  - Register new account
  - Submit symptoms
  - Check chat functionality

### Phase 8: Monitoring Setup (10 minutes)

- [ ] **8.1** Verify logs are being written
  ```bash
  tail -f Django/logs/django.log
  ```

- [ ] **8.2** Set up log rotation
  ```bash
  # Logs are already configured with RotatingFileHandler
  # Max 10MB per file, 5 backups
  ```

- [ ] **8.3** Test error logging
  ```bash
  # Trigger an error and check logs
  curl http://your-domain.com/api/nonexistent/
  tail -f Django/logs/django.log
  ```

- [ ] **8.4** Set up monitoring (optional)
  - [ ] Configure health check monitoring
  - [ ] Set up uptime monitoring (e.g., UptimeRobot)
  - [ ] Configure error alerting

### Phase 9: Backup Configuration (5 minutes)

- [ ] **9.1** Create backup script
  ```bash
  # See DEPLOYMENT.md for backup scripts
  ```

- [ ] **9.2** Test backup
  ```bash
  # Docker
  docker-compose exec db pg_dump -U cpsu_admin cpsu_health > test_backup.sql
  
  # Manual PostgreSQL
  pg_dump -U cpsu_admin cpsu_health > test_backup.sql
  ```

- [ ] **9.3** Test restore
  ```bash
  # Create test database
  createdb test_restore
  psql -U cpsu_admin test_restore < test_backup.sql
  dropdb test_restore
  ```

- [ ] **9.4** Schedule automated backups
  ```bash
  # Add to crontab: daily backup at 2 AM
  0 2 * * * /path/to/backup_script.sh
  ```

---

## 🎯 Final Verification

### Security Checklist
- [ ] All API keys are NEW (not the exposed ones)
- [ ] `.env` files are NOT in git
- [ ] `DEBUG=False` in production
- [ ] HTTPS is enabled (production)
- [ ] Security headers are configured
- [ ] Rate limiting is active
- [ ] Strong database password set

### Functionality Checklist
- [ ] Health check returns "healthy"
- [ ] Can register new users
- [ ] Can login
- [ ] Can submit symptoms
- [ ] ML predictions work
- [ ] LLM insights generate
- [ ] Admin panel accessible
- [ ] Frontend connects to backend

### Performance Checklist
- [ ] Response time < 500ms
- [ ] Static files load correctly
- [ ] Database queries are optimized
- [ ] Logs are rotating properly
- [ ] No memory leaks

### Documentation Checklist
- [ ] Read [DEPLOYMENT.md](DEPLOYMENT.md)
- [ ] Read [SECURITY.md](SECURITY.md)
- [ ] Read [QUICK_DEPLOY.md](QUICK_DEPLOY.md)
- [ ] Bookmark URLs and credentials securely

---

## 📊 Deployment Status

**Overall Progress:** ☐☐☐☐☐☐☐☐☐☐ 0/10 phases complete

Mark each phase as complete by changing `- [ ]` to `- [x]`

---

## 🆘 If Something Goes Wrong

### Quick Fixes

**Can't connect:**
- Check firewall settings
- Verify ALLOWED_HOSTS includes your IP/domain
- Check CORS settings

**Database errors:**
- Verify DATABASE_URL is correct
- Check PostgreSQL is running
- Try migrations again

**API keys not working:**
- Verify keys are in Django/.env
- Check keys are valid (not expired)
- Restart Django server

**Static files not loading:**
- Run: `python manage.py collectstatic`
- Check nginx configuration
- Verify file permissions

### Get Help

1. Check logs: `Django/logs/django.log`
2. Review [DEPLOYMENT.md](DEPLOYMENT.md) troubleshooting section
3. Check GitHub issues
4. Contact CPSU IT support

---

## 📞 Emergency Rollback

If deployment fails and you need to rollback:

```bash
# Docker
docker-compose down
git checkout previous-working-commit
docker-compose up -d

# Manual
git checkout previous-working-commit
sudo systemctl restart cpsu-health
```

---

## 🎉 Post-Deployment

Once everything is working:

- [ ] Document any custom configurations
- [ ] Share URLs with team
- [ ] Train users on the system
- [ ] Set up regular maintenance schedule
- [ ] Celebrate! 🎊

---

**Last Updated**: 2024
**Estimated Total Time**: 1-2 hours (first deployment)
