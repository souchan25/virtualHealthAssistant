<template>
  <div class="min-h-screen bg-gradient-to-br from-cpsu-green to-cpsu-green-dark">
    <!-- Hero Section -->
    <nav class="container mx-auto px-6 py-6">
      <div class="flex justify-between items-center">
        <div class="flex items-center space-x-4 text-white">
          <img src="@/assets/images/cpsu-logo.png" alt="CPSU Logo" class="h-16 w-16 object-contain">
          <div>
            <h1 class="text-2xl font-heading font-bold">CPSU Health Assistant</h1>
            <p class="text-sm text-cpsu-yellow">Mighty Hornbills</p>
          </div>
        </div>
        <div class="space-x-4">
          <router-link to="/login" class="btn-secondary">Login</router-link>
          <router-link to="/register" class="bg-white text-cpsu-green font-semibold px-6 py-2.5 rounded-lg hover:bg-gray-100 transition-colors duration-200">Register</router-link>
        </div>
      </div>
    </nav>

    <div class="container mx-auto px-6 py-20">
      <div class="max-w-4xl mx-auto text-center text-white">
        <h2 class="text-5xl font-heading font-bold mb-6">
          Your AI-Powered Health Companion
        </h2>
        <p class="text-xl mb-12 text-gray-100">
          Get instant health insights with 90-98% accuracy using our hybrid ML + LLM prediction system
        </p>
        
        <div class="flex justify-center gap-4 mb-16">
          <router-link to="/register" class="btn-secondary text-lg px-8 py-4">
            Get Started Free
          </router-link>
          <router-link to="/login" class="btn-outline text-lg px-8 py-4 !text-white !border-white hover:!bg-white hover:!text-cpsu-green">
            Sign In
          </router-link>
        </div>

        <!-- Features Grid -->
        <div class="grid md:grid-cols-3 gap-8 mt-16">
          <div class="bg-white/10 backdrop-blur-sm rounded-lg p-6">
            <div class="text-4xl mb-4">🤖</div>
            <h3 class="text-xl font-bold mb-2">AI-Powered</h3>
            <p class="text-gray-200">Hybrid ML + LLM system for accurate disease prediction</p>
          </div>
          
          <div class="bg-white/10 backdrop-blur-sm rounded-lg p-6">
            <div class="text-4xl mb-4">💬</div>
            <h3 class="text-xl font-bold mb-2">Smart Chat</h3>
            <p class="text-gray-200">Interactive chatbot with Rasa integration</p>
          </div>
          
          <div class="bg-white/10 backdrop-blur-sm rounded-lg p-6">
            <div class="text-4xl mb-4">📊</div>
            <h3 class="text-xl font-bold mb-2">Track History</h3>
            <p class="text-gray-200">Monitor your health records and get insights</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
// Home page - landing for non-authenticated users
</script>
