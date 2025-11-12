<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Navigation Header -->
    <nav class="bg-white shadow-sm border-b-2 border-cpsu-green">
      <div class="container mx-auto px-6 py-4">
        <div class="flex justify-between items-center">
          <router-link to="/dashboard" class="flex items-center space-x-4 text-cpsu-green">
            <img src="@/assets/images/cpsu-logo.png" alt="CPSU Logo" class="h-20 w-20 object-contain">
            <div>
              <h1 class="text-2xl font-heading font-bold">CPSU Health Assistant</h1>
              <p class="text-sm text-gray-600">Mighty Hornbills</p>
            </div>
          </router-link>
          <div class="flex items-center space-x-4">
            <router-link to="/dashboard" class="text-gray-700 hover:text-cpsu-green">Dashboard</router-link>
            <router-link to="/symptom-checker" class="text-gray-700 hover:text-cpsu-green">Check Symptoms</router-link>
            <router-link to="/medications" class="text-cpsu-green font-semibold">Medications</router-link>
            <router-link to="/followups" class="text-gray-700 hover:text-cpsu-green">Follow-Ups</router-link>
            <router-link to="/health-dashboard" class="text-gray-700 hover:text-cpsu-green">Analytics</router-link>
            <router-link to="/chat" class="text-gray-700 hover:text-cpsu-green">Chat</router-link>
            <router-link to="/history" class="text-gray-700 hover:text-cpsu-green">History</router-link>
            <router-link to="/profile" class="text-gray-700 hover:text-cpsu-green">Profile</router-link>
          </div>
        </div>
      </div>
    </nav>

    <!-- Page Content -->
    <div class="container mx-auto px-4 py-8">
      <!-- Back Button -->
      <router-link to="/dashboard" class="inline-flex items-center text-cpsu-green hover:text-green-700 mb-6">
        <span class="text-2xl mr-2">←</span>
        <span class="font-semibold">Back to Dashboard</span>
      </router-link>

      <!-- Header -->
      <div class="flex items-center justify-between mb-8">
        <div>
          <h1 class="text-3xl font-bold text-cpsu-green mb-2">My Medications</h1>
          <p class="text-gray-600">Manage your prescribed medications and track adherence</p>
        </div>
      
      <!-- Adherence Badge -->
      <div v-if="adherenceStats" class="text-center">
        <div class="text-4xl font-bold" :class="adherenceColorClass">
          {{ adherenceStats.adherence_percentage }}%
        </div>
        <div class="text-sm text-gray-600">Overall Adherence</div>
      </div>
    </div>

    <!-- Error Alert -->
    <div v-if="medicationStore.error" class="bg-red-50 border-l-4 border-red-500 p-4 mb-6">
      <div class="flex items-center">
        <span class="text-red-700">{{ medicationStore.error }}</span>
        <button @click="medicationStore.clearError" class="ml-auto text-red-500 hover:text-red-700">
          ✕
        </button>
      </div>
    </div>

    <!-- Today's Schedule Section -->
    <div class="mb-8">
      <h2 class="text-2xl font-bold text-cpsu-green mb-4">📅 Today's Schedule</h2>
      
      <!-- Loading State -->
      <div v-if="medicationStore.loading && todaysLogs.length === 0" class="text-center py-12">
        <div class="inline-block animate-spin rounded-full h-12 w-12 border-4 border-cpsu-green border-t-transparent"></div>
        <p class="mt-4 text-gray-600">Loading medications...</p>
      </div>

      <!-- Empty State -->
      <div v-else-if="todaysLogs.length === 0" class="bg-gray-50 rounded-lg p-8 text-center">
        <p class="text-gray-600">🎉 No medications scheduled for today!</p>
      </div>

      <!-- Medication Logs Grid -->
      <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <div
          v-for="log in todaysLogs"
          :key="log.id"
          class="bg-white rounded-lg border-2 p-4 transition-all hover:shadow-lg"
          :class="getLogCardClass(log)"
        >
          <div class="flex items-start justify-between mb-3">
            <div class="flex-1">
              <h3 class="font-semibold text-lg text-cpsu-green">{{ log.medication_name }}</h3>
              <p class="text-sm text-gray-600">{{ formatTime(log.scheduled_time) }}</p>
            </div>
            <span class="text-2xl">{{ getLogStatusIcon(log) }}</span>
          </div>

          <!-- Status Badge -->
          <div class="mb-3">
            <span
              class="inline-block px-3 py-1 rounded-full text-xs font-semibold"
              :class="getStatusBadgeClass(log)"
            >
              {{ getStatusText(log) }}
            </span>
          </div>

          <!-- Taken Info -->
          <div v-if="log.status === 'taken' && log.taken_at" class="text-xs text-gray-600 mb-3">
            ✓ Taken at {{ formatDateTime(log.taken_at) }}
            <p v-if="log.notes" class="mt-1 italic">{{ log.notes }}</p>
          </div>

          <!-- Action Button -->
          <button
            v-if="log.status === 'pending'"
            @click="markAsTaken(log)"
            class="w-full bg-cpsu-yellow text-cpsu-green font-semibold py-2 px-4 rounded-lg hover:bg-yellow-400 transition"
            :disabled="medicationStore.loading"
          >
            Mark as Taken
          </button>
        </div>
      </div>
    </div>

    <!-- Active Medications Section -->
    <div class="mb-8">
      <h2 class="text-2xl font-bold text-cpsu-green mb-4">💊 Active Medications</h2>
      
      <!-- Empty State -->
      <div v-if="activeMedications.length === 0" class="bg-gray-50 rounded-lg p-8 text-center">
        <p class="text-gray-600">No active medications</p>
      </div>

      <!-- Medications List -->
      <div v-else class="space-y-4">
        <div
          v-for="medication in activeMedications"
          :key="medication.id"
          class="bg-white rounded-lg border-2 border-cpsu-green p-6"
        >
          <div class="flex items-start justify-between mb-4">
            <div class="flex-1">
              <h3 class="text-xl font-bold text-cpsu-green mb-2">{{ medication.name }}</h3>
              <p class="text-gray-700 mb-1"><strong>Dosage:</strong> {{ medication.dosage }}</p>
              <p class="text-gray-700 mb-1"><strong>Frequency:</strong> {{ medication.frequency }}</p>
              <p class="text-gray-700"><strong>Schedule:</strong> {{ medication.schedule_times.join(', ') }}</p>
            </div>
            
            <!-- Adherence Badge -->
            <div v-if="medication.adherence_rate !== undefined" class="text-center ml-4">
              <div
                class="text-3xl font-bold"
                :class="getAdherenceColor(medication.adherence_rate)"
              >
                {{ Math.round(medication.adherence_rate) }}%
              </div>
              <div class="text-xs text-gray-600">Adherence</div>
            </div>
          </div>

          <!-- Date Range -->
          <div class="flex items-center gap-4 mb-4 text-sm text-gray-600">
            <span>📅 {{ formatDate(medication.start_date) }} → {{ formatDate(medication.end_date) }}</span>
            <span v-if="medication.prescribed_by_name" class="ml-auto">
              👨‍⚕️ Dr. {{ medication.prescribed_by_name }}
            </span>
          </div>

          <!-- Instructions -->
          <div v-if="medication.instructions" class="bg-blue-50 rounded-lg p-3 mb-3">
            <p class="text-sm text-blue-900"><strong>Instructions:</strong> {{ medication.instructions }}</p>
          </div>

          <!-- Side Effects -->
          <div v-if="medication.side_effects" class="bg-yellow-50 rounded-lg p-3">
            <p class="text-sm text-yellow-900"><strong>Possible Side Effects:</strong> {{ medication.side_effects }}</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Inactive Medications Section -->
    <div v-if="inactiveMedications.length > 0">
      <h2 class="text-2xl font-bold text-gray-600 mb-4">📦 Past Medications</h2>
      <div class="space-y-3">
        <div
          v-for="medication in inactiveMedications"
          :key="medication.id"
          class="bg-gray-50 rounded-lg border border-gray-300 p-4 opacity-75"
        >
          <h3 class="font-semibold text-gray-700">{{ medication.name }} - {{ medication.dosage }}</h3>
          <p class="text-sm text-gray-600">
            {{ formatDate(medication.start_date) }} → {{ formatDate(medication.end_date) }}
          </p>
        </div>
      </div>
    </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useMedicationStore } from '@/stores/medication'
