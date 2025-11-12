<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Navigation -->
    <nav class="bg-white shadow-sm border-b-2 border-cpsu-green">
      <div class="container mx-auto px-6 py-4">
        <div class="flex justify-between items-center">
          <div>
            <h1 class="text-2xl font-heading font-bold text-cpsu-green">CPSU Health Assistant</h1>
            <p class="text-sm text-gray-600">Welcome, {{ authStore.userName }}</p>
          </div>
          <div class="flex items-center space-x-4">
            <router-link to="/dashboard" class="text-gray-700 hover:text-cpsu-green">Dashboard</router-link>
            <router-link to="/symptom-checker" class="text-gray-700 hover:text-cpsu-green">Check Symptoms</router-link>
            <router-link to="/chat" class="text-gray-700 hover:text-cpsu-green">Chat</router-link>
            <router-link to="/history" class="text-gray-700 hover:text-cpsu-green">History</router-link>
            <router-link to="/profile" class="text-gray-700 hover:text-cpsu-green">Profile</router-link>
            <button @click="handleLogout" class="btn-outline !py-2 !px-4">Logout</button>
          </div>
        </div>
      </div>
    </nav>

    <!-- Dashboard Content -->
    <div class="container mx-auto px-6 py-8">
      <div class="mb-8">
        <h2 class="text-3xl font-heading font-bold text-gray-900">Dashboard</h2>
        <p class="text-gray-600 mt-2">Your health overview and quick actions</p>
      </div>

      <!-- Quick Actions -->
      <div class="grid md:grid-cols-3 gap-6 mb-8">
        <router-link to="/symptom-checker" class="card-bordered hover:shadow-xl transition-shadow">
          <div class="text-4xl mb-4">🩺</div>
          <h3 class="text-xl font-bold text-cpsu-green mb-2">Check Symptoms</h3>
          <p class="text-gray-600">Get AI-powered disease predictions</p>
        </router-link>

        <router-link to="/chat" class="card-bordered hover:shadow-xl transition-shadow">
          <div class="text-4xl mb-4">💬</div>
          <h3 class="text-xl font-bold text-cpsu-green mb-2">Chat Assistant</h3>
          <p class="text-gray-600">Talk to our health chatbot</p>
        </router-link>

        <router-link to="/history" class="card-bordered hover:shadow-xl transition-shadow">
          <div class="text-4xl mb-4">📊</div>
          <h3 class="text-xl font-bold text-cpsu-green mb-2">View History</h3>
          <p class="text-gray-600">See your past consultations</p>
        </router-link>
      </div>

      <!-- Recent Activity -->
      <div class="card">
        <h3 class="text-xl font-bold text-gray-900 mb-4">Recent Activity</h3>
        
        <div v-if="symptomsStore.loading" class="text-center py-8">
          <div class="spinner w-12 h-12 mx-auto"></div>
        </div>

        <div v-else-if="symptomsStore.history.length === 0" class="text-center py-8 text-gray-500">
          <p>No recent activity</p>
          <router-link to="/symptom-checker" class="text-cpsu-green hover:underline mt-2 inline-block">
            Start by checking your symptoms
          </router-link>
        </div>

        <div v-else class="space-y-4">
          <div
            v-for="record in symptomsStore.history.slice(0, 5)"
            :key="record.id"
            class="border-l-4 border-cpsu-yellow pl-4 py-2 hover:bg-gray-50"
          >
            <div class="flex justify-between items-start">
              <div>
                <p class="font-semibold text-gray-900">{{ record.predicted_disease }}</p>
                <p class="text-sm text-gray-600">
                  Confidence: {{ ((record.confidence_score ?? record.confidence ?? 0) * 100).toFixed(1) }}%
                </p>
                <p class="text-xs text-gray-500 mt-1">
                  {{ new Date(record.created_at).toLocaleString() }}
                </p>
              </div>
              <span class="px-3 py-1 bg-cpsu-green text-white text-xs rounded-full">
                {{ record.symptoms.length }} symptoms
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useSymptomsStore } from '@/stores/symptoms'

const router = useRouter()
const authStore = useAuthStore()
const symptomsStore = useSymptomsStore()

onMounted(async () => {
  await symptomsStore.fetchHistory()
})

async function handleLogout() {
  await authStore.logout()
  router.push('/login')
}
</script>
