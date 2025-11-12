<template>
  <div class="min-h-screen bg-gray-50 flex flex-col">
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
            <router-link to="/chat" class="text-cpsu-green font-semibold">Chat</router-link>
            <router-link to="/history" class="text-gray-700 hover:text-cpsu-green">History</router-link>
            <router-link to="/profile" class="text-gray-700 hover:text-cpsu-green">Profile</router-link>
          </div>
        </div>
      </div>
    </nav>

    <!-- Chat Header -->
    <div class="bg-cpsu-green text-white px-6 py-4">
      <div class="container mx-auto max-w-4xl flex justify-between items-center">
        <h2 class="text-2xl font-heading font-bold">💬 Health Chat Assistant</h2>
        <button
          v-if="chatStore.messages.length > 0"
          @click="clearChat"
          class="text-cpsu-yellow hover:text-white px-4 py-2 border border-cpsu-yellow rounded-lg transition-colors hover:bg-cpsu-yellow hover:text-cpsu-green"
        >
          🗑️ Clear Chat
        </button>
      </div>
    </div>

    <!-- Chat Container -->
    <div class="flex-1 container mx-auto px-6 py-8 max-w-4xl flex flex-col">
      <!-- Messages Area -->
      <div class="flex-1 card mb-4 overflow-hidden flex flex-col">
        <div class="flex-1 overflow-y-auto p-4 space-y-4" ref="messagesContainer">
          <!-- Welcome Message -->
          <div v-if="chatStore.messages.length === 0" class="text-center py-12">
            <div class="text-6xl mb-4">🤖</div>
            <h3 class="text-xl font-bold text-gray-900 mb-2">Welcome to Health Chat!</h3>
            <p class="text-gray-600">I'm here to help with your health questions. How are you feeling today?</p>
          </div>

          <!-- Chat Messages -->
          <div
            v-for="message in chatStore.messages"
            :key="message.id"
            :class="['flex', message.sender === 'user' ? 'justify-end' : 'justify-start']"
          >
            <div
              :class="[
                'max-w-[70%] rounded-lg px-4 py-3',
                message.sender === 'user'
                  ? 'bg-cpsu-yellow text-cpsu-green'
                  : message.isError
                  ? 'bg-red-100 text-red-800'
                  : 'bg-white border-2 border-gray-200 text-gray-900'
              ]"
            >
              <p class="whitespace-pre-wrap">{{ message.content }}</p>
              <p class="text-xs mt-1 opacity-70">
                {{ new Date(message.timestamp).toLocaleTimeString() }}
              </p>
            </div>
          </div>

          <!-- Loading Indicator -->
          <div v-if="chatStore.loading" class="flex justify-start">
            <div class="bg-white border-2 border-gray-200 rounded-lg px-4 py-3">
              <div class="flex items-center space-x-2">
                <div class="w-2 h-2 bg-cpsu-green rounded-full animate-bounce"></div>
                <div class="w-2 h-2 bg-cpsu-green rounded-full animate-bounce" style="animation-delay: 0.1s"></div>
                <div class="w-2 h-2 bg-cpsu-green rounded-full animate-bounce" style="animation-delay: 0.2s"></div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Input Area -->
      <div class="card">
        <form @submit.prevent="sendMessage" class="flex gap-3">
          <input
            v-model="messageInput"
            type="text"
            placeholder="Type your message..."
            class="input-field flex-1"
            :disabled="chatStore.loading"
          />
          <button
            type="submit"
            :disabled="!messageInput.trim() || chatStore.loading"
            class="btn-primary disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Send
          </button>
        </form>
        
        <!-- Quick Actions -->
        <div class="mt-4 flex flex-wrap gap-2">
          <button
            v-for="action in quickActions"
            :key="action"
            @click="sendQuickMessage(action)"
            :disabled="chatStore.loading"
            class="text-sm px-3 py-1 border-2 border-cpsu-green text-cpsu-green rounded-lg hover:bg-cpsu-green hover:text-white transition-colors disabled:opacity-50"
          >
            {{ action }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, nextTick, watch } from 'vue'
import { useChatStore } from '@/stores/chat'

const chatStore = useChatStore()
const messageInput = ref('')
const messagesContainer = ref<HTMLElement | null>(null)

const quickActions = [
  'I have a headache',
  'I feel tired',
  'I have fever',
  'Tell me about common cold'
]

async function sendMessage() {
  if (!messageInput.value.trim()) return
  
  const message = messageInput.value
  messageInput.value = ''
  
  await chatStore.sendMessage(message)
  scrollToBottom()
}

function sendQuickMessage(message: string) {
  messageInput.value = message
  sendMessage()
}

async function clearChat() {
  if (confirm('Are you sure you want to clear this conversation?')) {
    await chatStore.endSession()
    chatStore.clearMessages()
  }
}

function scrollToBottom() {
  nextTick(() => {
    if (messagesContainer.value) {
      messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight
    }
  })
}

// Auto-scroll when new messages arrive
watch(() => chatStore.messages.length, () => {
  scrollToBottom()
})
</script>
