<template>
  <div class="min-h-screen bg-gray-50">
    <!-- Navigation Header -->
    <nav class="bg-white shadow-sm border-b-2 border-cpsu-green">
      <div class="container mx-auto px-6 py-4">
        <div class="flex justify-between items-center">
          <router-link to="/dashboard" class="flex items-center space-x-4 text-cpsu-green">
            <img src="@/assets/images/cpsu-logo.png" alt="CPSU Logo" class="h-16 w-16 object-contain">
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
            <router-link to="/health-dashboard" class="text-cpsu-green font-semibold">Analytics</router-link>
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

      <h1 class="text-3xl font-bold text-cpsu-green mb-8">📊 Health Progress Dashboard</h1>

    <!-- Loading State -->
    <div v-if="loading" class="text-center py-12">
      <div class="inline-block animate-spin rounded-full h-12 w-12 border-4 border-cpsu-green border-t-transparent"></div>
      <p class="mt-4 text-gray-600">Loading health data...</p>
    </div>

    <div v-else>
      <!-- Summary Cards -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
        <div class="bg-white rounded-lg border-2 border-cpsu-green p-6">
          <div class="flex items-center justify-between mb-2">
            <span class="text-gray-600 font-semibold">Total Symptoms</span>
            <span class="text-3xl">📋</span>
          </div>
          <div class="text-3xl font-bold text-cpsu-green">{{ totalSymptoms }}</div>
        </div>

        <div class="bg-white rounded-lg border-2 border-blue-500 p-6">
          <div class="flex items-center justify-between mb-2">
            <span class="text-gray-600 font-semibold">Medication Adherence</span>
            <span class="text-3xl">💊</span>
          </div>
          <div class="text-3xl font-bold" :class="adherenceColor">
            {{ medicationAdherence }}%
          </div>
        </div>

        <div class="bg-white rounded-lg border-2 border-yellow-500 p-6">
          <div class="flex items-center justify-between mb-2">
            <span class="text-gray-600 font-semibold">Pending Follow-Ups</span>
            <span class="text-3xl">⏰</span>
          </div>
          <div class="text-3xl font-bold text-yellow-600">{{ pendingFollowups }}</div>
        </div>

        <div class="bg-white rounded-lg border-2 border-green-500 p-6">
          <div class="flex items-center justify-between mb-2">
            <span class="text-gray-600 font-semibold">Completed Follow-Ups</span>
            <span class="text-3xl">✅</span>
          </div>
          <div class="text-3xl font-bold text-green-600">{{ completedFollowups }}</div>
        </div>
      </div>

      <!-- Charts Row 1 -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        <!-- Symptom Trends Chart -->
        <div class="bg-white rounded-lg border-2 border-cpsu-green p-6">
          <h2 class="text-xl font-bold text-cpsu-green mb-4">📈 Symptom Reports Over Time</h2>
          <Line :data="symptomTrendsData" :options="lineChartOptions" />
        </div>

        <!-- Top Conditions Chart -->
        <div class="bg-white rounded-lg border-2 border-cpsu-green p-6">
          <h2 class="text-xl font-bold text-cpsu-green mb-4">🔝 Most Common Conditions</h2>
          <Bar :data="topConditionsData" :options="barChartOptions" />
        </div>
      </div>

      <!-- Charts Row 2 -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        <!-- Follow-Up Outcomes Chart -->
        <div class="bg-white rounded-lg border-2 border-cpsu-green p-6">
          <h2 class="text-xl font-bold text-cpsu-green mb-4">🎯 Follow-Up Outcomes</h2>
          <Doughnut :data="followupOutcomesData" :options="doughnutChartOptions" />
        </div>

        <!-- Medication Adherence Trend -->
        <div class="bg-white rounded-lg border-2 border-cpsu-green p-6">
          <h2 class="text-xl font-bold text-cpsu-green mb-4">💊 Medication Adherence Trend</h2>
          <Line :data="adherenceTrendData" :options="lineChartOptions" />
        </div>
      </div>

      <!-- Recent Activity Timeline -->
      <div class="bg-white rounded-lg border-2 border-cpsu-green p-6">
        <h2 class="text-xl font-bold text-cpsu-green mb-6">📅 Recent Health Activity</h2>
        
        <div v-if="recentActivity.length === 0" class="text-center py-8 text-gray-500">
          No recent activity
        </div>

        <div v-else class="space-y-4">
          <div
            v-for="(activity, index) in recentActivity"
            :key="index"
            class="flex items-start gap-4 p-4 rounded-lg"
            :class="getActivityBgClass(activity.type)"
          >
            <span class="text-3xl">{{ getActivityIcon(activity.type) }}</span>
            <div class="flex-1">
              <p class="font-semibold text-gray-800">{{ activity.title }}</p>
              <p class="text-sm text-gray-600">{{ activity.description }}</p>
              <p class="text-xs text-gray-500 mt-1">{{ formatDate(activity.date) }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { Line, Bar, Doughnut } from 'vue-chartjs'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend
} from 'chart.js'
import api from '@/services/api'

