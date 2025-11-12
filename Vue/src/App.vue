<template>
  <div id="app" class="min-h-screen">
    <RouterView />
  </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { RouterView } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()

onMounted(() => {
  // Check if user is already logged in (token in localStorage)
  authStore.checkAuth()
})
</script>
