#!/bin/bash
# Test Backend Deployment and Login
# This script verifies the backend is properly deployed and login works

set -e  # Exit on error

BACKEND_URL="${1:-https://cpsu-health-assistant-backend.azurewebsites.net}"
API_URL="${BACKEND_URL}/api"

echo "=========================================="
echo "Backend Deployment & Login Test"
echo "=========================================="
echo "Backend URL: $BACKEND_URL"
echo "API URL: $API_URL"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Health Check
echo "Test 1: Health Check Endpoint"
echo "----------------------------------------------"
if response=$(curl -s -w "\n%{http_code}" "${API_URL}/health/" 2>&1); then
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✓ Health check passed${NC}"
        echo "Response: $body"
    else
        echo -e "${RED}✗ Health check failed (HTTP $http_code)${NC}"
        echo "Response: $body"
        exit 1
    fi
else
    echo -e "${RED}✗ Health check failed - Could not connect${NC}"
    exit 1
fi
echo ""

# Test 2: Registration
echo "Test 2: User Registration"
echo "----------------------------------------------"
TEST_SCHOOL_ID="test-$(date +%s)"
TEST_PASSWORD="TestPass123!"
TEST_NAME="Test User $(date +%H:%M:%S)"

register_payload=$(cat <<EOF
{
  "school_id": "$TEST_SCHOOL_ID",
  "password": "$TEST_PASSWORD",
  "name": "$TEST_NAME",
  "role": "student"
}
EOF
)

if response=$(curl -s -w "\n%{http_code}" -X POST "${API_URL}/auth/register/" \
    -H "Content-Type: application/json" \
    -d "$register_payload" 2>&1); then
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "201" ]; then
        echo -e "${GREEN}✓ Registration successful${NC}"
        TOKEN=$(echo "$body" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
        echo "Token: $TOKEN"
        echo "School ID: $TEST_SCHOOL_ID"
    else
        echo -e "${YELLOW}⚠ Registration returned HTTP $http_code${NC}"
        echo "Response: $body"
        # This might be OK if user already exists
    fi
else
    echo -e "${RED}✗ Registration failed${NC}"
fi
echo ""

# Test 3: Login
echo "Test 3: User Login"
echo "----------------------------------------------"
login_payload=$(cat <<EOF
{
  "school_id": "$TEST_SCHOOL_ID",
  "password": "$TEST_PASSWORD"
}
EOF
)

if response=$(curl -s -w "\n%{http_code}" -X POST "${API_URL}/auth/login/" \
    -H "Content-Type: application/json" \
    -d "$login_payload" 2>&1); then
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✓ Login successful${NC}"
        TOKEN=$(echo "$body" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
        USER_NAME=$(echo "$body" | grep -o '"name":"[^"]*' | cut -d'"' -f4)
        echo "Token: $TOKEN"
        echo "User: $USER_NAME"
    else
        echo -e "${RED}✗ Login failed (HTTP $http_code)${NC}"
        echo "Response: $body"
        exit 1
    fi
else
    echo -e "${RED}✗ Login failed - Could not connect${NC}"
    exit 1
fi
echo ""

# Test 4: Authenticated Request (Profile)
if [ -n "$TOKEN" ]; then
    echo "Test 4: Authenticated Request (Profile)"
    echo "----------------------------------------------"
    if response=$(curl -s -w "\n%{http_code}" "${API_URL}/profile/" \
        -H "Authorization: Token $TOKEN" 2>&1); then
        
        http_code=$(echo "$response" | tail -n1)
        body=$(echo "$response" | sed '$d')
        
        if [ "$http_code" = "200" ]; then
            echo -e "${GREEN}✓ Profile request successful${NC}"
            echo "Profile: $body"
        else
            echo -e "${RED}✗ Profile request failed (HTTP $http_code)${NC}"
            echo "Response: $body"
            exit 1
        fi
    else
        echo -e "${RED}✗ Profile request failed${NC}"
        exit 1
    fi
    echo ""
fi

# Test 5: Available Symptoms
echo "Test 5: Available Symptoms List"
echo "----------------------------------------------"
if response=$(curl -s -w "\n%{http_code}" "${API_URL}/symptoms/available/" 2>&1); then
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✓ Symptoms list retrieved${NC}"
        symptom_count=$(echo "$body" | grep -o '"' | wc -l)
        echo "Response contains $((symptom_count / 2)) symptom entries"
    else
        echo -e "${RED}✗ Symptoms list failed (HTTP $http_code)${NC}"
        echo "Response: $body"
    fi
else
    echo -e "${RED}✗ Symptoms list failed${NC}"
fi
echo ""

# Summary
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo -e "${GREEN}✓ All critical tests passed!${NC}"
echo ""
echo "Backend is properly deployed and functional."
echo "Login system is working correctly."
echo ""
echo "Next steps:"
echo "  1. Test in browser: ${BACKEND_URL}/admin"
echo "  2. Test frontend: https://cpsu-health-assistant-frontend.azurestaticapps.net"
echo "  3. Try logging in with your registered user"
echo ""
