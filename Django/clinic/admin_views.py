"""
Custom admin views for backend monitoring
Provides dashboard with metrics, LLM usage, and system health
"""

from django.contrib.admin.views.decorators import staff_member_required
from django.shortcuts import render
from django.db.models import Count, Q
from django.utils import timezone
from django.conf import settings
from datetime import timedelta
from clinic.models import AuditLog, CustomUser
import os


@staff_member_required
def backend_monitoring_dashboard(request):
    """
    Custom dashboard showing:
    - Backend metrics (API latency, errors)
    - LLM API usage stats
    - System health indicators
    """
    
    # Time ranges
    now = timezone.now()
    last_24h = now - timedelta(hours=24)
    last_7d = now - timedelta(days=7)
    last_30d = now - timedelta(days=30)
    
    # User stats
    total_users = CustomUser.objects.count()
    active_users_24h = AuditLog.objects.filter(
        timestamp__gte=last_24h,
        action='login'
    ).values('user').distinct().count()
    
    staff_count = CustomUser.objects.filter(role='clinic_staff').count()
    student_count = CustomUser.objects.filter(role='student').count()
    
    # API Activity (Last 24 hours)
    api_logs_24h = AuditLog.objects.filter(timestamp__gte=last_24h)
    
    total_requests_24h = api_logs_24h.count()
    failed_requests_24h = api_logs_24h.filter(success=False).count()
    success_rate_24h = (
        ((total_requests_24h - failed_requests_24h) / total_requests_24h * 100)
        if total_requests_24h > 0 else 100
    )
    
    # Recent errors (Last 7 days)
    recent_errors = AuditLog.objects.filter(
        success=False,
        timestamp__gte=last_7d
    ).order_by('-timestamp')[:10]
    
    # Action breakdown (Last 24h)
    action_stats = api_logs_24h.values('action').annotate(
        count=Count('id')
    ).order_by('-count')[:5]
    
    # Failed login attempts (security monitoring)
    failed_logins_24h = AuditLog.objects.filter(
        action='failed_login',
        timestamp__gte=last_24h
    ).count()
    
    # LLM API Configuration Status
    llm_providers = {
        'Gemini': {
            'configured': bool(os.getenv('GEMINI_API_KEY')),
            'tier': 'Free (1,500 req/day)',
            'dashboard': 'https://aistudio.google.com/apikey'
        },
        'OpenRouter (Qwen)': {
            'configured': bool(os.getenv('OPENROUTER_API_KEY')),
            'tier': 'Free (Limited)',
            'dashboard': 'https://openrouter.ai/activity'
        },
        'Groq (Grok 2)': {
            'configured': bool(os.getenv('GROQ_API_KEY')),
            'tier': 'Free (30 req/min)',
            'dashboard': 'https://console.groq.com/'
        },
        'Cohere': {
            'configured': bool(os.getenv('COHERE_API_KEY')),
            'tier': 'Free (100 req/min)',
            'dashboard': 'https://dashboard.cohere.com/'
        }
    }
    
    # System Health Indicators
    health_checks = {
        'Database': {
            'status': 'healthy',
            'details': f'{total_users} total users'
        },
        'ML Model': {
            'status': 'healthy' if settings.ML_MODEL_PATH.exists() else 'warning',
            'details': 'Loaded' if settings.ML_MODEL_PATH.exists() else 'Not found'
        },
        'LLM Providers': {
            'status': 'healthy' if any(p['configured'] for p in llm_providers.values()) else 'warning',
            'details': f"{sum(1 for p in llm_providers.values() if p['configured'])}/4 configured"
        }
    }
    
    context = {
        # User stats
        'total_users': total_users,
        'active_users_24h': active_users_24h,
        'staff_count': staff_count,
        'student_count': student_count,
        
        # API stats
        'total_requests_24h': total_requests_24h,
        'failed_requests_24h': failed_requests_24h,
        'success_rate_24h': round(success_rate_24h, 1),
        'failed_logins_24h': failed_logins_24h,
        
        # Recent data
        'recent_errors': recent_errors,
        'action_stats': action_stats,
        
        # LLM & Health
        'llm_providers': llm_providers,
        'health_checks': health_checks,
        
        # Meta
        'last_updated': now,
    }
    
    return render(request, 'admin/backend_monitoring.html', context)
