# Worker Timeout Fix - Visual Comparison

## Overview
This document provides a visual before/after comparison of all changes made to fix the worker timeout issues.

---

## 1. Gunicorn Configuration Changes

### render.yaml

```diff
  services:
    - type: web
      name: cpsu-health-assistant-backend
      env: python
      region: oregon
      plan: free
      branch: main
      buildCommand: ./render_build.sh
-     startCommand: cd Django && gunicorn health_assistant.wsgi:application --bind 0.0.0.0:$PORT --workers 2
+     startCommand: cd Django && gunicorn health_assistant.wsgi:application --bind 0.0.0.0:$PORT --workers 1 --timeout 120 --graceful-timeout 30
```

**Key Changes:**
- 🔧 Workers: `2 → 1` (50% reduction for memory efficiency)
- ⏱️ Timeout: `30s (default) → 120s` (4x increase)
- 🛑 Graceful timeout: `Added 30s` (allows clean shutdown)

### Procfile

```diff
- web: cd Django && gunicorn health_assistant.wsgi:application --bind 0.0.0.0:$PORT --workers 3
+ web: cd Django && gunicorn health_assistant.wsgi:application --bind 0.0.0.0:$PORT --workers 1 --timeout 120 --graceful-timeout 30
  release: cd Django && python manage.py migrate --noinput
```

**Key Changes:**
- 🔧 Workers: `3 → 1` (67% reduction for memory efficiency)
- ⏱️ Timeout: `30s (default) → 120s` (4x increase)
- 🛑 Graceful timeout: `Added 30s` (allows clean shutdown)

---

## 2. LLM Service Timeout Configurations

### Django/clinic/llm_service.py

#### A. Gemini Client Initialization

```diff
  # Initialize Gemini with new API
  self.gemini_client = None
  
  if GEMINI_AVAILABLE and settings.GEMINI_API_KEY:
      try:
-         self.gemini_client = genai.Client(api_key=settings.GEMINI_API_KEY)
+         self.gemini_client = genai.Client(
+             api_key=settings.GEMINI_API_KEY,
+             http_options={'timeout': 30}  # Add 30 second timeout
+         )
          self.logger.info("Gemini AI initialized successfully (new API)")
```

**Impact:** All Gemini API calls (2 locations) now timeout after 30s

#### B. Groq Client Initialization

```diff
  # Initialize Groq (direct API, not OpenRouter)
  self.groq_client = None
  if OPENAI_AVAILABLE and hasattr(settings, 'GROQ_API_KEY') and settings.GROQ_API_KEY:
      try:
          self.groq_client = OpenAI(
              api_key=settings.GROQ_API_KEY,
              base_url="https://api.groq.com/openai/v1",
+             timeout=30.0  # Add 30 second timeout
          )
          self.logger.info("Groq API initialized successfully")
```

**Impact:** All Groq API calls (3 locations) now timeout after 30s

#### C. Cohere Client Initialization

```diff
  # Initialize Cohere
  if COHERE_AVAILABLE and settings.COHERE_API_KEY:
      try:
-         self.cohere_client = cohere.Client(settings.COHERE_API_KEY)
+         self.cohere_client = cohere.Client(settings.COHERE_API_KEY, timeout=30)
          self.logger.info("Cohere AI initialized successfully")
```

**Impact:** All Cohere API calls (2 locations) now timeout after 30s

#### D. OpenRouter (Already Configured) ✅

```python
# Lines 208, 317, 516 - Already have timeout=30
response = requests.post(
    url="https://openrouter.ai/api/v1/chat/completions",
    headers={...},
    json=payload,
    timeout=30  # Already present
)
```

**Status:** No changes needed - already properly configured

---

## 3. Enhanced Error Handling

### Django/clinic/views.py

#### A. Import Statement

```diff
  from datetime import timedelta
  import uuid
  import logging
+ import requests
```

#### B. send_chat_message Error Handling

