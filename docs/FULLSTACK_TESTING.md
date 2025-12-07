# Full-Stack Testing Guide

## Complete Testing Workflow for iOS App + Backend API

### Prerequisites
- Backend API running
- iOS app built and running
- Both connected and communicating

---

## 🚀 Step 1: Start Backend

```bash
# Start the backend services
make up

# Verify it's running
make health

# Should see:
# {
#     "service": "spark-backend",
#     "status": "healthy"
# }
```

**Expected:** Backend API running on `http://localhost:5001`

---

## 📱 Step 2: Configure iOS App (iOS Simulator)

### ✅ For iOS Simulator (Your Setup):
**Good news!** iOS Simulator can access `localhost` directly, so setup is simple:

1. Open `Spark/Services/APIClient.swift`
2. Verify `baseURL = "http://localhost:5001"` ✅
   - This should already be set correctly
   - Simulator shares the Mac's network, so localhost works!

3. Verify API Mode:
   - Open `Spark/Services/StorageService.swift`
   - Check `useAPI = true` (should be true to use API)

**That's it!** No IP address configuration needed for simulator.

### 📝 Note for Physical iPhone (if needed later):
If you test on a physical iPhone, you'll need to:
1. Find Mac's IP: `ifconfig | grep 'inet ' | grep -v 127.0.0.1`
2. Update `baseURL` to: `http://<your-mac-ip>:5001`
3. Ensure iPhone and Mac are on same WiFi

---

## 🧪 Step 3: Full-Stack Test Scenarios

### Test 1: Verify Backend is Accessible

**In Terminal:**
```bash
# Check health
curl http://localhost:5001/health

# Check current entries
curl http://localhost:5001/api/entries | python3 -m json.tool
```

**Expected:** 
- Health returns `{"status": "healthy"}`
- Entries returns `[]` (empty array initially)

---

### Test 2: Create Entry in iOS App → Verify in API

**In iOS App:**
1. Open the app
2. Tap the "+" or "Create" button
3. Fill in:
   - Title: "Test Entry from App"
   - Content: "This is a test entry created in the iOS app"
4. Save the entry

**In Terminal (verify):**
```bash
curl http://localhost:5001/api/entries | python3 -m json.tool
```

**Expected:**
- Entry appears in API response
- Entry has the title and content you entered
- Entry has an ID, creationDate, etc.

**What to look for:**
- ✅ Entry created successfully
- ✅ Entry has all fields populated
- ✅ Entry ID is a valid UUID

---

### Test 3: Create Entry via API → Verify in iOS App

**In Terminal:**
```bash
curl -X POST http://localhost:5001/api/entries \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test from API",
    "content": "This entry was created via API",
    "emotion": "happy"
  }' | python3 -m json.tool
```

**Save the entry ID from the response**

**In iOS App:**
1. Pull down to refresh (or restart app)
2. Look for "Test from API" entry

**Expected:**
- Entry appears in the app's entry list
- Entry shows the title and content

**What to look for:**
- ✅ Entry appears in app
- ✅ Data matches what was sent to API
- ✅ Entry is readable in app

---

### Test 4: Update Entry in iOS App → Verify in API

**In iOS App:**
1. Find an entry (preferably one you created)
2. Tap to view/edit
3. Change the title or content
4. Save

**In Terminal (get entry ID first):**
```bash
# Get all entries to find the ID
curl http://localhost:5001/api/entries | python3 -m json.tool

# Update the entry (replace <ID> with actual ID)
curl -X PUT http://localhost:5001/api/entries/<ID> \
  -H "Content-Type: application/json" \
  -d '{"title": "Updated Title"}' | python3 -m json.tool
```

**Expected:**
- Entry updated in API
- Changes reflected in API response

**What to look for:**
- ✅ Update successful
- ✅ New data in API
- ✅ Timestamp updated

---

### Test 5: Delete Entry in iOS App → Verify in API

**In iOS App:**
1. Find an entry to delete
2. Swipe to delete (or use delete button)
3. Confirm deletion

**In Terminal:**
```bash
# Check entries (should have one less)
curl http://localhost:5001/api/entries | python3 -m json.tool
```

