#!/bin/bash
# Quick DevOps Infrastructure Test Script

set -e  # Exit on error

echo "🧪 Testing DevOps Infrastructure..."
echo ""

# Test local build
echo "1️⃣  Testing local build..."
make build || { echo "❌ Build failed"; exit 1; }
echo "✅ Build successful"
echo ""

# Test services start
echo "2️⃣  Testing services..."
make up || { echo "❌ Services failed to start"; exit 1; }
sleep 5
echo "✅ Services started"
echo ""

# Test health
echo "3️⃣  Testing health endpoint..."
curl -f http://localhost:5001/health > /dev/null || { echo "❌ Health check failed"; make down; exit 1; }
echo "✅ Health check passed"
echo ""

# Test API - Create entry
echo "4️⃣  Testing API - Create entry..."
ENTRY_RESPONSE=$(curl -s -X POST http://localhost:5001/api/entries \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Entry","content":"This is a test"}')
if echo "$ENTRY_RESPONSE" | grep -q "id"; then
  echo "✅ Entry created successfully"
  ENTRY_ID=$(echo "$ENTRY_RESPONSE" | grep -o '"id":"[^"]*' | cut -d'"' -f4)
  echo "   Entry ID: $ENTRY_ID"
else
  echo "❌ Failed to create entry"
  make down
  exit 1
fi
echo ""

# Test API - Get entries
echo "5️⃣  Testing API - Get entries..."
curl -f http://localhost:5001/api/entries > /dev/null || { echo "❌ Failed to get entries"; make down; exit 1; }
echo "✅ Retrieved entries"
echo ""

# Test cleanup
echo "6️⃣  Testing cleanup..."
make down || { echo "❌ Cleanup failed"; exit 1; }
echo "✅ Cleanup successful"
echo ""

echo "🎉 All tests passed!"
echo ""
echo "Next steps:"
echo "  - Test CI/CD with a PR"
echo "  - Test branch protection (if enabled)"
echo "  - Review docs/TESTING_CHECKLIST.md for comprehensive tests"

