// User & Authentication Types
export interface User {
  id: number
  school_id: string
  name: string
  role: 'student' | 'staff'
  department?: string
  cpsu_address?: string
  year_level?: number
  course?: string
  data_consent_given: boolean
  consent_date?: string | null
  date_joined: string
}

export interface LoginCredentials {
  school_id: string
  password: string
}

export interface RegisterData {
  school_id: string
  password: string
  password_confirm: string
  name: string
  department?: string
  cpsu_address?: string
  year_level?: number
  course?: string
  data_consent_given?: boolean
}

// Symptoms & Prediction Types
export interface Symptom {
  name: string
  display_name?: string
  severity?: number
}

export interface PredictionResult {
  predicted_disease: string
  confidence: number
  confidence_score?: number  // Django API uses confidence_score
  description?: string
  precautions?: string[]
  severity_score?: number
  ml_confidence?: number
  llm_validated?: boolean  // Django API returns llm_validated
  llm_validation?: {
    agrees_with_ml: boolean
    confidence_boost: number
    reasoning?: string
  }
  top_predictions?: Array<{
    disease: string
    confidence: number
  }>
  recommendations?: string[]
  timestamp: string
}

export interface SymptomRecord {
  id: number
  symptoms: string[]
  predicted_disease: string
  confidence_score: number  // Django uses confidence_score, not confidence
  confidence?: number  // Legacy support
  top_predictions?: Array<{
    disease: string
    confidence: number
  }>
  llm_validated?: boolean
  created_at: string
  description?: string
  precautions?: string[]
}

// Chat Types
export interface ChatMessage {
  id: number
  content: string
  sender: 'user' | 'bot'
  timestamp: string
  metadata?: any
  isError?: boolean
}

export interface ChatSession {
  session_id: string
  created_at: string
}

// Staff Dashboard Types
export interface DashboardStats {
  total_students: number
  active_sessions: number
  total_predictions: number
  common_conditions: Array<{
    disease: string
    count: number
  }>
  recent_activity: Array<{
    student_name: string
    disease: string
    timestamp: string
  }>
}

// API Response Types
export interface ApiResponse<T> {
  data: T
  message?: string
  error?: string
}

export interface PaginatedResponse<T> {
  count: number
  next: string | null
  previous: string | null
  results: T[]
}
