c<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Navigation Header -->
    <nav class="bg-white shadow-sm border-b-2 border-cpsu-green">
      <div class="container mx-auto px-6 py-4">
        <div class="flex justify-between items-center">
          <router-link to="/dashboard" class="text-cpsu-green">
            <h1 class="text-2xl font-heading font-bold">CPSU Health Assistant</h1>
            <p class="text-sm text-gray-600">Mighty Hornbills</p>
          </router-link>
          <div class="flex items-center space-x-4">
            <router-link to="/dashboard" class="text-gray-700 hover:text-cpsu-green">Dashboard</router-link>
            <router-link to="/symptom-checker" class="text-cpsu-green font-semibold">Check Symptoms</router-link>
            <router-link to="/medications" class="text-gray-700 hover:text-cpsu-green">Medications</router-link>
            <router-link to="/followups" class="text-gray-700 hover:text-cpsu-green">Follow-Ups</router-link>
            <router-link to="/health-dashboard" class="text-gray-700 hover:text-cpsu-green">Analytics</router-link>
            <router-link to="/chat" class="text-gray-700 hover:text-cpsu-green">Chat</router-link>
            <router-link to="/history" class="text-gray-700 hover:text-cpsu-green">History</router-link>
            <router-link to="/profile" class="text-gray-700 hover:text-cpsu-green">Profile</router-link>
          </div>
        </div>
      </div>
    </nav>

    <!-- Main Content -->
    <div class="container mx-auto px-6 py-8 max-w-4xl">
      <div class="mb-8">
        <router-link to="/dashboard" class="text-cpsu-green hover:underline mb-4 inline-block">
          ← Back to Dashboard
        </router-link>
        <h2 class="text-3xl font-heading font-bold text-gray-900">Symptom Checker</h2>
        <p class="text-gray-600 mt-2">Select your symptoms to get AI-powered health insights</p>
      </div>

      <!-- Step Indicator -->
      <div class="mb-8">
        <div class="flex items-center justify-center space-x-4">
          <div :class="['flex items-center', currentStep >= 1 ? 'text-cpsu-green' : 'text-gray-400']">
            <div class="w-8 h-8 rounded-full border-2 flex items-center justify-center font-bold"
                 :class="currentStep >= 1 ? 'border-cpsu-green bg-cpsu-green text-white' : 'border-gray-400'">
              1
            </div>
            <span class="ml-2 font-medium">Select Symptoms</span>
          </div>
          <div class="w-12 h-1 bg-gray-300" :class="{ 'bg-cpsu-green': currentStep >= 2 }"></div>
          <div :class="['flex items-center', currentStep >= 2 ? 'text-cpsu-green' : 'text-gray-400']">
            <div class="w-8 h-8 rounded-full border-2 flex items-center justify-center font-bold"
                 :class="currentStep >= 2 ? 'border-cpsu-green bg-cpsu-green text-white' : 'border-gray-400'">
              2
            </div>
            <span class="ml-2 font-medium">Get Results</span>
          </div>
        </div>
      </div>

      <!-- Step 1: Symptom Selection -->
      <div v-if="currentStep === 1" class="card">
        <h3 class="text-xl font-bold text-gray-900 mb-4">Select Your Symptoms</h3>
        
        <!-- Search -->
        <div class="mb-6">
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Search symptoms..."
            class="input-field"
          />
        </div>

        <!-- Selected Symptoms -->
        <div v-if="symptomsStore.selectedSymptoms.length > 0" class="mb-6">
          <p class="text-sm font-medium text-gray-700 mb-2">Selected ({{ symptomsStore.selectedSymptoms.length }}):</p>
          <div class="flex flex-wrap gap-2">
            <span
              v-for="symptom in symptomsStore.selectedSymptoms"
              :key="symptom"
              class="px-3 py-1 bg-cpsu-green text-white rounded-full text-sm flex items-center gap-2"
            >
              {{ symptom }}
              <button @click="symptomsStore.toggleSymptom(symptom)" class="hover:text-cpsu-yellow">✕</button>
            </span>
          </div>
        </div>

        <!-- Symptoms Grid -->
        <div v-if="symptomsStore.loading" class="text-center py-8">
          <div class="spinner w-12 h-12 mx-auto"></div>
        </div>

        <div v-else class="grid grid-cols-2 md:grid-cols-3 gap-3 max-h-96 overflow-y-auto">
          <button
            v-for="symptom in filteredSymptoms"
            :key="symptom"
            @click="symptomsStore.toggleSymptom(symptom)"
            class="px-4 py-3 rounded-lg border-2 text-left transition-all"
            :class="symptomsStore.selectedSymptoms.includes(symptom)
              ? 'border-cpsu-green bg-cpsu-green text-white'
              : 'border-gray-300 hover:border-cpsu-green'"
          >
            {{ symptom }}
          </button>
        </div>

        <!-- Actions -->
        <div class="mt-6 flex justify-between">
          <button
            v-if="symptomsStore.selectedSymptoms.length > 0"
            @click="symptomsStore.clearSelection"
            class="btn-outline"
          >
            Clear All
          </button>
          <button
            :disabled="symptomsStore.selectedSymptoms.length === 0"
            @click="getPrediction"
            class="btn-primary ml-auto disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Get Prediction ({{ symptomsStore.selectedSymptoms.length }} symptoms)
          </button>
        </div>
      </div>

      <!-- Step 2: Results -->
      <div v-if="currentStep === 2 && symptomsStore.predictionResult" class="space-y-6">
        <!-- Main Result -->
        <div class="card-bordered">
          <div class="flex items-start justify-between mb-4">
            <div>
              <h3 class="text-2xl font-bold text-cpsu-green">{{ symptomsStore.predictionResult.predicted_disease }}</h3>
              <p class="text-gray-600 mt-1">Based on {{ symptomsStore.selectedSymptoms.length }} symptoms</p>
            </div>
            <div class="text-right">
              <div class="text-3xl font-bold text-cpsu-green">
                {{ getConfidencePercent() }}%
              </div>
              <p class="text-sm text-gray-600">Confidence</p>
              <span v-if="symptomsStore.predictionResult.llm_validated" class="inline-block mt-1 px-2 py-1 bg-blue-100 text-blue-800 text-xs rounded">
                ✅ AI Validated
              </span>
            </div>
          </div>

          <!-- Top Predictions -->
          <div v-if="symptomsStore.predictionResult.top_predictions && symptomsStore.predictionResult.top_predictions.length > 1" class="mb-4">
            <h4 class="font-semibold text-gray-900 mb-3">Other Possible Conditions:</h4>
            <div class="space-y-2">
              <div
                v-for="(pred, index) in symptomsStore.predictionResult.top_predictions.slice(1, 3)"
                :key="index"
                class="flex items-center justify-between p-3 bg-gray-50 rounded-lg"
              >
                <span class="text-sm text-gray-800">{{ pred.disease }}</span>
                <span class="text-sm font-medium text-gray-600">{{ (pred.confidence * 100).toFixed(1) }}%</span>
              </div>
            </div>
          </div>

          <!-- Description -->
          <div v-if="symptomsStore.predictionResult.description" class="mb-4 p-4 bg-blue-50 rounded-lg">
            <h4 class="font-semibold text-gray-900 mb-2">Description:</h4>
            <p class="text-gray-700">{{ symptomsStore.predictionResult.description }}</p>
          </div>

          <!-- LLM Validation -->
          <div v-if="symptomsStore.predictionResult.llm_validation" class="mb-4 p-4 bg-green-50 border border-green-200 rounded-lg">
            <h4 class="font-semibold text-green-900 mb-2">✅ AI Validation:</h4>
            <p class="text-green-800">{{ symptomsStore.predictionResult.llm_validation.reasoning || 'Prediction validated by multiple AI models' }}</p>
          </div>
        </div>

        <!-- Precautions -->
        <div v-if="symptomsStore.predictionResult.precautions" class="card">
          <h4 class="font-semibold text-gray-900 mb-3">Recommended Precautions:</h4>
          <ul class="space-y-2">
            <li
              v-for="(precaution, index) in symptomsStore.predictionResult.precautions"
              :key="index"
              class="flex items-start"
            >
              <span class="text-cpsu-green mr-2">✓</span>
              <span class="text-gray-700">{{ precaution }}</span>
            </li>
          </ul>
        </div>

        <!-- Actions -->
        <div class="flex gap-4">
          <button @click="startOver" class="btn-outline flex-1">
            Check Again
          </button>
          <router-link to="/chat" class="btn-secondary flex-1 text-center">
            Talk to Health Assistant
          </router-link>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useSymptomsStore } from '@/stores/symptoms'

