# iOS Simulator Full-Stack Testing Guide

## Quick Guide for Testing on iOS Simulator

Since you're using **iOS Simulator**, testing is simpler because the simulator can access `localhost` directly!

---

## ✅ Pre-Flight Checklist

- [ ] Backend running (`make up`)
- [ ] Backend healthy (`make health`)
- [ ] `APIClient.swift` has `baseURL = "http://localhost:5001"`
- [ ] `StorageService.swift` has `useAPI = true`
- [ ] Xcode project open
- [ ] Simulator selected (iPhone 14 or newer recommended)

---

## 🚀 Quick Test (5 minutes)

### 1. Start Backend
```bash
make up
make health
```

**Expected output:**
```json
{
    "service": "spark-backend",
    "status": "healthy"
}
```

### 2. Open Xcode & Run App
1. Open `Spark.xcodeproj` in Xcode
2. Select a simulator (iPhone 14 Pro recommended)
3. Press **⌘R** or click the Play button
4. Wait for app to launch

### 3. Test App → API
**In iOS App:**
1. Tap the **"+"** or **"Create"** button
2. Fill in:
   - Title: "Test from Simulator"
   - Content: "Testing full-stack integration"
3. Save the entry

**In Terminal (verify):**
```bash
curl http://localhost:5001/api/entries | python3 -m json.tool
```

**Expected:**
- Your entry appears in the API response
- Entry has title, content, ID, dates, etc.

### 4. Test API → App
**In Terminal:**
```bash
curl -X POST http://localhost:5001/api/entries \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test from API",
    "content": "Created via curl command",
    "emotion": "happy"
  }' | python3 -m json.tool
```

**In iOS App:**
1. Pull down to refresh (or restart app)
2. Look for "Test from API" entry

**Expected:**
- Entry appears in app
- Data matches what you sent to API

---

## 🧪 Complete Test Scenarios

### Scenario 1: Create in App, Verify in API
1. **App:** Create entry "Morning Thoughts"
2. **Terminal:** `curl http://localhost:5001/api/entries | python3 -m json.tool`
3. **Verify:** Entry appears with correct data

### Scenario 2: Create in API, Verify in App
1. **Terminal:** Create entry via curl
2. **App:** Refresh (pull down or restart)
3. **Verify:** Entry appears in app

### Scenario 3: Update in App, Verify in API
1. **App:** Edit an entry, change title
2. **Terminal:** Get entry by ID, verify update
3. **Verify:** Changes reflected in API

### Scenario 4: Delete in App, Verify in API
1. **App:** Delete an entry
2. **Terminal:** Check entries list
3. **Verify:** Entry removed from API

---

## 🔍 Monitoring During Test

### Watch Backend Logs
**In a separate terminal:**
```bash
make logs
# or
docker-compose logs -f backend
```

**What to watch for:**
- `POST /api/entries` - Entry created
- `GET /api/entries` - Entries fetched
- `PUT /api/entries/<id>` - Entry updated
- `DELETE /api/entries/<id>` - Entry deleted

### Watch Xcode Console
**In Xcode:**
1. View → Debug Area → Activate Console (⌘⇧Y)
2. Look for:
   - `📂 Loaded X entries from API` ✅
   - `✅ Created entry via API` ✅
   - `❌ Failed to...` (if errors)

---

## 🐛 Troubleshooting for Simulator

### "No entries" in app but API has data
**Check:**
1. Backend running? `make health`
2. `useAPI = true` in StorageService?
3. `baseURL = "http://localhost:5001"` in APIClient?
4. Xcode console for errors?

**Fix:**
- Restart app in Xcode
- Check console for error messages
- Verify backend is accessible: `curl http://localhost:5001/health`

### Network errors in console
**Check:**
- Backend running? `make up`
- Correct port? Backend should be on 5001
- CORS enabled? (It is in backend)

**Fix:**
```bash
# Restart backend
make down
make up

# Verify
make health
```

### App crashes or freezes
**Check:**
- Xcode console for error messages
- Backend logs for API errors
- Date format issues (should work automatically)

**Fix:**
- Check console errors
- Restart app
- Verify API returns valid JSON

---

## ✅ Success Indicators

Your full-stack is working if you see:

**In Terminal:**
- ✅ `curl http://localhost:5001/api/entries` shows entries created in app
- ✅ Backend logs show API requests from app
- ✅ No 404 or 500 errors

**In Xcode Console:**
- ✅ `📂 Loaded X entries from API`
- ✅ `✅ Created entry via API`
- ✅ No network errors

**In iOS App:**
- ✅ Entries created in app appear in list
- ✅ Entries created via API appear in app
- ✅ Updates and deletes work
- ✅ No crashes or freezes

---

## 🎬 Demo Flow for Presentation

### Perfect Demo Sequence:

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
   - Open app in simulator
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
   - Refresh app (pull down)
   - Entry appears!

**This demonstrates complete full-stack integration!**

---

## 📋 Quick Reference Commands

```bash
# Start backend
make up

# Check health
make health

# View logs
make logs

# Get all entries
curl http://localhost:5001/api/entries | python3 -m json.tool

# Create entry
curl -X POST http://localhost:5001/api/entries \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","content":"Test"}'

# Get specific entry (replace <ID>)
curl http://localhost:5001/api/entries/<ID> | python3 -m json.tool

# Update entry
curl -X PUT http://localhost:5001/api/entries/<ID> \
  -H "Content-Type: application/json" \
  -d '{"title":"Updated"}'

# Delete entry
curl -X DELETE http://localhost:5001/api/entries/<ID>
```

---

## 💡 Pro Tips for Simulator

1. **Keep terminal and Xcode open side-by-side**
   - Terminal for API testing
   - Xcode for app testing

2. **Use Xcode console to see API calls**
   - Shows when app makes requests
   - Shows success/error messages

3. **Test both directions**
   - App → API (create in app, check API)
   - API → App (create via API, check app)

4. **Watch backend logs**
   - See requests in real-time
   - Debug issues quickly

5. **Practice the demo flow**
   - Run through it a few times
   - Know what to say for each step

---

## ✅ Final Checklist

Before presentation, verify:
- [ ] Backend starts successfully
- [ ] App connects to API
- [ ] Create in app → Appears in API
- [ ] Create in API → Appears in app
- [ ] Updates work both ways
- [ ] Deletes work both ways
- [ ] No crashes or errors
- [ ] Demo flow practiced

If all checked, you're ready! 🎉


