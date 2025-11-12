import api from './api'
import type {
  Medication,
  MedicationLog,
  MedicationCreateData,
  AdherenceStats
} from '@/types'

export const medicationService = {
  // Get all medications for current user
  async getMedications(): Promise<Medication[]> {
    const response = await api.get('/medications/')
    // Ensure we always return an array
    return Array.isArray(response.data) ? response.data : []
  },

  // Get medications for specific student (staff only)
  async getMedicationsByStudent(studentId: number): Promise<Medication[]> {
    const response = await api.get('/medications/', {
      params: { student_id: studentId }
    })
    // Ensure we always return an array
    return Array.isArray(response.data) ? response.data : []
  },

  // Get single medication
  async getMedication(id: number): Promise<Medication> {
    const response = await api.get(`/medications/${id}/`)
    return response.data
  },

  // Create new medication (staff only)
  async createMedication(data: MedicationCreateData): Promise<Medication> {
    const response = await api.post('/medications/create/', data)
    return response.data
  },

  // Update medication
  async updateMedication(id: number, data: Partial<MedicationCreateData>): Promise<Medication> {
    const response = await api.put(`/medications/update/${id}/`, data)
    return response.data
  },

  // Get today's medication logs
  async getTodaysLogs(): Promise<MedicationLog[]> {
    const response = await api.get('/medications/logs/today/')
    // Ensure we always return an array
    return Array.isArray(response.data) ? response.data : []
  },

  // Mark medication log as taken
  async markLogAsTaken(logId: number, notes?: string): Promise<MedicationLog> {
    const response = await api.post(`/medications/logs/${logId}/taken/`, { notes })
    return response.data
  },

  // Get adherence statistics
  async getAdherence(studentId?: number, startDate?: string, endDate?: string): Promise<AdherenceStats> {
    const params: any = {}
    if (studentId) params.student_id = studentId
    if (startDate) params.start_date = startDate
    if (endDate) params.end_date = endDate

    const response = await api.get('/medications/adherence/', { params })
    return response.data
  }
}
