# API Integration Setup Guide

## ✅ What's Been Done

The iOS app is now connected to the backend API!

### Files Created/Modified:
- ✅ `Spark/Services/APIClient.swift` - New API client service
- ✅ `Spark/Services/StorageService.swift` - Updated to use API

## 🚀 Quick Start

### 1. Start Backend
```bash
make up
make health  # Verify it's running
```

### 2. Configure API URL

Open `Spark/Services/APIClient.swift` and check the `baseURL`:

**For iOS Simulator:**
```swift
private let baseURL = "http://localhost:5001"
```
✅ Simulator can access localhost

**For Physical iPhone:**
```swift
private let baseURL = "http://192.168.1.XXX:5001"  // Your Mac's IP
```
❌ Physical devices can't use localhost

**Find your Mac's IP:**
```bash
ifconfig | grep 'inet ' | grep -v 127.0.0.1
```

### 3. Build and Run in Xcode
- Open `Spark.xcodeproj`
- Select simulator or device
- Press ⌘R to build and run

## 🔄 How It Works

### StorageService Toggle
In `StorageService.swift`, there's a toggle:
```swift
private let useAPI = true  // Set to false for local storage
```

- `useAPI = true` → Uses backend API
- `useAPI = false` → Uses local file storage (original behavior)

### API Operations
All CRUD operations now go through the API:
- **Load:** Fetches entries from `/api/entries`
- **Create:** POSTs to `/api/entries`
- **Update:** PUTs to `/api/entries/{id}`
- **Delete:** DELETEs `/api/entries/{id}`

### Fallback Behavior
If API fails, the app falls back to local storage automatically.

## 🧪 Testing

### Test API Connection
1. Start backend: `make up`
2. Create entry in app
3. Check backend logs: `make logs`
4. Verify entry in API: `curl http://localhost:5001/api/entries`

### Test Both Directions
1. Create entry in app → Check API
2. Create entry via API → Check app (refresh)
3. Update entry in app → Check API
4. Delete entry in app → Check API

## 🐛 Troubleshooting

### App shows no entries
- ✅ Check backend is running: `make health`
- ✅ Check API URL is correct in `APIClient.swift`
- ✅ Check Xcode console for error messages
- ✅ Try setting `useAPI = false` to test local storage

### Network errors
- ✅ For simulator: Use `http://localhost:5001`
- ✅ For device: Use your Mac's IP address
- ✅ Make sure Mac and iPhone are on same WiFi
- ✅ Check firewall isn't blocking port 5001

### Date format issues
- ✅ Dates are encoded/decoded as ISO8601
- ✅ Backend returns dates as ISO strings
- ✅ Swift decodes them automatically

## 📱 For Presentation Demo

### Best Demo Flow:
1. **Show backend running:**
   ```bash
   make up
   make health
   ```

2. **Show API directly:**
   ```bash
   curl http://localhost:5001/api/entries
   ```

3. **Show iOS app:**
   - Open app in Xcode
   - Create entry in app
   - Show it appears in API
   - Show full integration!

### What to Say:
"The iOS app is now fully integrated with our backend API. When users create entries in the app, they're stored in the backend. This demonstrates our complete full-stack DevOps infrastructure."

## ✅ Verification Checklist

- [ ] Backend running (`make up`)
- [ ] API URL configured correctly
- [ ] App builds without errors
- [ ] Can create entries in app
- [ ] Entries appear in API
- [ ] Can view entries in app
- [ ] Updates sync to API
- [ ] Deletes work correctly

## 🎯 Next Steps (Optional)

- Add authentication
- Add error handling UI
- Add loading indicators
- Add offline mode support
- Add sync conflict resolution