import type { MedicationLog } from '@/types'

const medicationStore = useMedicationStore()

// Computed properties
const todaysLogs = computed(() => medicationStore.todaysLogs)
const activeMedications = computed(() => medicationStore.activeMedications)
const inactiveMedications = computed(() => medicationStore.inactiveMedications)
const adherenceStats = computed(() => medicationStore.adherenceStats)

const adherenceColorClass = computed(() => {
  if (!adherenceStats.value) return 'text-gray-500'
  const rate = adherenceStats.value.adherence_percentage
  if (rate >= 90) return 'text-green-600'
  if (rate >= 75) return 'text-yellow-600'
  return 'text-red-600'
})

// Methods
const formatTime = (timeStr: string | undefined) => {
  if (!timeStr) return 'N/A'
  const [hours, minutes] = timeStr.split(':')
  const hour = parseInt(hours)
  const ampm = hour >= 12 ? 'PM' : 'AM'
  const displayHour = hour > 12 ? hour - 12 : hour === 0 ? 12 : hour
  return `${displayHour}:${minutes} ${ampm}`
}

const formatDate = (dateStr: string) => {
  return new Date(dateStr).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric'
  })
}

const formatDateTime = (dateTimeStr: string) => {
  return new Date(dateTimeStr).toLocaleString('en-US', {
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
    hour12: true
  })
}

