# Deployment Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                         CPSU Health Assistant - Azure Deployment                 │
└─────────────────────────────────────────────────────────────────────────────────┘

                                    GitHub Repository
                                ┌────────────────────────┐
                                │  virtualHealthAssistant │
                                │                        │
                                │  ├── Django/           │
                                │  ├── Vue/              │
                                │  ├── ML/               │
                                │  └── .github/workflows/│
                                └───────────┬────────────┘
                                            │
                            ┌───────────────┴───────────────┐
                            │   Push to main branch         │
                            │   triggers GitHub Actions     │
                            └───────────────┬───────────────┘
                                            │
                    ┌───────────────────────┴───────────────────────┐
                    │                                               │
                    ▼                                               ▼
    ┌───────────────────────────────┐               ┌───────────────────────────────┐
    │  Backend Workflow             │               │  Frontend Workflow            │
    │  azure-django-backend.yml     │               │  azure-vue-frontend.yml       │
    │                               │               │                               │
    │  1. Setup Python 3.11         │               │  1. Setup Node.js 18          │
    │  2. Install dependencies      │               │  2. Install npm packages      │
    │  3. Train ML model            │               │  3. TypeScript type check     │
    │  4. Run Django checks         │               │  4. Build Vue app             │
    │  5. Package Django + ML       │               │  5. Deploy to Azure SWA       │
    │  6. Deploy to Azure Web App   │               │                               │
    │                               │               │                               │
    └───────────────┬───────────────┘               └───────────────┬───────────────┘
                    │                                               │
                    ▼                                               ▼
    ┌───────────────────────────────┐               ┌───────────────────────────────┐
    │  Azure Web App (Linux)        │               │  Azure Static Web Apps        │
    │  cpsu-health-assistant-backend│               │  cpsu-health-assistant-frontend│
    │                               │               │                               │
    │  Python 3.11 + Gunicorn       │               │  Static files (HTML/CSS/JS)   │
    │  Django REST API              │◄──────────────┤  Vue.js SPA                   │
    │  ML Prediction Service        │      HTTPS    │  TailwindCSS                  │
    │  LLM Validation (optional)    │    /api/*     │  Vue Router                   │
    │                               │               │                               │
    │  Environment Variables:       │               │  Environment Variables:       │
    │  - DATABASE_URL               │               │  - VITE_API_BASE_URL         │
    │  - DJANGO_SECRET_KEY          │               │  - VITE_APP_NAME             │
    │  - DEBUG=False                │               │  - VITE_APP_VERSION          │
    │  - DJANGO_ALLOWED_HOSTS       │               │                               │
    │  - CORS_ALLOWED_ORIGINS       │               │                               │
    │                               │               │                               │
    └───────────────┬───────────────┘               └───────────────────────────────┘
                    │
                    │ PostgreSQL Connection
                    │ (pooler: port 6543)
                    │
                    ▼
    ┌───────────────────────────────────────────────────────────────────────┐
    │                    Supabase (Managed PostgreSQL)                      │
    │                                                                        │
    │  Database: postgres                                                   │
    │  Region: US East (or your chosen region)                             │
    │                                                                        │
    │  Tables:                                                              │
    │  ├── clinic_customuser          (User accounts)                      │
    │  ├── clinic_symptomrecord       (Symptom submissions)                │
    │  ├── clinic_chatsession         (Chat history)                       │
    │  ├── clinic_auditlog            (System logs)                        │
    │  └── authtoken_token            (API tokens)                         │
    │                                                                        │
    │  Features:                                                            │
    │  ✅ Connection pooling (PgBouncer)                                    │
    │  ✅ Automated backups                                                 │
    │  ✅ SSL/TLS encryption                                                │
    │  ✅ Row Level Security (optional)                                     │
    │                                                                        │
    └────────────────────────────────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────────────────────────────────┐
│                              Request Flow Example                                │
└─────────────────────────────────────────────────────────────────────────────────┘

User Request:
    1. User visits: https://cpsu-health-assistant-frontend.azurestaticapps.net
    2. Azure SWA serves Vue.js SPA (index.html, app.js, styles.css)
    3. User submits symptoms via symptom checker form

API Call:
    4. Vue app calls: POST /api/symptoms/submit/ 
       → https://cpsu-health-assistant-backend.azurewebsites.net/api/symptoms/submit/
    5. Azure Web App receives request via Gunicorn
    6. Django authenticates user (Token authentication)
    7. Django validates and processes symptoms

ML Prediction:
    8. ML Service loads trained model (disease_predictor_v2.pkl)
    9. Model predicts disease based on 132 symptom features
    10. LLM Service validates prediction (optional, Gemini/Groq/Cohere)
    11. System combines ML + LLM results (90-98% accuracy)

Database Operations:
    12. Django creates SymptomRecord in Supabase PostgreSQL
    13. Record includes: user, symptoms, predictions, timestamp
    14. Supabase stores data with encryption

Response:
    15. Django returns JSON response with:
        - Predicted disease
        - Confidence score
        - Precautions (4 recommendations)
        - Description
        - Severity level
    16. Vue app displays results to user
    17. User can view in health history


┌─────────────────────────────────────────────────────────────────────────────────┐
│                              CI/CD Pipeline                                      │
└─────────────────────────────────────────────────────────────────────────────────┘

Every push to 'main' branch:

1. ci-cd.yml (Quality Checks)
   ├── Backend Tests (Django + PostgreSQL)
   ├── Frontend Tests (Vue + TypeScript)
   ├── Code Linting (flake8, black)
   └── Security Scan (Trivy)
         │
         ├─ PASS ──┐
         │         │
         └─ FAIL ──┼─► Block Deployment
                   │
2. azure-django-backend.yml (if Django/ or ML/ changed)
   ├── Train ML Model (~2-3 minutes)
   ├── Package Django + ML
   └── Deploy to Azure Web App (~3-5 minutes)
         │
3. azure-vue-frontend.yml (if Vue/ changed)
   ├── Build Vue Production Bundle
   └── Deploy to Azure Static Web Apps (~2-3 minutes)
         │
         ▼
   ✅ Deployment Complete!


┌─────────────────────────────────────────────────────────────────────────────────┐
│                            Cost Breakdown (Monthly)                              │
└─────────────────────────────────────────────────────────────────────────────────┘

Azure Web App (Backend):
  • B1 Basic Plan: $13/month
    - 1.75 GB RAM
    - 100 GB storage
    - Custom domain + SSL
    - Auto-scaling

Azure Static Web Apps (Frontend):
  • Free Plan: $0/month
    - 100 GB bandwidth
    - Custom domain + SSL
    - Global CDN
    - Automatic HTTPS

Supabase (Database):
  • Free Plan: $0/month
    - 500 MB database
    - Unlimited API requests
    - Auto-backup (7 days)
    - SSL connections
    - Connection pooling

LLM APIs (Optional):
  • All FREE tier: $0/month
    - Gemini 2.5 Flash
    - Groq (Grok 2)
    - Cohere

GitHub Actions:
  • 2,000 minutes/month: $0
    (Public repository)

───────────────────────────────
TOTAL: ~$13/month
───────────────────────────────

Upgrade options:
• B2 Basic: $26/month (more RAM/storage)
• Supabase Pro: $25/month (8GB database)


┌─────────────────────────────────────────────────────────────────────────────────┐
│                              Security Features                                   │
└─────────────────────────────────────────────────────────────────────────────────┘

Backend Security:
✅ HTTPS only (enforced)
✅ CORS protection (whitelisted origins)
✅ CSRF protection
✅ SQL injection prevention (ORM)
✅ XSS protection (Django middleware)
✅ Password hashing (Argon2)
✅ Token authentication (DRF)
✅ Rate limiting
✅ Audit logging

Database Security:
✅ SSL/TLS encryption in transit
✅ Encrypted at rest
✅ Connection pooling (PgBouncer)
✅ Automated backups
✅ IP whitelisting (optional)
✅ Row Level Security (optional)

Frontend Security:
✅ Static file hosting (no server-side code)
✅ CSP headers (Content Security Policy)
✅ SRI hashes (Subresource Integrity)
✅ HTTPS only
✅ No sensitive data in code

Secrets Management:
✅ GitHub Secrets (encrypted)
✅ Azure Key Vault ready
✅ Environment variables (not in code)
✅ No secrets in git history


┌─────────────────────────────────────────────────────────────────────────────────┐
│                              Monitoring & Logs                                   │
└─────────────────────────────────────────────────────────────────────────────────┘

Backend Monitoring:
• Azure Application Insights
  - Request metrics
  - Error tracking
  - Performance monitoring
  - Custom events

• Azure Log Stream
  - Real-time logs
  - stdout/stderr
  - Gunicorn logs

Frontend Monitoring:
• Azure SWA Analytics
  - Page views
  - User sessions
  - Geographic data

Database Monitoring:
• Supabase Dashboard
  - Query performance
  - Connection pool
  - Table statistics
  - Slow query logs

GitHub Actions:
• Workflow run history
• Deployment logs
• Test results
• Security scan reports


┌─────────────────────────────────────────────────────────────────────────────────┐
│                              URLs & Endpoints                                    │
└─────────────────────────────────────────────────────────────────────────────────┘

Production URLs:
• Frontend:     https://cpsu-health-assistant-frontend.azurestaticapps.net
• Backend API:  https://cpsu-health-assistant-backend.azurewebsites.net/api
• Admin Panel:  https://cpsu-health-assistant-backend.azurewebsites.net/admin

Key API Endpoints:
POST /api/auth/register/              Register new user
POST /api/auth/login/                 Login (get token)
POST /api/symptoms/submit/            Submit symptoms → get prediction
GET  /api/symptoms/available/         List all 132 symptoms
POST /api/chat/message/               Chat with AI
GET  /api/staff/dashboard/            Staff dashboard (staff only)

Health Checks:
GET  /api/health/                     System health status
GET  /admin/                          Django admin (staff only)

Documentation:
https://github.com/souchan25/virtualHealthAssistant
├── README.md                         Project overview
├── QUICKSTART_AZURE.md               5-minute setup
├── AZURE_DEPLOYMENT_GUIDE.md         Complete guide
└── GITHUB_SECRETS_GUIDE.md           Secrets setup
```

---

**Generated**: February 2026  
**Last Updated**: February 2026  
**Architecture Version**: 1.0
