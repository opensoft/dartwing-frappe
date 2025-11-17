#!/bin/bash
# Test script for Family Manager API endpoints

BASE_URL="http://localhost:8000"
CREDS_FILE="/home/brett/projects/frappe/development/frappe-bench/api_credentials.txt"

# Read API credentials
if [ -f "$CREDS_FILE" ]; then
    API_KEY=$(grep "API Key:" $CREDS_FILE | cut -d' ' -f3)
    API_SECRET=$(grep "API Secret:" $CREDS_FILE | cut -d' ' -f3)
    AUTH_HEADER="Authorization: token ${API_KEY}:${API_SECRET}"
else
    echo "Error: API credentials file not found. Run setup_family_manager.py first."
    exit 1
fi

echo "=========================================="
echo "Family Manager API Tests"
echo "=========================================="
echo ""

# Test 1: Create a Family organization
echo "1. Testing CREATE (Custom API)..."
CREATE_RESPONSE=$(curl -s -X POST "$BASE_URL/api/method/family_manager.api.family.create_family" \
  -H "$AUTH_HEADER" \
  -H "Content-Type: application/json" \
  -d '{
    "organization_name": "Smith Family",
    "organization_type": "Family",
    "description": "The Smith family organization"
  }')
echo "Response: $CREATE_RESPONSE"
echo ""

# Test 2: Get all families
echo "2. Testing GET ALL (Custom API)..."
GET_ALL_RESPONSE=$(curl -s -X GET "$BASE_URL/api/method/family_manager.api.family.get_all_families" \
  -H "$AUTH_HEADER")
echo "Response: $GET_ALL_RESPONSE"
echo ""

# Test 3: Get single family
echo "3. Testing GET ONE (Custom API)..."
GET_ONE_RESPONSE=$(curl -s -X GET "$BASE_URL/api/method/family_manager.api.family.get_family?name=Smith%20Family" \
  -H "$AUTH_HEADER")
echo "Response: $GET_ONE_RESPONSE"
echo ""

# Test 4: Update family
echo "4. Testing UPDATE (Custom API)..."
UPDATE_RESPONSE=$(curl -s -X POST "$BASE_URL/api/method/family_manager.api.family.update_family" \
  -H "$AUTH_HEADER" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Smith Family",
    "description": "Updated Smith family organization",
    "status": "Active"
  }')
echo "Response: $UPDATE_RESPONSE"
echo ""

# Test 5: Search families
echo "5. Testing SEARCH (Custom API)..."
SEARCH_RESPONSE=$(curl -s -X GET "$BASE_URL/api/method/family_manager.api.family.search_families?query=Smith" \
  -H "$AUTH_HEADER")
echo "Response: $SEARCH_RESPONSE"
echo ""

# Test 6: Get statistics
echo "6. Testing STATISTICS (Custom API)..."
STATS_RESPONSE=$(curl -s -X GET "$BASE_URL/api/method/family_manager.api.family.get_family_stats" \
  -H "$AUTH_HEADER")
echo "Response: $STATS_RESPONSE"
echo ""

# Test 7: Built-in REST API - List
echo "7. Testing Built-in REST API - LIST..."
REST_LIST=$(curl -s -X GET "$BASE_URL/api/resource/Family" \
  -H "$AUTH_HEADER")
echo "Response: $REST_LIST"
echo ""

# Test 8: Built-in REST API - Get One
echo "8. Testing Built-in REST API - GET ONE..."
REST_GET=$(curl -s -X GET "$BASE_URL/api/resource/Family/Smith%20Family" \
  -H "$AUTH_HEADER")
echo "Response: $REST_GET"
echo ""

# Test 9: Delete family (commented out to preserve data)
# echo "9. Testing DELETE (Custom API)..."
# DELETE_RESPONSE=$(curl -s -X POST "$BASE_URL/api/method/family_manager.api.family.delete_family" \
#   -H "$AUTH_HEADER" \
#   -H "Content-Type: application/json" \
#   -d '{"name": "Smith Family"}')
# echo "Response: $DELETE_RESPONSE"
# echo ""

echo "=========================================="
echo "API Tests Complete!"
echo "=========================================="