// Register Chart.js components
ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend
)

// State
const loading = ref(true)
const totalSymptoms = ref(0)
const medicationAdherence = ref(0)
const pendingFollowups = ref(0)
const completedFollowups = ref(0)
const recentActivity = ref<any[]>([])

// Chart data
const symptomTrendsData = ref({
  labels: [] as string[],
  datasets: [{
    label: 'Symptom Reports',
    data: [] as number[],
    borderColor: '#006B3F',
    backgroundColor: 'rgba(0, 107, 63, 0.1)',
    tension: 0.4
  }]
})

const topConditionsData = ref({
  labels: [] as string[],
  datasets: [{
    label: 'Count',
    data: [] as number[],
    backgroundColor: [
      '#006B3F',
      '#FFF44F',
      '#4CAF50',
      '#2196F3',
      '#FF9800'
    ]
  }]
})

const followupOutcomesData = ref({
  labels: ['Improved', 'Resolved', 'Same', 'Worse'],
  datasets: [{
    data: [0, 0, 0, 0],
    backgroundColor: [
      '#4CAF50',  // Improved - green
      '#2196F3',  // Resolved - blue
      '#FFC107',  // Same - yellow
      '#F44336'   // Worse - red
    ]
  }]
})

const adherenceTrendData = ref({
  labels: [] as string[],
  datasets: [{
    label: 'Adherence %',
    data: [] as number[],
    borderColor: '#2196F3',
    backgroundColor: 'rgba(33, 150, 243, 0.1)',
    tension: 0.4
  }]
})

// Chart options
const lineChartOptions = {
  responsive: true,
  maintainAspectRatio: true,
  plugins: {
    legend: {
      display: true
    }
  },
  scales: {
    y: {
      beginAtZero: true
    }
  }
}

const barChartOptions = {
  responsive: true,
  maintainAspectRatio: true,
  plugins: {
    legend: {
      display: false
    }
  },
  scales: {
    y: {
      beginAtZero: true,
      ticks: {
        stepSize: 1
      }
    }
  }
}

const doughnutChartOptions = {
  responsive: true,
  maintainAspectRatio: true,
  plugins: {
    legend: {
      position: 'bottom' as const
    }
  }
}

// Computed
const adherenceColor = computed(() => {
  if (medicationAdherence.value >= 90) return 'text-green-600'
  if (medicationAdherence.value >= 75) return 'text-yellow-600'
  return 'text-red-600'
})

// Methods
const formatDate = (dateStr: string) => {
  const date = new Date(dateStr)
  const now = new Date()
  const diffMs = now.getTime() - date.getTime()
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24))
  
  if (diffDays === 0) return 'Today'
  if (diffDays === 1) return 'Yesterday'
  if (diffDays < 7) return `${diffDays} days ago`
  
  return date.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric'
  })
}

const getActivityIcon = (type: string) => {
  const icons: Record<string, string> = {
    symptom: '📋',
    medication: '💊',
    followup: '✅',
    emergency: '🚨'
  }
  return icons[type] || '📌'
}

const getActivityBgClass = (type: string) => {
  const classes: Record<string, string> = {
    symptom: 'bg-blue-50',
    medication: 'bg-green-50',
    followup: 'bg-yellow-50',
    emergency: 'bg-red-50'
  }
  return classes[type] || 'bg-gray-50'
}

