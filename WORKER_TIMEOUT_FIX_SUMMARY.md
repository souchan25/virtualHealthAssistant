# Worker Timeout Fix - Implementation Summary

## Problem Statement
The chatbot was experiencing worker timeouts in production (Render/Gunicorn) when users sent messages, causing:
- `WORKER TIMEOUT (pid:39)` errors
- `Worker was sent SIGKILL! Perhaps out of memory?` errors
- Users seeing "Sorry, I encountered an error. Please try again."

## Root Causes
1. **No timeout on LLM API calls** - HTTP requests to Groq/Gemini/Cohere had no timeout parameter
2. **Gunicorn default timeout (30s)** too short for LLM responses during high load
3. **Too many workers (2-3)** on free tier causing memory pressure

## Changes Implemented

### 1. Gunicorn Configuration Updates

#### render.yaml (Line 9)
**Before:**
```yaml
startCommand: cd Django && gunicorn health_assistant.wsgi:application --bind 0.0.0.0:$PORT --workers 2
```

**After:**
```yaml
startCommand: cd Django && gunicorn health_assistant.wsgi:application --bind 0.0.0.0:$PORT --workers 1 --timeout 120 --graceful-timeout 30
```

**Changes:**
- Workers: 2 → 1 (memory optimization for free tier)
- Timeout: default 30s → 120s (4x increase)
- Graceful timeout: Added 30s for clean shutdown

#### Procfile (Line 1)
**Before:**
```
web: cd Django && gunicorn health_assistant.wsgi:application --bind 0.0.0.0:$PORT --workers 3
```

**After:**
```
web: cd Django && gunicorn health_assistant.wsgi:application --bind 0.0.0.0:$PORT --workers 1 --timeout 120 --graceful-timeout 30
```

**Changes:**
- Workers: 3 → 1 (standardized with render.yaml, memory optimization)
- Timeout: default 30s → 120s (4x increase)
- Graceful timeout: Added 30s for clean shutdown

### 2. LLM Client Timeout Configurations

#### Django/clinic/llm_service.py

##### A. Groq Client Initialization (Lines 81-85)
**Before:**
```python
self.groq_client = OpenAI(
    api_key=settings.GROQ_API_KEY,
    base_url="https://api.groq.com/openai/v1",
)
```

**After:**
```python
self.groq_client = OpenAI(
    api_key=settings.GROQ_API_KEY,
    base_url="https://api.groq.com/openai/v1",
    timeout=30.0  # Add 30 second timeout
)
```

**Impact:** All Groq API calls now timeout after 30 seconds (3 locations in file)

##### B. Gemini Client Initialization (Lines 58-61)
**Before:**
```python
self.gemini_client = genai.Client(api_key=settings.GEMINI_API_KEY)
```

**After:**
```python
self.gemini_client = genai.Client(
    api_key=settings.GEMINI_API_KEY,
    http_options={'timeout': 30}  # Add 30 second timeout
)
```

**Impact:** All Gemini API calls now timeout after 30 seconds (2 locations in file)

##### C. Cohere Client Initialization (Line 96)
**Before:**
```python
self.cohere_client = cohere.Client(settings.COHERE_API_KEY)
```

**After:**
```python
self.cohere_client = cohere.Client(settings.COHERE_API_KEY, timeout=30)
```

**Impact:** All Cohere API calls now timeout after 30 seconds (2 locations in file)

##### D. OpenRouter API Calls
**Status:** Already had `timeout=30` parameter ✅
- Lines 204, 313, 512 - All OpenRouter requests.post() calls already properly configured

### 3. Enhanced Error Handling

#### Django/clinic/views.py

##### A. Added requests module import (Line 17)
```python
import requests
```

##### B. Improved send_chat_message error handling (Lines 399-401)
**Before:**
```python
except Exception as llm_error:
    logger.error(f"LLM fallback failed: {llm_error}")
    response_text = "Thank you for your message. I'm experiencing technical difficulties..."
```

