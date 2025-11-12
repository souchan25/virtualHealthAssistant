"""
Serializers for CPSU Health Assistant API
Handles data validation and transformation
"""

from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import (
    SymptomRecord, HealthInsight, ChatSession, 
    ConsentLog, AuditLog, DepartmentStats, EmergencyAlert
)

User = get_user_model()


class UserRegistrationSerializer(serializers.ModelSerializer):
    """Serializer for user registration"""
    password = serializers.CharField(write_only=True, min_length=6)
    password_confirm = serializers.CharField(write_only=True)
    
    class Meta:
        model = User
        fields = ['school_id', 'password', 'password_confirm', 'name', 'department', 'cpsu_address', 'role', 'data_consent_given']
        extra_kwargs = {
            'role': {'read_only': True},  # Role is set based on context, not user input
        }
    
    def validate(self, data):
        if data['password'] != data['password_confirm']:
            raise serializers.ValidationError({"password": "Passwords must match"})
        return data
    
    def create(self, validated_data):
        validated_data.pop('password_confirm')
        password = validated_data.pop('password')
        user = User.objects.create_user(password=password, **validated_data)
        return user


class UserProfileSerializer(serializers.ModelSerializer):
    """Serializer for user profile (read/update)"""
    
    class Meta:
        model = User
        fields = ['school_id', 'name', 'department', 'cpsu_address', 'role', 'data_consent_given', 'consent_date', 'date_joined']
        read_only_fields = ['school_id', 'role', 'consent_date', 'date_joined']


class SymptomRecordSerializer(serializers.ModelSerializer):
    """Serializer for symptom records"""
    student_school_id = serializers.CharField(source='student.school_id', read_only=True)
    student_name = serializers.CharField(source='student.name', read_only=True)
    
    class Meta:
        model = SymptomRecord
        fields = [
            'id', 'student', 'student_school_id', 'student_name',
            'symptoms', 'duration_days', 'severity',
            'predicted_disease', 'confidence_score', 'top_predictions',
            'on_medication', 'medication_adherence',
            'is_communicable', 'is_acute', 'icd10_code',
            'requires_referral', 'referral_triggered', 'referral_date',
            'created_at', 'updated_at'
        ]
        read_only_fields = [
            'student', 'predicted_disease', 'confidence_score', 'top_predictions',
            'is_communicable', 'is_acute', 'icd10_code',
            'requires_referral', 'referral_triggered', 'referral_date',
            'created_at', 'updated_at'
        ]


class SymptomSubmissionSerializer(serializers.Serializer):
    """Serializer for symptom submission endpoint"""
    symptoms = serializers.ListField(
        child=serializers.CharField(max_length=100),
        min_length=1,
        help_text='List of symptom names'
    )
    duration_days = serializers.IntegerField(min_value=1, default=1, required=False)
    severity = serializers.ChoiceField(
        choices=[(1, 'Mild'), (2, 'Moderate'), (3, 'Severe')],
        default=2,
        required=False
    )
    on_medication = serializers.BooleanField(default=False, required=False)
    medication_adherence = serializers.BooleanField(required=False, allow_null=True)


class DiseasePredictionSerializer(serializers.Serializer):
    """Serializer for disease prediction response"""
    predicted_disease = serializers.CharField()
    confidence_score = serializers.FloatField()
    top_predictions = serializers.ListField()
    description = serializers.CharField(allow_blank=True)
    precautions = serializers.ListField()
    is_communicable = serializers.BooleanField()
    is_acute = serializers.BooleanField()
    icd10_code = serializers.CharField(allow_blank=True)


class HealthInsightSerializer(serializers.ModelSerializer):
    """Serializer for AI health insights"""
    
    class Meta:
        model = HealthInsight
        fields = ['id', 'session_id', 'insight_text', 'references', 'reliability_score', 'generated_at']
        read_only_fields = ['id', 'generated_at']


class ChatSessionSerializer(serializers.ModelSerializer):
    """Serializer for chat sessions"""
    insights = HealthInsightSerializer(many=True, read_only=True, source='student.health_insights')
    
    class Meta:
        model = ChatSession
        fields = ['id', 'started_at', 'ended_at', 'duration_seconds', 'language', 'topics_discussed', 'insights_generated_count', 'insights']
        read_only_fields = ['id', 'started_at', 'insights_generated_count']


class ChatMessageSerializer(serializers.Serializer):
    """Serializer for real-time chat messages"""
    message = serializers.CharField(max_length=2000)
    language = serializers.ChoiceField(
        choices=['english', 'filipino', 'cebuano', 'tagalog'],
        default='english'
    )
    session_id = serializers.UUIDField(required=False)


class ConsentLogSerializer(serializers.ModelSerializer):
    """Serializer for consent logs"""
    
    class Meta:
        model = ConsentLog
        fields = ['id', 'action', 'ip_address', 'user_agent', 'timestamp']
        read_only_fields = ['id', 'timestamp']


class AuditLogSerializer(serializers.ModelSerializer):
    """Serializer for audit logs (staff only)"""
    user_school_id = serializers.CharField(source='user.school_id', read_only=True)
    
    class Meta:
        model = AuditLog
        fields = [
            'id', 'user', 'user_school_id', 'action', 'model_name', 'object_id',
            'changes', 'timestamp', 'ip_address', 'user_agent', 'success', 'error_message'
        ]
        read_only_fields = ['id', 'timestamp']


class DepartmentStatsSerializer(serializers.ModelSerializer):
    """Serializer for department statistics"""
    
    class Meta:
        model = DepartmentStats
        fields = [
            'department', 'total_students', 'students_with_symptoms', 'percentage_with_symptoms',
            'top_diseases', 'communicable_count', 'non_communicable_count',
            'acute_count', 'chronic_count', 'referral_pending_count', 'last_updated'
        ]
        read_only_fields = ['last_updated']


class DashboardStatsSerializer(serializers.Serializer):
    """Serializer for clinic dashboard overview"""
    total_students = serializers.IntegerField()
    students_with_symptoms_today = serializers.IntegerField()
    students_with_symptoms_7days = serializers.IntegerField()
    students_with_symptoms_30days = serializers.IntegerField()
    top_insight = serializers.CharField(allow_blank=True)
    department_breakdown = DepartmentStatsSerializer(many=True)
    recent_symptoms = SymptomRecordSerializer(many=True)
    pending_referrals = serializers.IntegerField()


class EmergencyAlertSerializer(serializers.ModelSerializer):
    """Serializer for emergency alerts"""
    student_school_id = serializers.CharField(source='student.school_id', read_only=True)
    student_name = serializers.CharField(source='student.name', read_only=True)
    student_department = serializers.CharField(source='student.department', read_only=True)
    responded_by_name = serializers.CharField(source='responded_by.name', read_only=True, allow_null=True)
    response_time_minutes = serializers.IntegerField(read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    
    class Meta:
        model = EmergencyAlert
        fields = [
            'id', 'student_school_id', 'student_name', 'student_department',
            'location', 'symptoms', 'description', 'status', 'status_display',
            'priority', 'responded_by_name', 'response_time', 'response_time_minutes',
            'resolved_at', 'resolution_notes', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'response_time_minutes']


class EmergencyTriggerSerializer(serializers.Serializer):
    """Serializer for triggering emergency alert"""
    location = serializers.CharField(max_length=255, required=True)
    symptoms = serializers.ListField(
        child=serializers.CharField(),
        required=False,
        default=list
    )
    description = serializers.CharField(
        required=False,
        allow_blank=True,
        default=''
    )
