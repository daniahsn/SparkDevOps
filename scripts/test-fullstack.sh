#!/bin/bash
# Full-Stack Integration Test Script

set -e

API_URL="http://localhost:5001"

echo "🧪 FULL-STACK INTEGRATION TEST"
echo "=============================="
echo ""

# 1. Check backend health
echo "1️⃣  Checking backend health..."
HEALTH=$(curl -s $API_URL/health)
if echo "$HEALTH" | grep -q "healthy"; then
    echo "✅ Backend is healthy"
    echo "$HEALTH" | python3 -m json.tool
else
    echo "❌ Backend is not healthy"
    echo "Run: make up"
    exit 1
fi

echo ""
echo "2️⃣  Checking current entries..."
ENTRIES=$(curl -s $API_URL/api/entries)
ENTRY_COUNT=$(echo "$ENTRIES" | python3 -c "import sys, json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")
echo "Current entries: $ENTRY_COUNT"

echo ""
echo "3️⃣  Creating entry via API..."
CREATE_RESPONSE=$(curl -s -X POST $API_URL/api/entries \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Full-Stack Test Entry",
    "content": "This entry was created via API to test integration",
    "emotion": "happy"
  }')

if echo "$CREATE_RESPONSE" | grep -q "id"; then
    echo "✅ Entry created successfully"
    echo "$CREATE_RESPONSE" | python3 -m json.tool | head -10
    ENTRY_ID=$(echo "$CREATE_RESPONSE" | grep -o '"id":"[^"]*' | cut -d'"' -f4)
    echo "Entry ID: $ENTRY_ID"
else
    echo "❌ Failed to create entry"
    echo "$CREATE_RESPONSE"
    exit 1
fi

echo ""
echo "4️⃣  Verifying entry in API..."
GET_RESPONSE=$(curl -s $API_URL/api/entries/$ENTRY_ID)
if echo "$GET_RESPONSE" | grep -q "Full-Stack Test Entry"; then
    echo "✅ Entry found in API"
    echo "$GET_RESPONSE" | python3 -m json.tool | head -8
else
    echo "❌ Entry not found"
    exit 1
fi

echo ""
echo "5️⃣  Updating entry via API..."
UPDATE_RESPONSE=$(curl -s -X PUT $API_URL/api/entries/$ENTRY_ID \
  -H "Content-Type: application/json" \
  -d '{"title":"Updated Test Entry","content":"This entry has been updated"}')
if echo "$UPDATE_RESPONSE" | grep -q "Updated Test Entry"; then
    echo "✅ Entry updated successfully"
    echo "$UPDATE_RESPONSE" | python3 -m json.tool | head -8
else
    echo "❌ Failed to update entry"
    exit 1
fi

echo ""
echo "6️⃣  Getting all entries..."
ALL_ENTRIES=$(curl -s $API_URL/api/entries)
NEW_COUNT=$(echo "$ALL_ENTRIES" | python3 -c "import sys, json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")
echo "Total entries now: $NEW_COUNT"

echo ""
echo "7️⃣  Cleaning up - Deleting test entry..."
DELETE_RESPONSE=$(curl -s -X DELETE $API_URL/api/entries/$ENTRY_ID)
echo "✅ Test entry deleted"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ FULL-STACK API TEST COMPLETE!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📱 NEXT: Test iOS App Integration"
echo ""
echo "1. Open iOS app in Xcode"
echo "2. Create an entry in the app"
echo "3. Run this command to verify it appears in API:"
echo "   curl $API_URL/api/entries | python3 -m json.tool"
echo ""
echo "4. Create an entry via API:"
echo "   curl -X POST $API_URL/api/entries \\"
echo "     -H \"Content-Type: application/json\" \\"
echo "     -d '{\"title\":\"From API\",\"content\":\"Test\"}'"
echo ""
echo "5. Refresh the app - entry should appear!"
echo ""
echo "✅ If both directions work, your full-stack is integrated!"