const loadDashboardData = async () => {
  loading.value = true
  
  try {
    // Load all health data
    const [symptomsRes, medicationsRes, followupsRes] = await Promise.all([
      api.get('/symptoms/'),
      api.get('/medications/adherence/'),
      api.get('/followups/')
    ])

    // Summary stats
    totalSymptoms.value = symptomsRes.data.length
    medicationAdherence.value = Math.round(medicationsRes.data.overall_adherence_rate || 0)
    
    const followups = followupsRes.data
    pendingFollowups.value = followups.filter((f: any) => f.status === 'pending' || f.status === 'overdue').length
    completedFollowups.value = followups.filter((f: any) => f.status === 'completed').length

    // Symptom trends (last 30 days)
    const symptomsByDate: Record<string, number> = {}
    const last30Days = Array.from({ length: 30 }, (_, i) => {
      const d = new Date()
      d.setDate(d.getDate() - (29 - i))
      return d.toISOString().split('T')[0]
    })
    
    last30Days.forEach(date => { symptomsByDate[date] = 0 })
    
    symptomsRes.data.forEach((s: any) => {
      const date = s.created_at.split('T')[0]
      if (symptomsByDate[date] !== undefined) {
        symptomsByDate[date]++
      }
    })
    
    symptomTrendsData.value.labels = last30Days.map(d => {
      const date = new Date(d)
      return `${date.getMonth() + 1}/${date.getDate()}`
    })
    symptomTrendsData.value.datasets[0].data = last30Days.map(d => symptomsByDate[d])

    // Top conditions
    const conditionCounts: Record<string, number> = {}
    symptomsRes.data.forEach((s: any) => {
      const disease = s.predicted_disease || 'Unknown'
      conditionCounts[disease] = (conditionCounts[disease] || 0) + 1
    })
    
    const topConditions = Object.entries(conditionCounts)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
    
    topConditionsData.value.labels = topConditions.map(([name]) => name)
    topConditionsData.value.datasets[0].data = topConditions.map(([, count]) => count)

    // Follow-up outcomes
    const outcomeCounts = { improved: 0, resolved: 0, same: 0, worse: 0 }
    followups.forEach((f: any) => {
      if (f.outcome && outcomeCounts[f.outcome as keyof typeof outcomeCounts] !== undefined) {
        outcomeCounts[f.outcome as keyof typeof outcomeCounts]++
      }
    })
    followupOutcomesData.value.datasets[0].data = [
      outcomeCounts.improved,
      outcomeCounts.resolved,
      outcomeCounts.same,
      outcomeCounts.worse
    ]

    // Adherence trend (last 7 days)
    const last7Days = Array.from({ length: 7 }, (_, i) => {
      const d = new Date()
      d.setDate(d.getDate() - (6 - i))
      return d.toISOString().split('T')[0]
    })
    
    adherenceTrendData.value.labels = last7Days.map(d => {
      const date = new Date(d)
      return `${date.getMonth() + 1}/${date.getDate()}`
    })
    
    // Simplified adherence trend (use overall rate for all days)
    adherenceTrendData.value.datasets[0].data = last7Days.map(() => medicationAdherence.value)

    // Recent activity (combine all sources)
    const activities: any[] = []
    
    symptomsRes.data.slice(0, 5).forEach((s: any) => {
      activities.push({
        type: 'symptom',
        title: 'Symptom Report',
        description: `Reported ${s.predicted_disease}`,
        date: s.created_at
      })
    })
    
    followups.slice(0, 5).forEach((f: any) => {
      if (f.status === 'completed') {
        activities.push({
          type: 'followup',
          title: 'Follow-Up Completed',
          description: `${f.symptom_disease} - ${f.outcome}`,
          date: f.response_date
        })
      }
    })
    
    // Sort by date and take top 10
    recentActivity.value = activities
      .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
      .slice(0, 10)

  } catch (error) {
    console.error('Error loading dashboard data:', error)
  } finally {
    loading.value = false
  }
}

// Lifecycle
onMounted(() => {
  loadDashboardData()
})
</script>