```diff
  try:
      ai_generator = AIInsightGenerator()
      response_text = ai_generator.generate_chat_response(
          message=message,
          context={'language': language, 'session_id': str(session_id), 'rasa_failed': True}
      )
      # Ensure response is not None or empty
      if not response_text or not response_text.strip():
          raise ValueError("LLM returned empty response")
+ except requests.exceptions.Timeout as timeout_error:
+     logger.error(f"LLM call timed out: {timeout_error}")
+     response_text = "I apologize for the delay. The system is experiencing high load. Please try again in a moment, or consult with our clinic staff for immediate assistance."
  except Exception as llm_error:
      logger.error(f"LLM fallback failed: {llm_error}")
      # Ultimate fallback - hardcoded response
      response_text = "Thank you for your message. I'm experiencing technical difficulties. Please consult with our clinic staff for proper evaluation of your symptoms."
```

**Changes:**
- ➕ Added specific `requests.exceptions.Timeout` handler
- 💬 Provides helpful user message for timeout scenarios
- 🔄 Maintains generic fallback for other errors

---

## 4. Timeout Configuration Summary

| Component | Location | Timeout Before | Timeout After | Status |
|-----------|----------|----------------|---------------|--------|
| **Gunicorn (Render)** | render.yaml | 30s (default) | 120s | ✅ Updated |
| **Gunicorn (Heroku)** | Procfile | 30s (default) | 120s | ✅ Updated |
| **Groq API** | llm_service.py:84 | None (infinite) | 30s | ✅ Updated |
| **Gemini API** | llm_service.py:60 | None (infinite) | 30s | ✅ Updated |
| **Cohere API** | llm_service.py:96 | None (infinite) | 30s | ✅ Updated |
| **OpenRouter API** | llm_service.py:208,317,516 | 30s | 30s | ✅ Already OK |
| **Error Handling** | views.py:399 | Generic | Specific | ✅ Updated |

---

## 5. Worker Configuration Summary

| Platform | Before | After | Change | Memory Impact |
|----------|--------|-------|--------|---------------|
| **Render** | 2 workers | 1 worker | -50% | ~50% less memory |
| **Heroku/Other** | 3 workers | 1 worker | -67% | ~67% less memory |

**Rationale:** Free tier has limited memory. Single worker with 120s timeout is better than multiple workers timing out at 30s.

---

## 6. Error Flow Comparison

### Before

```
User Message → LLM API Call (no timeout)
                    ↓
              Hangs indefinitely (>30s)
                    ↓
              Gunicorn timeout (30s)
                    ↓
              WORKER TIMEOUT → SIGKILL
                    ↓
              Generic error to user
```

### After

```
User Message → LLM API Call (timeout=30)
                    ↓
              Times out at 30s (if slow)
                    ↓
              Caught by requests.exceptions.Timeout
                    ↓
              Helpful error message to user
                    ↓
              Gunicorn continues (within 120s budget)
```

---

## 7. Files Changed Summary

| File | Lines Changed | Type | Critical |
|------|---------------|------|----------|
| `render.yaml` | 1 line | Config | ⚠️ Yes |
| `Procfile` | 1 line | Config | ⚠️ Yes |
| `Django/clinic/llm_service.py` | 3 additions | Code | ⚠️ Yes |
| `Django/clinic/views.py` | 4 additions | Code | ⚠️ Yes |
| **Total** | **9 lines** | **Mixed** | **4 files** |

---

## 8. Testing Checklist

- [x] Syntax validation passed for Python files
- [x] All timeout configurations verified (6 locations)
- [x] Error handling updated for timeout exceptions
- [x] Gunicorn configurations standardized across platforms
- [ ] Manual testing in production (to be done post-deployment)
- [ ] Monitor logs for timeout errors (to be done post-deployment)
- [ ] Verify memory usage improvement (to be done post-deployment)

---

## 9. Deployment Impact

### Immediate Effects
✅ Workers won't be killed by SIGKILL after 30s
✅ LLM API calls fail gracefully after 30s
✅ Users get helpful error messages
✅ Lower memory footprint (1 worker vs 2-3)

### Potential Concerns
⚠️ Lower concurrency with 1 worker (acceptable for free tier)
⚠️ 120s timeout may still be reached if multiple LLM calls chain
✅ Mitigated by 30s timeout on each individual LLM call

### Monitoring Priorities
1. 🔍 Worker timeout errors in logs
2. 📊 Memory usage trends
3. ⏱️ Response time metrics
4. 👥 User-reported errors

---

**Documentation Version:** 1.0  
**Last Updated:** 2026-02-15  
**Implementation Status:** ✅ Complete
