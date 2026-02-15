# Deployment Guide - Worker Timeout Fix

## Pre-Deployment Checklist

- [x] All code changes committed to branch `copilot/fix-chatbot-worker-timeouts`
- [x] Syntax validation passed
- [x] Documentation complete
- [x] No breaking changes introduced
- [ ] Ready for code review
- [ ] Ready to merge to main branch

## Deployment Steps

### Step 1: Merge to Main Branch

```bash
# After PR approval
git checkout main
git pull origin main
git merge copilot/fix-chatbot-worker-timeouts
git push origin main
```

### Step 2: Verify Render Deployment

1. Go to Render Dashboard: https://dashboard.render.com
2. Navigate to `cpsu-health-assistant-backend` service
3. Verify automatic deployment triggered by push to main
4. Monitor deployment logs for:
   - ✅ Build success
   - ✅ Service restart with new Gunicorn config
   - ✅ No startup errors

### Step 3: Post-Deployment Verification

#### A. Check Worker Configuration

1. Go to Render service "Logs" tab
2. Look for Gunicorn startup message:
   ```
   [INFO] Starting gunicorn 21.x.x
   [INFO] Using worker: sync
   [INFO] Workers: 1  ← Verify this is 1, not 2
   ```

#### B. Test Chat Functionality

1. Open the deployed application
2. Navigate to chat interface
3. Send test message: "I feel tired, apat na oras lng tulog ko"
4. Expected results:
   - ✅ Bot responds within reasonable time (<10s normal, <120s worst case)
   - ✅ No error messages about worker timeouts
   - ✅ If timeout occurs, user sees helpful message

#### C. Monitor Logs

Watch logs for 10-15 minutes after deployment:

```bash
# Look for these GOOD indicators:
✅ "Gemini AI initialized successfully (new API)"
✅ "Groq API initialized successfully"
✅ "Cohere AI initialized successfully"
✅ "Response from [Groq|OpenRouter|Cohere|Gemini]"

# Should NOT see these anymore:
❌ "[CRITICAL] WORKER TIMEOUT"
❌ "[ERROR] Worker (pid:X) was sent SIGKILL"
❌ "Perhaps out of memory?"
```

#### D. Check Memory Usage

1. Go to Render Dashboard → Service → Metrics
2. Monitor memory usage:
   - **Before:** ~400-512 MB (2 workers)
   - **Expected After:** ~200-300 MB (1 worker)
   - **Alert if:** Memory exceeds 450 MB consistently

### Step 4: Performance Testing

#### Test 1: Single Request
```bash
# Test chat endpoint
curl -X POST https://your-app.onrender.com/api/chat/message/ \
  -H "Authorization: Token YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message":"I have fever","session_id":"test-123"}'
```

**Expected:** Response within 5-15 seconds

#### Test 2: Timeout Simulation
- Wait for a genuine timeout scenario (network issue, API slowdown)
- User should see: "I apologize for the delay. The system is experiencing high load..."
- Logs should show: "LLM call timed out: <timeout_error>"

#### Test 3: Concurrent Requests
```bash
# Run 3 concurrent requests (tests 1 worker handling multiple)
for i in {1..3}; do
  curl -X POST https://your-app.onrender.com/api/chat/message/ \
    -H "Authorization: Token YOUR_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"message":"test message '$i'","session_id":"test-'$i'"}' &
done
wait
```

**Expected:** All requests complete within 120s, no worker timeout errors

## Monitoring Plan (First 48 Hours)

### Critical Metrics

| Metric | Check Frequency | Alert Threshold |
|--------|----------------|-----------------|
| Worker timeouts | Every 2 hours | 0 expected, alert if >0 |
| Memory usage | Every 4 hours | Alert if >450 MB |
| Response time | Every 2 hours | Alert if >30s average |
| Error rate | Every 2 hours | Alert if >5% |

### Log Monitoring Commands

```bash
# If using Render CLI
render logs -t cpsu-health-assistant-backend | grep -E "(TIMEOUT|SIGKILL|ERROR)"

# Watch for timeout errors
render logs -t cpsu-health-assistant-backend | grep "timed out"

# Check LLM provider usage
render logs -t cpsu-health-assistant-backend | grep "Response from"
```

## Rollback Procedure

If critical issues occur, rollback immediately:

### Option 1: Quick Rollback via Render Dashboard
1. Go to Render Dashboard → Service → "Manual Deploy"
2. Select previous successful deployment
3. Click "Deploy"

### Option 2: Git Revert
```bash
git revert 6515a31  # Revert comparison docs
git revert 5ac05e4  # Revert test and summary
git revert 822438b  # Revert timeout configurations
git push origin main
```

### Option 3: Manual Fix (if specific issue identified)
Update the specific file causing issues and push hotfix.

## Success Criteria

After 48 hours, deployment is successful if:

- ✅ Zero worker timeout errors in logs
- ✅ Memory usage reduced by 30-50%
- ✅ Average response time <10 seconds
- ✅ No user-reported errors about timeouts
- ✅ All LLM providers responding normally

## Known Limitations

1. **Reduced Concurrency**: With 1 worker, only 1 request processed at a time
   - **Impact**: Slight delay during concurrent requests
   - **Acceptable for**: Free tier with low to moderate traffic

2. **Long Requests**: 120s timeout may still be reached if:
   - Multiple LLM calls in sequence
   - All providers fail and retry
   - **Mitigation**: Each individual LLM call times out at 30s

3. **Cold Start**: First request after idle period may take longer
   - **Impact**: 2-3 second delay for model loading
   - **Acceptable**: Models cached after first load

## Support & Escalation

### If Issues Arise

1. **Check logs first**: Most issues visible in Render logs
2. **Review metrics**: Memory, response time, error rate
3. **Test manually**: Use curl commands from this guide
4. **Rollback if needed**: Use procedures above

### Contact Information

- **Repository**: https://github.com/souchan25/virtualHealthAssistant
- **Pull Request**: #[PR_NUMBER]
- **Implementation Branch**: `copilot/fix-chatbot-worker-timeouts`

## Additional Resources

- 📄 [WORKER_TIMEOUT_FIX_SUMMARY.md](./WORKER_TIMEOUT_FIX_SUMMARY.md) - Complete implementation details
- 📊 [TIMEOUT_FIX_COMPARISON.md](./TIMEOUT_FIX_COMPARISON.md) - Visual before/after comparison
- 🧪 [test_timeout_config.py](./Django/tests/test_timeout_config.py) - Timeout verification test

---

**Document Version:** 1.0  
**Last Updated:** 2026-02-15  
**Status:** Ready for Deployment ✅
