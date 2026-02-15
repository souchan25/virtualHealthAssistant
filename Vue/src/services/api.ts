import axios from 'axios';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'https://virtualhealthassistant.onrender.com/api',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Token auto-injection interceptor
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('auth_token');  // ← FIX 1: Match the storage key
  if (token) {
    config.headers.Authorization = `Token ${token}`;  // ← FIX 2: Use 'Token' not 'Bearer'
  }
  return config;
});

export default api;