const getLogCardClass = (log: MedicationLog) => {
  if (log.status === 'taken') return 'border-green-500 bg-green-50'
  if (log.status === 'missed') return 'border-red-500 bg-red-50'
  if (log.is_overdue) return 'border-orange-500 bg-orange-50'
  return 'border-cpsu-green'
}

const getLogStatusIcon = (log: MedicationLog) => {
  if (log.status === 'taken') return '✅'
  if (log.status === 'missed') return '❌'
  if (log.is_overdue) return '⚠️'
  return '⏰'
}

const getStatusBadgeClass = (log: MedicationLog) => {
  if (log.status === 'taken') return 'bg-green-200 text-green-800'
  if (log.status === 'missed') return 'bg-red-200 text-red-800'
  if (log.is_overdue) return 'bg-orange-200 text-orange-800'
  return 'bg-blue-200 text-blue-800'
}

const getStatusText = (log: MedicationLog) => {
  if (log.status === 'taken') return 'Taken'
  if (log.status === 'missed') return 'Missed'
  if (log.is_overdue) return 'Overdue'
  return 'Pending'
}

const getAdherenceColor = (rate: number) => {
  if (rate >= 90) return 'text-green-600'
  if (rate >= 75) return 'text-yellow-600'
  return 'text-red-600'
}

const markAsTaken = async (log: MedicationLog) => {
  try {
    await medicationStore.markLogAsTaken(log.id)
    // Refresh adherence stats after marking
    await medicationStore.fetchAdherence()
  } catch (error) {
    console.error('Error marking medication as taken:', error)
  }
}

// Lifecycle
onMounted(async () => {
  await Promise.all([
    medicationStore.fetchMedications(),
    medicationStore.fetchTodaysLogs(),
    medicationStore.fetchAdherence()
  ])
})
</script>