const router = useRouter()
const authStore = useAuthStore()
const symptomsStore = useSymptomsStore()

const currentStep = ref(1)
const searchQuery = ref('')

const filteredSymptoms = computed(() => {
  if (!searchQuery.value) {
    return symptomsStore.availableSymptoms.map((s: any) => typeof s === 'string' ? s : s.name)
  }
  
  return symptomsStore.availableSymptoms
    .map((s: any) => typeof s === 'string' ? s : s.name)
    .filter((symptom: string) => 
      symptom.toLowerCase().includes(searchQuery.value.toLowerCase())
    )
})

onMounted(async () => {
  await symptomsStore.fetchAvailableSymptoms()
})

async function getPrediction() {
  try {
    await symptomsStore.submitSymptoms(symptomsStore.selectedSymptoms, true)
    currentStep.value = 2
  } catch (error) {
    console.error('Prediction failed:', error)
  }
}

function startOver() {
  symptomsStore.clearSelection()
  currentStep.value = 1
  searchQuery.value = ''
}

function getConfidencePercent(): string {
  const result = symptomsStore.predictionResult
  if (!result) return '0.0'
  
  // Try confidence_score first (Django API), fallback to confidence, default to 0
  const confidence = result.confidence_score ?? result.confidence ?? 0
  return (confidence * 100).toFixed(1)
}

async function handleLogout() {
  await authStore.logout()
  router.push('/login')
}
</script>
