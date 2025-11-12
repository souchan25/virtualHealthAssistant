<template>
  <div class="min-h-screen bg-gray-50 flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
    <div class="max-w-md w-full space-y-8">
      <!-- Logo and Header -->
      <div class="text-center">
        <h2 class="text-4xl font-heading font-bold text-cpsu-green">CPSU Health Assistant</h2>
        <p class="mt-2 text-sm text-gray-600">Create your account</p>
      </div>

      <!-- Registration Form -->
      <div class="card">
        <form @submit.prevent="handleRegister" class="space-y-6">
          <!-- Error Message -->
          <div v-if="authStore.error" class="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-lg text-sm">
            {{ authStore.error }}
          </div>

          <!-- School ID -->
          <div>
            <label for="school-id" class="block text-sm font-medium text-gray-700 mb-2">
              School ID *
            </label>
            <input
              id="school-id"
              v-model="formData.school_id"
              type="text"
              required
              class="input-field"
              placeholder="e.g., 2024-001"
            />
          </div>

          <!-- Name -->
          <div>
            <label for="name" class="block text-sm font-medium text-gray-700 mb-2">
              Full Name *
            </label>
            <input
              id="name"
              v-model="formData.name"
              type="text"
              required
              class="input-field"
              placeholder="Juan Dela Cruz"
            />
          </div>

          <!-- Department -->
          <div>
            <label for="department" class="block text-sm font-medium text-gray-700 mb-2">
              Department
            </label>
            <select
              id="department"
              v-model="formData.department"
              class="input-field"
            >
              <option value="">Select department</option>
              <option>College of Agriculture and Forestry</option>
              <option>College of Teacher Education</option>
              <option>College of Arts and Sciences</option>
              <option>College of Hospitality Management</option>
              <option>College of Engineering</option>
              <option>College of Computer Studies</option>
              <option>College of Criminal Justice Education</option>
            </select>
          </div>

          <!-- Password -->
          <div>
            <label for="password" class="block text-sm font-medium text-gray-700 mb-2">
              Password *
            </label>
            <input
              id="password"
              v-model="formData.password"
              type="password"
              required
              minlength="6"
              class="input-field"
              placeholder="At least 6 characters"
            />
          </div>

          <!-- Confirm Password -->
          <div>
            <label for="confirm-password" class="block text-sm font-medium text-gray-700 mb-2">
              Confirm Password *
            </label>
            <input
              id="confirm-password"
              v-model="confirmPassword"
              type="password"
              required
              class="input-field"
              :class="{ 'input-error': confirmPassword && confirmPassword !== formData.password }"
              placeholder="Re-enter password"
            />
            <p v-if="confirmPassword && confirmPassword !== formData.password" class="mt-1 text-sm text-red-600">
              Passwords do not match
            </p>
          </div>

          <!-- Data Consent -->
          <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
            <label class="flex items-start cursor-pointer">
              <input
                id="data-consent"
                v-model="formData.data_consent_given"
                type="checkbox"
                required
                class="mt-1 mr-3 h-4 w-4 text-cpsu-green border-gray-300 rounded focus:ring-cpsu-green"
              />
              <span class="text-sm text-gray-700">
                <strong class="text-gray-900">I consent to health data storage *</strong>
                <br />
                By checking this box, you agree to allow CPSU Health Assistant to store your health information 
                (symptoms, predictions, chat history) for providing personalized health recommendations and insights.
                You can revoke this consent anytime from your profile settings.
              </span>
            </label>
          </div>

          <!-- Submit Button -->
          <button
            type="submit"
            :disabled="authStore.loading || (!!confirmPassword && confirmPassword !== formData.password)"
            class="w-full btn-primary disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <span v-if="authStore.loading">Creating account...</span>
            <span v-else>Create Account</span>
          </button>

          <!-- Login Link -->
          <div class="text-center text-sm">
            <span class="text-gray-600">Already have an account?</span>
            <router-link to="/login" class="ml-1 text-cpsu-green font-semibold hover:text-cpsu-green-dark">
              Sign in here
            </router-link>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const formData = ref({
  school_id: '',
  name: '',
  password: '',
  department: '',
  data_consent_given: false
})

const confirmPassword = ref('')

async function handleRegister() {
  if (confirmPassword.value !== formData.value.password) {
    return
  }

  // Include password_confirm in payload for Django validation
  const registrationData = {
    ...formData.value,
    password_confirm: confirmPassword.value
  }

  const success = await authStore.register(registrationData)
  
  if (success) {
    router.push('/dashboard')
  }
}
</script>
