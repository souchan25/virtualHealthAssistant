# CPSU Virtual Health Assistant 🏥

A full-stack health assistant application with AI-powered disease prediction, chatbot interface, and comprehensive health management system for Central Philippine State University.

[![Deploy Django Backend](https://github.com/souchan25/virtualHealthAssistant/actions/workflows/azure-django-backend.yml/badge.svg)](https://github.com/souchan25/virtualHealthAssistant/actions/workflows/azure-django-backend.yml)
[![Deploy Vue Frontend](https://github.com/souchan25/virtualHealthAssistant/actions/workflows/azure-vue-frontend.yml/badge.svg)](https://github.com/souchan25/virtualHealthAssistant/actions/workflows/azure-vue-frontend.yml)
[![CI/CD](https://github.com/souchan25/virtualHealthAssistant/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/souchan25/virtualHealthAssistant/actions/workflows/ci-cd.yml)

## 🎯 Features

### 🔬 AI-Powered Health Features
- **Disease Prediction Engine**: Hybrid ML+LLM system (85-98% accuracy)
- **Symptom Checker**: Interactive symptom analysis with 132+ symptoms
- **Health Insights**: AI-generated health recommendations
- **Conversational Chatbot**: Rasa-powered medical dialogue system

### 👥 User Management
- **Custom Authentication**: School ID-based login system
- **Role-Based Access**: Student and clinic staff roles
- **Health Records**: Personal health history tracking
- **Privacy Controls**: GDPR-compliant data handling

### 📊 For Clinic Staff
- **Dashboard Analytics**: Student health trends and statistics
- **Patient Management**: Search and manage student records
- **Report Generation**: Export health data (CSV/Excel)
- **Audit Logging**: Track all system access

### 🎨 Modern UI/UX
- **CPSU Branding**: Official colors (Earls Green & Lemon Yellow)
- **Responsive Design**: Mobile-first approach
- **Accessibility**: WCAG AA compliant
- **Dark Mode Ready**: Theme support

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        CPSU Health Assistant                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────┐    ┌──────────────────┐    ┌──────────────┐ │
│  │  Vue.js Frontend │───▶│ Django REST API  │───▶│  PostgreSQL  │ │
│  │  (TypeScript)    │    │  (Python 3.11)   │    │  (Supabase)  │ │
│  │                  │    │                  │    │              │ │
│  │  - Pinia Store   │    │  - DRF APIs      │    │  - User data │ │
│  │  - Vue Router    │    │  - ML Service    │    │  - Records   │ │
│  │  - TailwindCSS   │    │  - LLM Service   │    │  - Logs      │ │
│  └──────────────────┘    └────────┬─────────┘    └──────────────┘ │
│                                   │                                 │
│                         ┌─────────▼─────────┐                      │
│                         │   ML Pipeline     │                      │
│                         │  - scikit-learn   │                      │
│                         │  - 132 features   │                      │
│                         │  - 41 diseases    │                      │
│                         └───────────────────┘                      │
│                                                                      │
│  ┌──────────────────┐    ┌──────────────────┐                     │
│  │  Rasa Chatbot    │───▶│  LLM Providers   │                     │
│  │  (Optional)      │    │  - Gemini        │                     │
│  │                  │    │  - Grok (Groq)   │                     │
│  │  - NLU Engine    │    │  - Cohere        │                     │
│  │  - Dialogue Mgmt │    │  (All FREE tier) │                     │
│  └──────────────────┘    └──────────────────┘                     │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## 🚀 Deployment

### Azure Cloud (Production) ☁️

**Quick Start**: Deploy to Azure in ~10 minutes!

1. **[Quick Start Guide](./QUICKSTART_AZURE.md)** - Get started in 5 steps
2. **[Full Deployment Guide](./AZURE_DEPLOYMENT_GUIDE.md)** - Complete instructions
3. **[GitHub Secrets Guide](./GITHUB_SECRETS_GUIDE.md)** - Configure secrets

```bash
# One-time setup (follow guides above)
# 1. Create Supabase database
# 2. Create Azure Web App (backend)
# 3. Create Azure Static Web App (frontend)
# 4. Configure GitHub secrets

# Deploy (automatic via GitHub Actions)
git push origin main
```

**What gets deployed**:
- ✅ Django Backend → Azure Web App (Python 3.11)
- ✅ Vue Frontend → Azure Static Web Apps
- ✅ PostgreSQL Database → Supabase (managed)
- ✅ ML Model → Trained & deployed automatically
- ✅ Static Files → CDN-served
- ✅ HTTPS → Automatic SSL certificates

**Cost**: ~$13/month (Azure Web App B1 + Supabase Free tier)

### Local Development 💻

#### Prerequisites
- Python 3.11+
- Node.js 18+
- PostgreSQL (optional, uses SQLite by default)

#### Quick Start

```bash
# 1. Clone repository
git clone https://github.com/souchan25/virtualHealthAssistant.git
cd virtualHealthAssistant

# 2. Setup backend
cd Django
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt

# 3. Train ML model (required first time)
cd ../ML/scripts
python train_model_realistic.py

# 4. Setup database
cd ../../Django
python manage.py migrate
python manage.py createsuperuser  # Use school_id, not username!

# 5. Start backend
python manage.py runserver  # http://localhost:8000

# 6. Setup frontend (new terminal)
cd ../Vue
npm install
npm run dev  # http://localhost:5173
```

**Detailed guides**:
- [Django Backend Setup](./Django/README.md)
- [Vue Frontend Setup](./Vue/README.md)
- [ML Training Guide](./ML/docs/QUICKSTART.md)

## 📁 Project Structure

```
virtualHealthAssistant/
├── Django/                    # Django REST API Backend
│   ├── clinic/               # Main app (models, views, services)
│   │   ├── models.py         # CustomUser, SymptomRecord, etc.
│   │   ├── views.py          # REST API endpoints
│   │   ├── ml_service.py     # ML prediction service
│   │   ├── llm_service.py    # LLM validation service
│   │   └── rasa_webhooks.py  # Rasa integration
│   ├── health_assistant/     # Django project config
│   │   └── settings.py       # Database, CORS, Security
│   └── requirements.txt      # Python dependencies
│
├── Vue/                      # Vue.js Frontend
│   ├── src/
│   │   ├── views/           # Page components
│   │   ├── stores/          # Pinia state management
│   │   ├── services/        # API integration
│   │   └── types/           # TypeScript types
│   ├── package.json         # Node dependencies
│   └── staticwebapp.config.json  # Azure SWA config
│
├── ML/                       # Machine Learning Pipeline
│   ├── scripts/
│   │   ├── train_model_realistic.py  # Main training script
│   │   └── predict.py       # Standalone prediction
│   ├── models/              # Trained models (.pkl)
│   ├── Datasets/active/     # Active training data
│   │   ├── train.csv        # 4,920 samples
│   │   └── symptom_*.csv    # Metadata files
│   └── docs/                # ML documentation
│
├── Rasa/                    # Chatbot (Optional)
│   ├── domain.yml           # Intents, entities, responses
│   ├── actions/             # Custom actions
│   └── data/                # NLU training data
│
├── .github/workflows/       # CI/CD Pipelines
│   ├── azure-django-backend.yml    # Backend deployment
│   ├── azure-vue-frontend.yml      # Frontend deployment
│   └── ci-cd.yml                   # Tests & linting
│
├── QUICKSTART_AZURE.md      # Quick deployment guide
├── AZURE_DEPLOYMENT_GUIDE.md # Full deployment guide
├── GITHUB_SECRETS_GUIDE.md  # Secrets configuration
└── README.md                # This file
```

## 🔧 Technology Stack

### Backend
- **Django 4.2** - Web framework
- **Django REST Framework** - API development
- **PostgreSQL** - Production database (Supabase)
- **SQLite** - Development database
- **Gunicorn** - WSGI server
- **WhiteNoise** - Static file serving

### Machine Learning
- **scikit-learn** - ML models
- **pandas, numpy** - Data processing
- **pickle** - Model serialization
- **Gemini API** - LLM validation (optional)
- **Groq API** - LLM validation (optional)
- **Cohere API** - LLM validation (optional)

### Frontend
- **Vue 3** - Progressive framework
- **TypeScript** - Type safety
- **Vite** - Build tool
- **Pinia** - State management
- **Vue Router** - Routing
- **TailwindCSS** - Styling
- **Axios** - HTTP client

### DevOps
- **GitHub Actions** - CI/CD
- **Azure Web Apps** - Backend hosting
- **Azure Static Web Apps** - Frontend hosting
- **Supabase** - Managed PostgreSQL
- **Docker** - Containerization (optional)

## 🧪 Testing

```bash
# Backend tests
cd Django
python manage.py test clinic

# Frontend tests
cd Vue
npm run type-check

# ML model validation
cd ML/scripts
python test_model.py
```

## 📊 ML Model Performance

- **Accuracy**: 85-95% (realistic noise model)
- **Features**: 132 binary symptoms
- **Classes**: 41 diseases
- **Training Data**: 4,920 samples
- **Validation**: LLM-enhanced (90-98% final accuracy)

## 🔐 Security Features

- ✅ Django security middleware
- ✅ CORS protection
- ✅ CSRF protection
- ✅ SQL injection prevention
- ✅ XSS protection
- ✅ HTTPS enforcement (production)
- ✅ Token-based authentication
- ✅ Password hashing (Argon2)
- ✅ Audit logging
- ✅ Rate limiting
- ✅ Environment-based secrets

## 📝 API Documentation

### Authentication
```http
POST /api/auth/register/    # Register new user
POST /api/auth/login/       # Login (returns token)
POST /api/auth/logout/      # Logout
```

### Symptoms & Prediction
```http
POST /api/symptoms/submit/      # Submit symptoms → get prediction
GET  /api/symptoms/available/   # Get all 132 symptoms
GET  /api/symptoms/             # User's symptom history
```

### Chat (Direct LLM)
```http
POST /api/chat/start/       # Start chat session
POST /api/chat/message/     # Send message → get response
POST /api/chat/insights/    # Generate health insights
```

### Rasa Integration
```http
POST /api/rasa/predict/     # ML prediction webhook (for Rasa)
GET  /api/rasa/symptoms/    # Get symptom list (for Rasa)
```

### Staff Only
```http
GET /api/staff/dashboard/   # Dashboard statistics
GET /api/staff/students/    # Student directory
GET /api/staff/export/      # Export reports (CSV/Excel)
```

**Full API Docs**: [Django/docs/api/API_DOCS.md](./Django/docs/api/API_DOCS.md)

## 🤝 Contributing

This is a thesis project for CPSU. For development:

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 License

This project is developed as a thesis project for Central Philippine State University (CPSU).

## 👥 Team

**CPSU Virtual Health Assistant Team**  
College of Computer Studies  
Central Philippine State University

## 🆘 Support & Documentation

- **[Quick Start](./QUICKSTART_AZURE.md)** - Deploy in 10 minutes
- **[Full Deployment Guide](./AZURE_DEPLOYMENT_GUIDE.md)** - Detailed Azure setup
- **[GitHub Secrets](./GITHUB_SECRETS_GUIDE.md)** - Configure secrets
- **[Workflows Guide](./.github/workflows/README.md)** - CI/CD details
- **[Django Backend](./Django/README.md)** - Backend documentation
- **[Vue Frontend](./Vue/README.md)** - Frontend documentation
- **[ML Pipeline](./ML/docs/)** - ML documentation

## 🌟 Acknowledgments

- CPSU for academic support
- Open source community for amazing tools
- Free tier providers (Supabase, Azure, Gemini, Groq, Cohere)

---

**Last Updated**: February 2026  
**Version**: 1.0.0  
**Status**: Production Ready ✅
