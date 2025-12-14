<template>
  <div class="min-h-screen bg-gray-50 flex flex-col">
    <!-- Navigation Header -->
    <nav class="bg-white shadow-sm border-b-2 border-cpsu-green">
      <div class="container mx-auto px-6 py-4">
        <div class="flex justify-between items-center">
          <router-link to="/dashboard" class="flex items-center space-x-4 text-cpsu-green">
            <img src="@/assets/images/cpsu-logo.png" alt="CPSU Logo" class="h-12 w-12 object-contain">
            <div>
              <h1 class="text-2xl font-heading font-bold">CPSU Health Assistant</h1>
              <p class="text-sm text-gray-600">Central Philippines State University</p>
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
    <div class="bg-gradient-to-r from-cpsu-green to-cpsu-green-dark text-white px-6 py-4 shadow-md">
      <div class="container mx-auto flex justify-between items-center">
        <div class="flex items-center space-x-3">
          <div class="w-12 h-12 bg-cpsu-yellow rounded-full flex items-center justify-center text-2xl">
            🤖
          </div>
          <div>
            <h2 class="text-2xl font-heading font-bold">Health Chat Assistant</h2>
            <p class="text-sm text-cpsu-yellow">AI-powered health support</p>
          </div>
        </div>
        <button
          v-if="chatStore.messages.length > 0"
          @click="clearChat"
          class="text-white bg-white/20 hover:bg-white hover:text-cpsu-green px-4 py-2 rounded-lg transition-all font-semibold flex items-center space-x-2"
        >
          <span>🗑️</span>
          <span>Clear Chat</span>
        </button>
      </div>
    </div>

    <!-- Chat Container - Full Width -->
    <div class="flex-1 flex flex-col bg-gray-100">
      <!-- Messages Area - Full Width -->
      <div class="flex-1 overflow-y-auto py-6" ref="messagesContainer">
        <div class="container mx-auto px-6 max-w-7xl">
          <!-- Welcome Message -->
          <div v-if="chatStore.messages.length === 0" class="text-center py-20">
            <div class="w-24 h-24 bg-gradient-to-br from-cpsu-green to-cpsu-green-dark rounded-full mx-auto mb-6 flex items-center justify-center text-5xl shadow-lg">
              🤖
            </div>
            <h3 class="text-3xl font-bold text-gray-900 mb-3">Welcome to Health Chat!</h3>
            <p class="text-gray-600 text-lg mb-8">I'm your AI health assistant. How can I help you today?</p>
            <div class="flex flex-wrap justify-center gap-3">
              <button
                v-for="action in quickActions"
                :key="action"
                @click="sendQuickMessage(action)"
                class="px-6 py-3 bg-white border-2 border-cpsu-green text-cpsu-green rounded-lg hover:bg-cpsu-green hover:text-white transition-all shadow-sm hover:shadow-md font-semibold"
              >
                {{ action }}
              </button>
            </div>
          </div>

          <!-- Chat Messages -->
          <div class="space-y-6">
            <div
              v-for="message in chatStore.messages"
              :key="message.id"
              :class="['flex', message.sender === 'user' ? 'justify-end' : 'justify-start']"
            >
              <!-- AI Message with Avatar -->
              <div v-if="message.sender === 'bot'" class="flex items-start space-x-3 max-w-4xl">
                <!-- AI Avatar -->
                <div class="flex-shrink-0 w-10 h-10 bg-gradient-to-br from-cpsu-green to-cpsu-green-dark rounded-full flex items-center justify-center text-white text-xl shadow-md">
                  🤖
                </div>
                
                <!-- AI Message Content -->
                <div class="flex-1">
                  <div class="bg-white rounded-2xl rounded-tl-none shadow-md border border-gray-200 overflow-hidden">
                    <div class="p-5" v-html="formatBotMessage(message.content)"></div>
                  </div>
                  <p class="text-xs text-gray-500 mt-2 ml-2">
                    {{ new Date(message.timestamp).toLocaleTimeString() }}
                  </p>
                </div>
              </div>

              <!-- User Message -->
              <div v-else class="flex items-start space-x-3 max-w-2xl">
                <div class="flex-1">
                  <div
                    :class="[
                      'rounded-2xl rounded-tr-none shadow-md px-5 py-3',
                      message.isError
                        ? 'bg-red-500 text-white'
                        : 'bg-cpsu-yellow text-cpsu-green'
                    ]"
                  >
                    <p class="whitespace-pre-wrap font-medium">{{ message.content }}</p>
                  </div>
                  <p class="text-xs text-gray-500 mt-2 mr-2 text-right">
                    {{ new Date(message.timestamp).toLocaleTimeString() }}
                  </p>
                </div>
                
                <!-- User Avatar -->
                <div class="flex-shrink-0 w-10 h-10 bg-cpsu-yellow rounded-full flex items-center justify-center text-cpsu-green text-xl font-bold shadow-md">
                  👤
                </div>
              </div>
            </div>
          </div>

          <!-- Loading Indicator -->
          <div v-if="chatStore.loading" class="flex justify-start">
            <div class="flex items-start space-x-3 max-w-4xl">
              <div class="flex-shrink-0 w-10 h-10 bg-gradient-to-br from-cpsu-green to-cpsu-green-dark rounded-full flex items-center justify-center text-white text-xl shadow-md">
                🤖
              </div>
              <div class="bg-white rounded-2xl rounded-tl-none shadow-md border border-gray-200 px-5 py-4">
                <div class="flex items-center space-x-2">
                  <div class="w-2.5 h-2.5 bg-cpsu-green rounded-full animate-bounce"></div>
                  <div class="w-2.5 h-2.5 bg-cpsu-green rounded-full animate-bounce" style="animation-delay: 0.15s"></div>
                  <div class="w-2.5 h-2.5 bg-cpsu-green rounded-full animate-bounce" style="animation-delay: 0.3s"></div>
                  <span class="text-gray-600 ml-2">Thinking...</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Input Area - Full Width Bottom -->
      <div class="bg-white border-t-2 border-gray-200 shadow-lg">
        <div class="container mx-auto px-6 py-4 max-w-7xl">
          <form @submit.prevent="sendMessage" class="flex gap-3 items-center">
            <input
              v-model="messageInput"
              type="text"
              placeholder="Type your health question here..."
              class="flex-1 px-5 py-3 border-2 border-gray-300 rounded-full focus:border-cpsu-green focus:ring-2 focus:ring-cpsu-green/20 outline-none transition-all text-gray-900 text-lg"
              :disabled="chatStore.loading"
            />
            <button
              type="submit"
              :disabled="!messageInput.trim() || chatStore.loading"
              class="bg-cpsu-green text-white px-8 py-3 rounded-full font-bold text-lg hover:bg-cpsu-green-dark transition-all disabled:opacity-50 disabled:cursor-not-allowed shadow-md hover:shadow-lg flex items-center space-x-2"
            >
              <span>Send</span>
              <span>📤</span>
            </button>
          </form>
          
          <!-- Quick Actions -->
          <div v-if="chatStore.messages.length > 0" class="mt-4 flex flex-wrap gap-2">
            <span class="text-sm text-gray-600 font-medium mr-2">Quick questions:</span>
            <button
              v-for="action in quickActions"
              :key="action"
              @click="sendQuickMessage(action)"
              :disabled="chatStore.loading"
              class="text-sm px-4 py-2 border-2 border-cpsu-green/30 text-cpsu-green rounded-full hover:bg-cpsu-green hover:text-white transition-all disabled:opacity-50 font-medium"
            >
              {{ action }}
            </button>
          </div>
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