**Expected:**
- Entry removed from API
- Entry count decreased

**What to look for:**
- ✅ Entry no longer in API
- ✅ Deletion successful

---

### Test 6: Multiple Operations Flow

**Complete workflow:**
1. **Create 3 entries in app**
   - Entry 1: "Morning thoughts"
   - Entry 2: "Afternoon reflection"
   - Entry 3: "Evening gratitude"

2. **Verify all 3 in API:**
   ```bash
   curl http://localhost:5001/api/entries | python3 -m json.tool
   ```

3. **Update Entry 2 in app**
   - Change title to "Updated Afternoon"

4. **Verify update in API:**
   ```bash
   curl http://localhost:5001/api/entries | python3 -m json.tool | grep -A 5 "Updated Afternoon"
   ```

5. **Delete Entry 1 via API:**
   ```bash
   # Get ID first, then delete
   curl -X DELETE http://localhost:5001/api/entries/<ID>
   ```

6. **Verify deletion in app:**
   - Refresh app
   - Entry 1 should be gone

**Expected:**
- All operations work correctly
- Data stays in sync
- No data loss

---

## 🔍 Step 4: Monitor and Debug

### Watch Backend Logs
```bash
# In a separate terminal
make logs

# Or
docker-compose logs -f backend
```

**What to watch for:**
- API requests coming in
- Successful responses (200, 201)
- Any errors (400, 500)

### Check iOS App Console
In Xcode:
1. Open Console (View → Debug Area → Activate Console)
2. Look for:
   - `📂 Loaded X entries from API`
   - `✅ Created entry via API`
   - `❌ Failed to...` (if errors)

### Test API Directly
```bash
# Health check
curl http://localhost:5001/health

# Get all entries
curl http://localhost:5001/api/entries

# Create entry
curl -X POST http://localhost:5001/api/entries \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","content":"Test"}'

# Get specific entry (replace <ID>)
curl http://localhost:5001/api/entries/<ID>

# Update entry
curl -X PUT http://localhost:5001/api/entries/<ID> \
  -H "Content-Type: application/json" \
  -d '{"title":"Updated"}'

# Delete entry
curl -X DELETE http://localhost:5001/api/entries/<ID>
```

---

## ✅ Test Checklist

### Basic Connectivity
- [ ] Backend running (`make health` works)
- [ ] API accessible from terminal
- [ ] iOS app can connect to API
- [ ] No network errors in console

### Create Operations
- [ ] Create entry in app → Appears in API
- [ ] Create entry via API → Appears in app
- [ ] Entry has all required fields
- [ ] Entry ID is valid UUID

### Read Operations
- [ ] App loads entries from API on startup
- [ ] App shows all entries from API
- [ ] Entry details match API data
- [ ] Refresh pulls latest from API

### Update Operations
- [ ] Update entry in app → Changes in API
- [ ] Update entry via API → Changes in app
- [ ] Updates persist correctly
- [ ] No data loss on update

### Delete Operations
- [ ] Delete entry in app → Removed from API
- [ ] Delete entry via API → Removed from app
- [ ] Other entries unaffected
- [ ] No crashes on delete

### Data Persistence
- [ ] Restart backend → Data persists
- [ ] Restart app → Data loads from API
- [ ] Data survives service restarts
- [ ] No duplicate entries

### Error Handling
- [ ] Backend down → App handles gracefully
- [ ] Network error → App shows appropriate message
- [ ] Invalid data → App doesn't crash
- [ ] Fallback to local storage works (if implemented)

---

## 🐛 Troubleshooting

### App shows "No entries" but API has data
**Check:**
- ✅ `useAPI = true` in StorageService
- ✅ `baseURL` is correct in APIClient
- ✅ Backend is running
- ✅ Check Xcode console for errors

**Fix:**
- Restart app
- Check network connection
- Verify API URL

### Network errors in app
**For iOS Simulator (Your Setup):**
- ✅ Use `http://localhost:5001` (already configured)
- ✅ Backend must be running (`make up`)
- ✅ Simulator can access localhost directly

**Common Simulator Issues:**
- Backend not running → Run `make up`
- Wrong port → Check backend is on 5001
- App not refreshing → Restart app in Xcode

