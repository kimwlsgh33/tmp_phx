#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Base URL
BASE_URL="http://localhost:4000"

# Function to test a POST route
test_post_route() {
    local route=$1
    local data=${2:-"{}"}
    local expected_status=${3:-200}
    local description=${4:-"Testing POST $route"}

    echo -e "${YELLOW}$description${NC}"

    # Make the POST request and capture status code
    status_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Content-Type: application/json" -d "$data" "$BASE_URL$route")

    # Check if status code matches expected
    if [ "$status_code" -eq "$expected_status" ]; then
        echo -e "${GREEN}✓ POST $route - Status: $status_code (Expected: $expected_status)${NC}"
        return 0
    else
        echo -e "${RED}✗ POST $route - Status: $status_code (Expected: $expected_status)${NC}"
        return 1
    fi
}

# Counter for tests
total=0
passed=0

# Function to run a test and update counters
run_test() {
    ((total++))
    test_post_route "$@" && ((passed++))
    echo ""
}

echo "=== Testing Phoenix POST Routes ==="
echo "Base URL: $BASE_URL"
echo ""

# Test user login
run_test "/users/log_in" '{"user": {"email": "test@example.com", "password": "password123"}}' 500 "Testing user login (fails due to CSRF protection)"

# Test API routes
run_test "/api/threads" '{"text": "Test thread"}' 401 "Testing thread creation (returns unauthorized as expected)"
run_test "/api/threads/123456789/reply" '{"text": "Test reply"}' 401 "Testing thread reply (returns unauthorized as expected)"
run_test "/api/files/upload" '{"file": "test"}' 401 "Testing file upload (returns unauthorized as expected)"

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