function formatBotMessage(content: string): string {
  // Parse the structured health response
  let html = content

  // Format diagnosis section
  html = html.replace(/🏥\s*\*\*Diagnosis Analysis\*\*/g, '<div class="mb-6"><div class="flex items-center space-x-2 mb-4"><span class="text-3xl">🏥</span><h3 class="text-xl font-bold text-cpsu-green">Diagnosis Analysis</h3></div>')
  
  // Format condition and confidence
  html = html.replace(/\*\*Condition\*\*:\s*([^\n]+)/g, '<div class="bg-cpsu-green/10 rounded-lg p-4 mb-3"><div class="flex items-center justify-between"><div><span class="text-sm text-gray-600">Condition</span><div class="text-2xl font-bold text-cpsu-green mt-1">$1</div></div>')
  html = html.replace(/\*\*Confidence\*\*:\s*(\d+)%\s*✅\s*\(AI Validated\)/g, '<div class="text-right"><span class="text-sm text-gray-600">Confidence</span><div class="text-2xl font-bold text-cpsu-green mt-1">$1%</div><span class="text-xs bg-green-100 text-green-800 px-2 py-1 rounded-full mt-1 inline-block">✅ AI Validated</span></div></div></div>')
  
  // Format description
  html = html.replace(/\*\*Description\*\*:\s*([^\n]+(?:\n(?!\*\*)[^\n]+)*)/g, '<div class="bg-gray-50 rounded-lg p-4 mb-4"><div class="text-sm text-gray-600 mb-2 font-semibold">Description</div><p class="text-gray-700 leading-relaxed">$1</p></div>')
  
  // Format precautions
  html = html.replace(/\*\*Recommended Precautions\*\*:\s*/g, '<div class="mb-4"><div class="text-sm font-semibold text-gray-800 mb-3 flex items-center"><span class="text-xl mr-2">💊</span>Recommended Precautions</div><ul class="space-y-2">')
  html = html.replace(/(\d+)\.\s*([^\n]+)/g, '<li class="flex items-start space-x-3"><span class="flex-shrink-0 w-6 h-6 bg-cpsu-green text-white rounded-full flex items-center justify-center text-xs font-bold">$1</span><span class="text-gray-700 flex-1">$2</span></li>')
  
  // Format important notice
  html = html.replace(/⚕️\s*\*\*Important\*\*:\s*([^\n]+)/g, '</ul></div><div class="bg-yellow-50 border-l-4 border-yellow-400 p-4 mb-4"><div class="flex items-start space-x-2"><span class="text-xl">⚕️</span><div><div class="font-semibold text-yellow-800 mb-1">Important Notice</div><p class="text-sm text-yellow-700">$1</p></div></div></div>')
  
  // Format other possibilities
  html = html.replace(/\*\*Other Possibilities\*\*:\s*/g, '<div class="border-t border-gray-200 pt-4"><div class="text-sm font-semibold text-gray-700 mb-3">Other Possibilities</div><ul class="space-y-2">')
  html = html.replace(/•\s*([^\(]+)\((\d+)%\)/g, '<li class="flex items-center justify-between text-sm"><span class="text-gray-700">• $1</span><span class="bg-gray-200 text-gray-700 px-3 py-1 rounded-full text-xs font-semibold">$2%</span></li>')
  
  // Close any open divs
  if (html.includes('<ul class="space-y-2">') && !html.includes('</ul></div></div>')) {
    html += '</ul></div></div>'
  }
  
  // Format bold text that wasn't caught
  html = html.replace(/\*\*([^*]+)\*\*/g, '<strong class="font-semibold text-gray-800">$1</strong>')
  
  // Format line breaks
  html = html.replace(/\n/g, '<br>')
  
  return html
}

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
