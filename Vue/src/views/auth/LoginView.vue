<template>
  <div class="min-h-screen bg-gray-50 flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
    <div class="max-w-md w-full space-y-8">
      <!-- Logo and Header -->
      <div class="text-center">
        <h2 class="text-4xl font-heading font-bold text-cpsu-green">CPSU Health Assistant</h2>
        <p class="mt-2 text-sm text-gray-600">Sign in to your account</p>
      </div>

      <!-- Login Form -->
      <div class="card">
        <form @submit.prevent="handleLogin" class="space-y-6">
          <!-- Error Message -->
          <div v-if="authStore.error" class="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-lg">
            {{ authStore.error }}
          </div>

          <!-- School ID -->
          <div>
            <label for="school-id" class="block text-sm font-medium text-gray-700 mb-2">
              School ID
            </label>
            <input
              id="school-id"
              v-model="credentials.school_id"
              type="text"
              required
              class="input-field"
              :class="{ 'input-error': authStore.error }"
              placeholder="Enter your school ID"
            />
          </div>

          <!-- Password -->
          <div>
            <label for="password" class="block text-sm font-medium text-gray-700 mb-2">
              Password
            </label>
            <input
              id="password"
              v-model="credentials.password"
              type="password"
              required
              class="input-field"
              :class="{ 'input-error': authStore.error }"
              placeholder="Enter your password"
            />
          </div>

          <!-- Submit Button -->
          <button
            type="submit"
            :disabled="authStore.loading"
            class="w-full btn-primary"
          >
            <span v-if="authStore.loading">Signing in...</span>
            <span v-else>Sign In</span>
          </button>

          <!-- Register Link -->
          <div class="text-center text-sm">
            <span class="text-gray-600">Don't have an account?</span>
            <router-link to="/register" class="ml-1 text-cpsu-green font-semibold hover:text-cpsu-green-dark">
              Register here
            </router-link>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

const credentials = ref({
  school_id: '',
  password: ''
})

async function handleLogin() {
  const success = await authStore.login(credentials.value)
  
  if (success) {
    // Redirect based on user role
    const user = authStore.user
    if (user?.role === 'staff') {
      router.push('/staff')
    } else {
      const redirect = route.query.redirect as string || '/dashboard'
      router.push(redirect)
    }
  }
}
</script>
