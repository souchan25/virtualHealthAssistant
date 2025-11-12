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
            <router-link to="/medications" class="text-gray-700 hover:text-cpsu-green">Medications</router-link>
            <router-link to="/followups" class="text-gray-700 hover:text-cpsu-green">Follow-Ups</router-link>
            <router-link to="/health-dashboard" class="text-gray-700 hover:text-cpsu-green">Analytics</router-link>
            <router-link to="/chat" class="text-gray-700 hover:text-cpsu-green">Chat</router-link>
            <router-link to="/history" class="text-cpsu-green font-semibold">History</router-link>
            <router-link to="/profile" class="text-gray-700 hover:text-cpsu-green">Profile</router-link>
          </div>
        </div>
      </div>
    </nav>

    <!-- Main Content -->
    <div class="container mx-auto px-6 py-8 max-w-6xl">
      <div class="mb-8">
        <router-link to="/dashboard" class="text-cpsu-green hover:underline mb-4 inline-block">
          ← Back to Dashboard
        </router-link>
        <h2 class="text-3xl font-heading font-bold text-gray-900">Health History</h2>
        <p class="text-gray-600 mt-2">View and manage your past consultations</p>
      </div>

      <!-- Loading State -->
      <div v-if="symptomsStore.loading" class="text-center py-12">
        <div class="spinner w-16 h-16 mx-auto"></div>
        <p class="text-gray-600 mt-4">Loading your history...</p>
      </div>

      <!-- Empty State -->
      <div v-else-if="symptomsStore.history.length === 0" class="card text-center py-12">
        <div class="text-6xl mb-4">📋</div>
        <h3 class="text-xl font-bold text-gray-900 mb-2">No History Yet</h3>
        <p class="text-gray-600 mb-6">You haven't checked any symptoms yet</p>
        <router-link to="/symptom-checker" class="btn-primary inline-block">
          Check Symptoms Now
        </router-link>
      </div>

      <!-- History List -->
      <div v-else class="space-y-4">
        <div
          v-for="record in symptomsStore.history"
          :key="record.id"
          class="card hover:shadow-lg transition-shadow"
        >
          <div class="flex justify-between items-start mb-4">
            <div class="flex-1">
              <div class="flex items-center gap-3 mb-2">
                <h3 class="text-xl font-bold text-cpsu-green">{{ record.predicted_disease }}</h3>
                <span class="px-3 py-1 bg-cpsu-green text-white text-sm rounded-full">
                  {{ getConfidence(record) }}% confidence
                </span>
                <span v-if="record.llm_validated" class="px-3 py-1 bg-blue-100 text-blue-800 text-sm rounded-full">
                  ✅ AI Validated
                </span>
              </div>
              <p class="text-sm text-gray-500">
                {{ new Date(record.created_at).toLocaleString() }}
              </p>
              <p class="text-sm text-gray-600 mt-1">
                {{ record.symptoms.length }} symptom{{ record.symptoms.length > 1 ? 's' : '' }} reported
              </p>
            </div>
            <button
              @click="deleteRecord(record.id)"
              class="text-red-600 hover:text-red-800 px-3 py-1 hover:bg-red-50 rounded transition-colors"
              title="Delete record"
            >
              🗑️ Delete
            </button>
          </div>

          <!-- Symptoms -->
          <div class="mb-4">
            <p class="text-sm font-medium text-gray-700 mb-2">Reported Symptoms:</p>
            <div class="flex flex-wrap gap-2">
              <span
                v-for="symptom in record.symptoms"
                :key="symptom"
                class="px-3 py-1 bg-gray-100 text-gray-700 rounded-full text-sm"
              >
                {{ symptom }}
              </span>
            </div>
          </div>

          <!-- Top 3 Predictions -->
          <div v-if="record.top_predictions && record.top_predictions.length > 1" class="mb-4">
            <p class="text-sm font-medium text-gray-700 mb-2">Other Possible Conditions:</p>
            <div class="space-y-2">
              <div
                v-for="(pred, index) in record.top_predictions.slice(1, 3)"
                :key="index"
                class="flex items-center justify-between p-3 bg-gray-50 rounded-lg"
              >
                <span class="text-sm text-gray-800">{{ pred.disease }}</span>
                <span class="text-sm font-medium text-gray-600">{{ (pred.confidence * 100).toFixed(1) }}%</span>
              </div>
            </div>
          </div>

          <!-- Description -->
          <div v-if="record.description" class="mb-4 p-4 bg-blue-50 rounded-lg">
            <p class="text-sm font-medium text-gray-900 mb-1">Description:</p>
            <p class="text-sm text-gray-700">{{ record.description }}</p>
          </div>

          <!-- Precautions -->
          <div v-if="record.precautions && record.precautions.length > 0">
            <p class="text-sm font-medium text-gray-900 mb-2">Precautions:</p>
            <ul class="space-y-1">
              <li
                v-for="(precaution, index) in record.precautions"
                :key="index"
                class="text-sm text-gray-700 flex items-start"
              >
                <span class="text-cpsu-green mr-2">✓</span>
                <span>{{ precaution }}</span>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { useSymptomsStore } from '@/stores/symptoms'
import type { SymptomRecord } from '@/types'

const symptomsStore = useSymptomsStore()

onMounted(async () => {
  await symptomsStore.fetchHistory()
})

function getConfidence(record: SymptomRecord): string {
  // Django uses confidence_score, fallback to confidence for older records
  const conf = record.confidence_score ?? record.confidence ?? 0
  return (conf * 100).toFixed(1)
}

async function deleteRecord(id: number) {
  if (confirm('Are you sure you want to delete this record?')) {
    await symptomsStore.deleteRecord(id)
  }
}
</script>
