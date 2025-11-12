<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Navigation -->
    <nav class="bg-white shadow-sm border-b-2 border-cpsu-green">
      <div class="container mx-auto px-6 py-4">
        <div class="flex justify-between items-center mb-4">
          <div>
            <h1 class="text-2xl font-heading font-bold text-cpsu-green">CPSU Health Clinic</h1>
            <p class="text-sm text-gray-600">Staff Dashboard - {{ authStore.user?.name }}</p>
          </div>
          <button @click="handleLogout" class="btn-outline !py-2 !px-4">Logout</button>
        </div>
        <!-- Navigation Menu -->
        <div class="flex items-center space-x-4 border-t pt-3">
          <router-link to="/staff" class="text-gray-700 hover:text-cpsu-green font-medium">
            📊 Dashboard
          </router-link>
          <router-link to="/staff/emergencies" class="text-gray-700 hover:text-cpsu-green font-medium">
            🚨 Emergencies
          </router-link>
          <router-link to="/staff/students" class="text-gray-700 hover:text-cpsu-green font-medium">
            👥 Students
          </router-link>
          <router-link to="/staff/prescribe" class="text-gray-700 hover:text-cpsu-green font-medium">
            💊 Prescribe
          </router-link>
          <router-link to="/staff/adherence" class="text-gray-700 hover:text-cpsu-green font-medium">
            📈 Adherence
          </router-link>
          <router-link to="/staff/followups" class="text-gray-700 hover:text-cpsu-green font-medium">
            📋 Follow-Ups
          </router-link>
          <router-link to="/staff/analytics" class="text-gray-700 hover:text-cpsu-green font-medium">
            📉 Analytics
          </router-link>
        </div>
      </div>
    </nav>

    <!-- Main Content -->
    <div class="container mx-auto px-6 py-8">
      <!-- Stats Cards -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
        <div class="card-bordered bg-white">
          <h3 class="text-sm font-semibold text-gray-600 mb-2">Total Students</h3>
          <p class="text-3xl font-bold text-cpsu-green">{{ stats.total_students || 0 }}</p>
        </div>
        
        <div class="card-bordered bg-white">
          <h3 class="text-sm font-semibold text-gray-600 mb-2">Consultations Today</h3>
          <p class="text-3xl font-bold text-blue-600">{{ stats.students_with_symptoms_today || 0 }}</p>
        </div>
        
        <div class="card-bordered bg-white">
          <h3 class="text-sm font-semibold text-gray-600 mb-2">Last 7 Days</h3>
          <p class="text-3xl font-bold text-purple-600">{{ stats.students_with_symptoms_7days || 0 }}</p>
        </div>
        
        <div class="card-bordered bg-white">
          <h3 class="text-sm font-semibold text-gray-600 mb-2">Pending Referrals</h3>
          <p class="text-3xl font-bold text-red-600">{{ stats.pending_referrals || 0 }}</p>
        </div>
      </div>

      <!-- Top Insight -->
      <div v-if="stats.top_insight" class="card-bordered bg-cpsu-yellow mb-8">
        <h3 class="font-semibold text-cpsu-green mb-2">🔍 Top Health Concern</h3>
        <p class="text-lg text-gray-800">{{ stats.top_insight }}</p>
      </div>

      <!-- Tabs -->
      <div class="bg-white rounded-lg shadow-sm border-2 border-gray-200">
        <div class="border-b border-gray-200">
          <div class="flex space-x-1 p-1">
            <button
              @click="activeTab = 'overview'"
              :class="['px-6 py-3 font-medium rounded-t-lg transition', activeTab === 'overview' ? 'bg-cpsu-green text-white' : 'text-gray-600 hover:bg-gray-100']"
            >
              Overview
            </button>
            <button
              @click="activeTab = 'students'"
              :class="['px-6 py-3 font-medium rounded-t-lg transition', activeTab === 'students' ? 'bg-cpsu-green text-white' : 'text-gray-600 hover:bg-gray-100']"
            >
              Student Directory
            </button>
            <button
              @click="activeTab = 'reports'"
              :class="['px-6 py-3 font-medium rounded-t-lg transition', activeTab === 'reports' ? 'bg-cpsu-green text-white' : 'text-gray-600 hover:bg-gray-100']"
            >
              Reports & Export
            </button>
          </div>
        </div>

        <div class="p-6">
          <!-- Overview Tab -->
          <div v-if="activeTab === 'overview'" class="space-y-6">
            <!-- Department Breakdown -->
            <div>
              <h3 class="text-lg font-semibold text-gray-900 mb-4">Department Breakdown</h3>
              <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200">
                  <thead class="bg-gray-50">
                    <tr>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Department</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Total Students</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">With Symptoms</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">% Affected</th>
                    </tr>
                  </thead>
                  <tbody class="bg-white divide-y divide-gray-200">
                    <tr v-for="dept in stats.department_breakdown" :key="dept.department">
                      <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{{ dept.department }}</td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ dept.total_students }}</td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ dept.students_with_symptoms }}</td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {{ ((dept.students_with_symptoms / dept.total_students) * 100).toFixed(1) }}%
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>

            <!-- Recent Activity -->
            <div>
              <h3 class="text-lg font-semibold text-gray-900 mb-4">Recent Consultations</h3>
              <div class="space-y-3">
                <div v-for="record in stats.recent_symptoms" :key="record.id" class="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                  <div class="flex-1">
                    <p class="font-medium text-gray-900">{{ record.student_name || 'Student' }}</p>
                    <p class="text-sm text-gray-600">{{ record.predicted_disease }} - {{ (record.confidence_score * 100).toFixed(1) }}%</p>
                    <p class="text-xs text-gray-500">{{ record.symptoms.join(', ') }}</p>
                  </div>
                  <div class="text-right">
                    <p class="text-sm text-gray-600">{{ formatDate(record.created_at) }}</p>
                    <span v-if="record.requires_referral" class="inline-block px-2 py-1 text-xs bg-red-100 text-red-800 rounded">Referral Required</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Students Tab -->
          <div v-if="activeTab === 'students'">
            <StudentDirectory />
          </div>

          <!-- Reports Tab -->
          <div v-if="activeTab === 'reports'">
            <ReportsExport />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import api from '@/services/api'
import StudentDirectory from './StudentDirectory.vue'
import ReportsExport from './ReportsExport.vue'

const router = useRouter()
const authStore = useAuthStore()

const activeTab = ref('overview')
const stats = ref<any>({
  total_students: 0,
  students_with_symptoms_today: 0,
  students_with_symptoms_7days: 0,
  students_with_symptoms_30days: 0,
  pending_referrals: 0,
  top_insight: '',
  department_breakdown: [],
  recent_symptoms: []
})

onMounted(async () => {
  await loadDashboard()
})

async function loadDashboard() {
  try {
    const response = await api.get('/staff/dashboard/')
    stats.value = response.data
  } catch (error) {
    console.error('Failed to load dashboard:', error)
  }
}

function formatDate(dateStr: string): string {
  const date = new Date(dateStr)
  return date.toLocaleDateString() + ' ' + date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
}

async function handleLogout() {
  await authStore.logout()
  router.push('/login')
}
</script>
