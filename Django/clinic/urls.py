"""
URL Configuration for Clinic app
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views, rasa_webhooks

# Router for viewsets
router = DefaultRouter()
router.register(r'symptoms', views.SymptomRecordViewSet, basename='symptom')
router.register(r'audit', views.AuditLogViewSet, basename='audit')

app_name = 'clinic'

urlpatterns = [
    # Authentication endpoints
    path('auth/register/', views.register_user, name='register'),
    path('auth/login/', views.login_user, name='login'),
    path('auth/logout/', views.logout_user, name='logout'),
    
    # User profile endpoints
    path('profile/', views.UserProfileView.as_view(), name='profile'),
    path('profile/consent/', views.update_consent, name='consent'),
    
    # Symptom & ML endpoints
    path('symptoms/submit/', views.submit_symptoms, name='submit-symptoms'),
    path('symptoms/available/', views.get_available_symptoms, name='available-symptoms'),
    
    # Rasa Webhook endpoints (for Rasa → Django ML integration)
    path('rasa/predict/', rasa_webhooks.rasa_webhook_predict, name='rasa-predict'),
    path('rasa/symptoms/', rasa_webhooks.rasa_webhook_symptoms, name='rasa-symptoms'),
    
    # AI Chat endpoints
    path('chat/start/', views.start_chat_session, name='start-chat'),
    path('chat/message/', views.send_chat_message, name='send-message'),
    path('chat/insights/', views.generate_insights, name='generate-insights'),
    path('chat/end/', views.end_chat_session, name='end-chat'),
    
    # Clinic staff endpoints
    path('staff/dashboard/', views.clinic_dashboard, name='dashboard'),
    path('staff/students/', views.student_directory, name='students'),
    path('staff/export/', views.export_report, name='export'),
    
    # Router URLs (viewsets)
    path('', include(router.urls)),
]
