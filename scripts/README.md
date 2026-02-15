# Helper Scripts

This directory contains utility scripts for testing and deployment.

## test_backend_deployment.sh

Automated script to verify backend deployment and login functionality.

### Usage

```bash
# Test default production backend
bash scripts/test_backend_deployment.sh

# Test custom backend URL
bash scripts/test_backend_deployment.sh https://your-backend.azurewebsites.net
```

### What it tests

1. **Health Check** - Verifies backend is running and responding
2. **User Registration** - Tests the registration endpoint
3. **User Login** - Tests authentication with school_id and password
4. **Authenticated Request** - Tests token-based authentication
5. **Symptoms API** - Verifies ML-related endpoints are accessible

### Expected Output

```
==========================================
Backend Deployment & Login Test
==========================================
Backend URL: https://cpsu-health-assistant-backend.azurewebsites.net
API URL: https://cpsu-health-assistant-backend.azurewebsites.net/api

Test 1: Health Check Endpoint
----------------------------------------------
✓ Health check passed
Response: {"status":"ok","database":"connected",...}

Test 2: User Registration
----------------------------------------------
✓ Registration successful
Token: abcd1234...
School ID: test-1708000000

Test 3: User Login
----------------------------------------------
✓ Login successful
Token: abcd1234...
User: Test User 10:00:00

Test 4: Authenticated Request (Profile)
----------------------------------------------
✓ Profile request successful
Profile: {"school_id":"test-1708000000",...}

Test 5: Available Symptoms List
----------------------------------------------
✓ Symptoms list retrieved
Response contains 132 symptom entries

==========================================
Test Summary
==========================================
✓ All critical tests passed!

Backend is properly deployed and functional.
Login system is working correctly.
```

### Exit Codes

- `0` - All tests passed
- `1` - One or more tests failed

### Requirements

- `curl` command-line tool
- `grep` and `sed` (standard on most systems)
- Internet connection to reach Azure backend

### Troubleshooting

**"Health check failed - Could not connect"**
- Backend may not be deployed yet
- Check URL is correct
- Verify backend is running in Azure Portal

**"Registration returned HTTP 400"**
- Check request payload format
- Verify backend environment variables are set

**"Login failed (HTTP 401)"**
- Check credentials are correct
- Verify user was registered successfully

**"Profile request failed (HTTP 403)"**
- Token authentication may be failing
- Check DJANGO_SECRET_KEY is set in Azure

---

## Future Scripts

Additional scripts to be added:

- `start_rasa.sh` - Interactive Rasa setup and start
- `run_tests.sh` - Run Django and Vue test suites
- `deploy_local.sh` - Local deployment with Docker
- `backup_database.sh` - Backup Supabase database

---

**Last Updated**: February 15, 2026
