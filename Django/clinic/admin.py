"""
Django Admin configuration for Clinic app
"""

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import (
    CustomUser, SymptomRecord, HealthInsight, ChatSession,
    ConsentLog, AuditLog, DepartmentStats
)


@admin.register(CustomUser)
class CustomUserAdmin(BaseUserAdmin):
    """Admin interface for custom user model"""
    
    list_display = ['school_id', 'name', 'role', 'department', 'data_consent_given', 'is_active', 'date_joined']
    list_filter = ['role', 'data_consent_given', 'is_active', 'department']
    search_fields = ['school_id', 'name', 'department']
    ordering = ['-date_joined']
    
    fieldsets = (
        ('Credentials', {
            'fields': ('school_id', 'password')
        }),
        ('Personal Info', {
            'fields': ('name', 'department', 'cpsu_address')
        }),
        ('Role & Permissions', {
            'fields': ('role', 'is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')
        }),
        ('Data Consent', {
            'fields': ('data_consent_given', 'consent_date')
        }),
        ('Important Dates', {
            'fields': ('last_login', 'date_joined')
        }),
    )
    
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('school_id', 'name', 'department', 'role', 'password1', 'password2'),
        }),
    )
    
    readonly_fields = ['last_login', 'date_joined', 'consent_date']


@admin.register(SymptomRecord)
class SymptomRecordAdmin(admin.ModelAdmin):
    """Admin interface for symptom records"""
    
    list_display = ['student', 'predicted_disease', 'confidence_score', 'duration_days', 'severity', 'requires_referral', 'created_at']
    list_filter = ['severity', 'is_communicable', 'is_acute', 'requires_referral', 'created_at']
    search_fields = ['student__school_id', 'student__name', 'predicted_disease']
    readonly_fields = ['id', 'created_at', 'updated_at', 'predicted_disease', 'confidence_score', 'top_predictions']
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('Student & Symptoms', {
            'fields': ('student', 'symptoms', 'duration_days', 'severity')
        }),
        ('ML Prediction', {
            'fields': ('predicted_disease', 'confidence_score', 'top_predictions', 'is_communicable', 'is_acute', 'icd10_code')
        }),
        ('Medication', {
            'fields': ('on_medication', 'medication_adherence')
        }),
        ('Referral', {
            'fields': ('requires_referral', 'referral_triggered', 'referral_date')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at')
        }),
    )


@admin.register(HealthInsight)
class HealthInsightAdmin(admin.ModelAdmin):
    """Admin interface for health insights"""
    
    list_display = ['student', 'session_id', 'reliability_score', 'generated_at']
    list_filter = ['reliability_score', 'generated_at']
    search_fields = ['student__school_id', 'insight_text']
    readonly_fields = ['id', 'generated_at']
    date_hierarchy = 'generated_at'


@admin.register(ChatSession)
class ChatSessionAdmin(admin.ModelAdmin):
    """Admin interface for chat sessions"""
    
    list_display = ['student', 'language', 'started_at', 'duration_seconds', 'insights_generated_count']
    list_filter = ['language', 'started_at']
    search_fields = ['student__school_id']
    readonly_fields = ['id', 'started_at']
    date_hierarchy = 'started_at'


@admin.register(ConsentLog)
class ConsentLogAdmin(admin.ModelAdmin):
    """Admin interface for consent logs"""
    
    list_display = ['user', 'action', 'timestamp', 'ip_address']
    list_filter = ['action', 'timestamp']
    search_fields = ['user__school_id']
    readonly_fields = ['id', 'timestamp']
    date_hierarchy = 'timestamp'


@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    """Admin interface for audit logs"""
    
    list_display = ['user', 'action', 'model_name', 'success', 'timestamp']
    list_filter = ['action', 'success', 'timestamp']
    search_fields = ['user__school_id', 'model_name']
    readonly_fields = ['id', 'timestamp']
    date_hierarchy = 'timestamp'


@admin.register(DepartmentStats)
class DepartmentStatsAdmin(admin.ModelAdmin):
    """Admin interface for department statistics"""
    
    list_display = ['department', 'total_students', 'students_with_symptoms', 'percentage_with_symptoms', 'last_updated']
    list_filter = ['last_updated']
    search_fields = ['department']
    readonly_fields = ['last_updated']
