#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Base URL
BASE_URL="http://localhost:4000"

# Function to test a route
test_route() {
    local route=$1
    local method=${2:-GET}
    local expected_status=${3:-200}
    local description=${4:-"Testing $method $route"}

    echo -e "${YELLOW}$description${NC}"

    # Make the request and capture status code
    if [ "$method" = "GET" ]; then
        status_code=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL$route")
    elif [ "$method" = "POST" ]; then
        status_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL$route")
    elif [ "$method" = "DELETE" ]; then
        status_code=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$BASE_URL$route")
    fi

    # Check if status code matches expected
    if [ "$status_code" -eq "$expected_status" ]; then
        echo -e "${GREEN}✓ $method $route - Status: $status_code (Expected: $expected_status)${NC}"
        return 0
    else
        echo -e "${RED}✗ $method $route - Status: $status_code (Expected: $expected_status)${NC}"
        return 1
    fi
}

# Counter for tests
total=0
passed=0

# Function to run a test and update counters
run_test() {
    ((total++))
    test_route "$@" && ((passed++))
    echo ""
}

echo "=== Testing Phoenix Routes ==="
echo "Base URL: $BASE_URL"
echo ""

# Test landing page routes
run_test "/"
run_test "/marketing/pricing"
run_test "/marketing/features"
run_test "/marketing/company"

# Test legal pages
run_test "/privacy-policy/latest" "GET" 400 "Testing privacy policy page (returns bad request due to invalid version)"
run_test "/terms-of-services/latest" "GET" 400 "Testing terms of service page (returns bad request due to invalid version)"

# Test documentation routes
run_test "/docs"
run_test "/docs/getting-started"

# Test LiveView routes
run_test "/counter"
run_test "/files"
run_test "/search"
run_test "/upload"
run_test "/upload/post"
run_test "/upload/short"
run_test "/upload/long"

# Test authentication routes (these might redirect)
run_test "/users/register" "GET" 200 "Testing user registration page"
run_test "/users/log_in" "GET" 200 "Testing user login page"
run_test "/users/reset_password" "GET" 200 "Testing password reset page"

# Test API routes (these might require authentication)
run_test "/api/threads/123456789" "GET" 401 "Testing thread API (returns unauthorized as expected)"
run_test "/api/files/test.txt" "GET" 401 "Testing file download (returns unauthorized as expected)"

# Test dashboard (if in dev mode)
run_test "/dev/dashboard" "GET" 302 "Testing LiveDashboard (redirects to login)"

# Print summary
echo "=== Test Summary ==="
echo "Passed: $passed/$total tests"

if [ "$passed" -eq "$total" ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi
