# 🔒 Security Guide - CPSU Virtual Health Assistant

## ⚠️ URGENT: Current Security Issues

### 🚨 CRITICAL - API Keys Exposed in Git

Your API keys are currently exposed in the git repository. **Take action immediately:**

```bash
# 1. Rotate ALL API keys NOW
# Get new keys from:
# - Gemini: https://ai.google.dev/
# - OpenRouter: https://openrouter.ai/
# - Groq: https://console.groq.com/
# - Cohere: https://dashboard.cohere.ai/

# 2. Remove .env from git tracking
git rm --cached Django/.env

# 3. Verify .env is in .gitignore
cat .gitignore | grep ".env"

# 4. Update .env with NEW keys
cp Django/.env.example Django/.env
nano Django/.env  # Add your NEW keys

# 5. Commit the changes
git add .gitignore
git commit -m "security: remove .env from version control"
git push
```

---

## 🔐 Security Best Practices

### 1. Environment Variables

**Never commit these files:**
- `.env`
- `Django/.env`
- `Vue/.env`
- Any file containing credentials

**Always:**
- Use `.env.example` templates
- Store production secrets in secure vault (e.g., AWS Secrets Manager, HashiCorp Vault)
- Rotate keys regularly (every 90 days)

### 2. Django Secret Key

```bash
# Generate a new secret key
cd Django
python generate_secret_key.py

# Add to Django/.env
DJANGO_SECRET_KEY=your-new-generated-key

# NEVER use the default key in production
```

### 3. Database Security

```bash
# Use strong passwords (minimum 16 characters)
# Include: uppercase, lowercase, numbers, special characters

# Example strong password generation
openssl rand -base64 24

# Store in .env
DATABASE_URL=postgresql://user:STRONG_PASSWORD_HERE@localhost:5432/dbname
```

### 4. HTTPS/SSL Configuration

```python
# In Django/.env (production only)
DEBUG=False
SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
```

### 5. CORS Configuration

```python
# Django/.env
# ONLY allow your frontend domain
CORS_ALLOWED_ORIGINS=https://your-domain.com,https://www.your-domain.com

# NEVER use in production:
# CORS_ALLOW_ALL_ORIGINS=True
```

---

## 🛡️ API Security

### Rate Limiting

The Nginx configuration includes rate limiting:

```nginx
# 60 requests per minute for API
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=60r/m;

# 5 requests per minute for authentication
limit_req_zone $binary_remote_addr zone=auth_limit:10m rate=5r/m;
```

### Authentication

All endpoints require authentication except:
- `/api/health/` - Health check
- `/api/auth/register/` - User registration
- `/api/auth/login/` - User login

```python
# Token authentication required
Authorization: Token <user-token>
```

### Input Validation

All user inputs are validated and sanitized:
- Symptoms: Whitelist validation
- School ID: Format validation
- Email: Domain validation
- Passwords: Strength requirements

---

## 👤 User Access Control

### Role-Based Permissions

1. **Student** (`role='student'`)
   - View own records only
   - Submit symptoms
   - Chat with AI
   - View own medications

2. **Clinic Staff** (`role='staff'`)
   - View all student records
   - Access analytics dashboard
   - Manage medications
   - Respond to emergencies

3. **Admin** (`is_superuser=True`)
   - Full system access
   - User management
   - System configuration
   - Backend monitoring

### School ID Validation

```python
# Format: YYYY-NNNNN (e.g., 2024-00001)
SCHOOL_ID_REGEX = r'^\d{4}-\d{5}$'
```

---

## 📊 Data Privacy & GDPR Compliance

### Personal Data Handling

1. **Data Minimization**: Only collect necessary health data
2. **Consent Management**: Explicit consent required for data processing
3. **Right to Access**: Users can export their data
4. **Right to Erasure**: Users can request deletion
5. **Data Portability**: Export in JSON format

### Audit Logging

All sensitive operations are logged:

```python
AuditLog.objects.create(
    user=user,
    action='view_patient_record',
    resource_type='symptom_record',
    resource_id=record.id,
    ip_address=request.META.get('REMOTE_ADDR'),
    user_agent=request.META.get('HTTP_USER_AGENT')
)
```

### Data Encryption

**At Rest:**
- Database encryption (PostgreSQL TDE)
- Encrypted backups

**In Transit:**
- HTTPS/TLS 1.3
- Secure WebSocket connections (WSS)

---

## 🚨 Incident Response

### Security Incident Checklist

If you suspect a security breach:

1. **Immediate Actions**
   ```bash
   # Rotate all credentials
   # Lock affected accounts
   # Enable maintenance mode
   ```

2. **Investigation**
   - Check audit logs: `Django/logs/django.log`
   - Review access logs: `/var/log/nginx/access.log`
   - Check failed authentication attempts

3. **Containment**
   - Isolate affected systems
   - Block suspicious IP addresses
   - Revoke compromised tokens

4. **Recovery**
   - Restore from clean backup
   - Update all dependencies
   - Patch vulnerabilities

5. **Post-Incident**
   - Document incident
   - Update security measures
   - Train team

---

## 🔍 Security Monitoring

### Regular Checks

```bash
# Check for suspicious activity
tail -f Django/logs/django.log | grep "WARN\|ERROR"

# Monitor failed login attempts
grep "authentication failed" Django/logs/django.log

# Check for unusual API usage
tail -f /var/log/nginx/access.log | grep "/api/"
```

### Automated Security Scans

```bash
# Dependency vulnerability scan
pip install safety
safety check -r Django/requirements.txt

# Code security scan
pip install bandit
bandit -r Django/clinic/
```

---

## 📋 Security Checklist

### Pre-Deployment

- [ ] All API keys rotated
- [ ] `.env` removed from git
- [ ] Strong database password set
- [ ] Django SECRET_KEY generated
- [ ] DEBUG=False in production
- [ ] HTTPS/SSL configured
- [ ] CORS properly configured
- [ ] Rate limiting enabled
- [ ] Security headers configured
- [ ] Audit logging enabled

### Post-Deployment

- [ ] Health check accessible
- [ ] SSL certificate valid
- [ ] Rate limiting working
- [ ] Authentication working
- [ ] Logs being written
- [ ] Backups automated
- [ ] Monitoring active
- [ ] Security scan passed

### Regular Maintenance

- [ ] Update dependencies monthly
- [ ] Rotate keys quarterly
- [ ] Review audit logs weekly
- [ ] Test backups monthly
- [ ] Security scan weekly
- [ ] Update SSL annually

---

## 🔗 Security Resources

### Dependencies

Keep these updated regularly:

```bash
# Check for outdated packages
pip list --outdated

# Update specific package
pip install --upgrade django

# Update all (test first!)
pip install -U -r requirements.txt
```

### Known Vulnerabilities

Check CVE databases:
- Django: https://www.djangoproject.com/weblog/
- Python: https://www.python.org/news/security/
- Node.js: https://nodejs.org/en/security/

---

## 📞 Reporting Security Issues

**Do NOT create public GitHub issues for security vulnerabilities.**

Instead:
1. Email: security@cpsu.edu.ph
2. Include:
   - Detailed description
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

We aim to respond within 48 hours.

---

## ⚖️ Compliance

### Philippines Data Privacy Act (DPA)

This system complies with:
- RA 10173 (Data Privacy Act of 2012)
- NPC Circular 16-03 (Security of Personal Data)

### Health Information Privacy

Implements:
- Secure storage of health records
- Access control based on need-to-know
- Audit trails for all access
- Patient consent management

---

**Last Updated**: 2024
**Security Status**: ⚠️ Action Required - API Keys Need Rotation