**After:**
```python
except requests.exceptions.Timeout as timeout_error:
    logger.error(f"LLM call timed out: {timeout_error}")
    response_text = "I apologize for the delay. The system is experiencing high load. Please try again in a moment, or consult with our clinic staff for immediate assistance."
except Exception as llm_error:
    logger.error(f"LLM fallback failed: {llm_error}")
    response_text = "Thank you for your message. I'm experiencing technical difficulties. Please consult with our clinic staff for proper evaluation of your symptoms."
```

**Changes:**
- Added specific handling for `requests.exceptions.Timeout`
- Timeout errors now provide more helpful user-facing message
- Still maintains generic fallback for other errors

## Expected Outcomes

✅ **LLM API calls timeout gracefully** after 30 seconds instead of hanging indefinitely
✅ **Gunicorn workers have 120 seconds** to complete requests (4x previous timeout)
✅ **Users receive helpful error messages** instead of generic errors during timeouts
✅ **Reduced memory usage** with 1 worker on free tier (50% reduction from render.yaml, 67% from Procfile)
✅ **No more WORKER TIMEOUT or SIGKILL errors** in production logs

## Testing Recommendations

### Manual Testing
1. Send a chat message: "I feel tired, apat na oras lng tulog ko"
2. Verify bot responds without errors
3. Check logs for no timeout errors
4. Monitor memory usage on Render dashboard

### Integration Testing
- Verify all LLM providers can still make successful API calls
- Test fallback chain: Groq → OpenRouter → Cohere → Gemini
- Confirm timeout exceptions are caught and handled gracefully

### Load Testing
- Simulate multiple concurrent requests to verify worker doesn't timeout
- Test with intentionally slow API responses (mock)

## Files Modified

1. ✅ `render.yaml` - Gunicorn configuration for Render deployment
2. ✅ `Procfile` - Gunicorn configuration for Heroku/other platforms  
3. ✅ `Django/clinic/llm_service.py` - LLM client timeout configurations
4. ✅ `Django/clinic/views.py` - Enhanced timeout error handling

## Compatibility Notes

- **Groq/OpenAI SDK**: `timeout` parameter supported in OpenAI client constructor
- **Gemini SDK**: `http_options` parameter supports timeout configuration
- **Cohere SDK**: `timeout` parameter supported in Client constructor
- **OpenRouter**: Uses `requests.post()` with `timeout` parameter (already implemented)

## Security Considerations

- Timeouts prevent resource exhaustion from hanging requests
- Graceful timeout allows workers to finish in-progress requests before shutdown
- No sensitive data exposed in timeout error messages

## Performance Impact

- **Positive**: Faster failure detection (30s vs infinite hang)
- **Positive**: Better memory efficiency with 1 worker
- **Minimal**: Timeout checks add negligible overhead
- **Trade-off**: Lower concurrency with 1 worker (acceptable for free tier)

## Rollback Plan

If issues arise, revert by:
1. `git revert <commit-hash>`
2. Or manually restore previous values:
   - render.yaml: `--workers 2` (no timeout flags)
   - Procfile: `--workers 3` (no timeout flags)
   - Remove timeout parameters from LLM client initializations
   - Remove timeout exception handling from views.py

## Monitoring

After deployment, monitor:
- Gunicorn worker logs for timeout errors
- Memory usage on Render dashboard  
- Response time metrics for chat endpoint
- User-reported errors in production

## Future Improvements

1. **Async LLM calls**: Use async/await for better concurrency with 1 worker
2. **Caching**: Cache common LLM responses to reduce API calls
3. **Circuit breaker**: Implement circuit breaker pattern for failing providers
4. **Rate limiting**: Add rate limiting to prevent abuse
5. **Metrics**: Add Prometheus metrics for timeout tracking

---

**Implemented by:** GitHub Copilot Agent  
**Date:** 2026-02-15  
**Commit:** Add timeout configurations to prevent worker timeouts
