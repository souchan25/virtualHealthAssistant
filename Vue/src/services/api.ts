const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'https://virtualhealthassistant.onrender.com/api',
  timeout: 60000,
  headers: {
    'Content-Type': 'application/json',
  },
});