**For Physical Device (if testing later):**
- ✅ Use Mac's IP address (not localhost)
- ✅ Mac and iPhone on same WiFi
- ✅ Firewall not blocking port 5001

**Fix for Simulator:**
```bash
# Make sure backend is running
make up
make health

# Verify API is accessible
curl http://localhost:5001/health
```

### Entries not syncing
**Check:**
- ✅ Backend logs show requests
- ✅ API returns correct data
- ✅ App console shows API calls
- ✅ No errors in either

**Fix:**
- Restart both backend and app
- Check API URL configuration
- Verify CORS is enabled (it is in backend)

### Date format issues
**Check:**
- ✅ Backend returns ISO8601 dates
- ✅ Swift decodes dates correctly
- ✅ No date parsing errors

**Fix:**
- Dates should work automatically
- Check console for date errors

---

## 🎯 Quick Test Script

Save this as `test-fullstack.sh`:

```bash
#!/bin/bash
echo "🧪 Full-Stack Test"
echo "=================="

# 1. Check backend
echo "1. Checking backend..."
curl -s http://localhost:5001/health | python3 -m json.tool || exit 1

# 2. Create entry via API
echo ""
echo "2. Creating entry via API..."
ENTRY_RESPONSE=$(curl -s -X POST http://localhost:5001/api/entries \
  -H "Content-Type: application/json" \
  -d '{"title":"Full-Stack Test","content":"Testing integration"}')
echo "$ENTRY_RESPONSE" | python3 -m json.tool

# 3. Get entry ID
ENTRY_ID=$(echo "$ENTRY_RESPONSE" | grep -o '"id":"[^"]*' | cut -d'"' -f4)
echo "Entry ID: $ENTRY_ID"

# 4. Verify entry exists
echo ""
echo "3. Verifying entry in API..."
curl -s http://localhost:5001/api/entries/$ENTRY_ID | python3 -m json.tool

# 5. Update entry
echo ""
echo "4. Updating entry..."
curl -s -X PUT http://localhost:5001/api/entries/$ENTRY_ID \
  -H "Content-Type: application/json" \
  -d '{"title":"Updated Test"}' | python3 -m json.tool

# 6. Delete entry
echo ""
echo "5. Deleting entry..."
curl -s -X DELETE http://localhost:5001/api/entries/$ENTRY_ID
echo "✅ Deleted"

echo ""
echo "✅ Full-stack test complete!"
echo "Now check the iOS app - entries should sync!"
```

Run with:
```bash
chmod +x test-fullstack.sh
./test-fullstack.sh
```

---

## 📊 Expected Results

### Successful Integration:
- ✅ App creates → API receives
- ✅ API creates → App receives
- ✅ Updates sync both ways
- ✅ Deletes sync both ways
- ✅ Data persists across restarts
- ✅ No data loss or corruption

### Performance:
- ✅ API responses < 1 second
- ✅ App updates smoothly
- ✅ No UI freezing
- ✅ Background operations work

---

## 🎬 For Presentation Demo

### Demo Flow:
1. **Show backend running:**
   ```bash
   make up
   make health
   ```

2. **Show empty API:**
   ```bash
   curl http://localhost:5001/api/entries
   # Returns: []
   ```

3. **Create entry in iOS app:**
   - Open app
   - Create new entry
   - Save

4. **Show entry in API:**
   ```bash
   curl http://localhost:5001/api/entries | python3 -m json.tool
   # Shows the entry you just created!
   ```

5. **Create entry via API:**
   ```bash
   curl -X POST http://localhost:5001/api/entries \
     -H "Content-Type: application/json" \
     -d '{"title":"From API","content":"Created via API"}'
   ```

6. **Show entry in app:**
   - Refresh app
   - Entry appears!

**This demonstrates full-stack integration!**

---

## ✅ Success Criteria

Your full-stack is working if:
- ✅ App can create entries that appear in API
- ✅ API can create entries that appear in app
- ✅ Updates work in both directions
- ✅ Deletes work in both directions
- ✅ Data persists correctly
- ✅ No crashes or errors

If all these work, your full-stack integration is complete! 🎉

