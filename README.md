# Spark - Journaling App with DevOps Infrastructure

[![CI/CD Pipeline](https://github.com/daniahsn/SparkDevOps/actions/workflows/ci.yml/badge.svg)](https://github.com/daniahsn/SparkDevOps/actions/workflows/ci.yml)

@ -27,6 +27,124 @@ Spark is a journaling app with conditional unlock features. This repository incl
- **Backend API**: Flask-based REST API for managing journal entries
- **DevOps Infrastructure**: Containerization, CI/CD, and automation

### What We've Accomplished

**Full-Stack Journaling Application:**
- Built a complete iOS journaling app using SwiftUI with a modern, intuitive interface
- Created a RESTful backend API using Flask with full CRUD operations for journal entries
- Implemented conditional unlock system that allows entries to be locked behind location, weather, emotion, or time-based conditions
- Integrated real-time location services, weather API, and emotion tracking

**DevOps & Infrastructure:**
- Containerized the backend using Docker with proper health checks and volume mounting
- Set up Docker Compose for easy local development and deployment
- Implemented CI/CD pipeline using GitHub Actions that automatically runs tests, linting, and builds
- Created comprehensive test suite with pytest and coverage reporting
- Built Makefile for standardized development commands

**Key Features:**
- **Conditional Unlocks**: Entries can be locked behind:
  - **Location-based**: Unlock when you return to a specific location (geofencing)
  - **Weather-based**: Unlock when specific weather conditions occur
  - **Emotion-based**: Unlock when you're feeling a specific emotion
  - **Time-based**: Unlock after a certain date/time
- **Real-time Monitoring**: The app continuously monitors location, weather, and emotion to automatically unlock entries when conditions are met
- **Persistent Storage**: All entries are stored in JSON format with proper date/time handling
- **Modern UI**: Beautiful SwiftUI interface with custom branding, animations, and responsive design

---

## Code Explanation & Architecture

### Backend API (`backend/app.py`)

The Flask backend provides a RESTful API for managing journal entries. Key components:

**Entry Management:**
- **Date Handling**: The API normalizes all dates to ISO8601 format with timezone (required for Swift compatibility). See `format_iso8601()` and `parse_date()` functions (lines 23-58)
- **Data Persistence**: Entries are stored in JSON format using atomic writes to prevent file corruption. See `save_entries()` function (lines 94-109)
- **CORS Support**: Enabled for iOS app integration (line 18)

**API Endpoints:**
- `GET /health` - Health check endpoint for monitoring
- `GET /api/entries` - Retrieve all journal entries
- `GET /api/entries/<id>` - Get a specific entry by UUID (case-insensitive)
- `POST /api/entries` - Create a new entry with validation
- `PUT /api/entries/<id>` - Update an entry (supports partial updates)
- `DELETE /api/entries/<id>` - Delete an entry
- `POST /api/entries/<id>/unlock` - Manually unlock an entry

**Key Implementation Details:**
- All entries are normalized before being returned to ensure consistent date formatting
- UUID comparison is case-insensitive for better compatibility
- Partial updates are supported - only provided fields are updated
- Atomic file writes prevent data corruption during concurrent access

### iOS App Architecture

**Main Components:**

1. **AppEnvironment** (`Spark/AppEnvironment.swift`):
   - Manages shared services (Location, Weather, Emotion, Storage)
   - Provides dependency injection through SwiftUI's environment system

2. **Services Layer** (`Spark/Services/`):
   - **APIClient.swift**: Handles all HTTP requests to the backend API
     - Uses async/await for modern Swift concurrency
     - Includes comprehensive error handling and logging
     - Configurable base URL for different environments (simulator vs physical device)
   - **StorageService.swift**: Manages local entry storage and syncs with backend
   - **LocationService.swift**: Handles CoreLocation integration and geofencing
   - **WeatherService.swift**: Fetches weather data from external API
   - **EmotionService.swift**: Tracks current user emotion state
   - **UnlockService.swift**: Core logic for determining if an entry should unlock
     - Checks all conditions (location, weather, emotion, time)
     - Returns `true` only if all set conditions are met

3. **Views**:
   - **HomeView.swift**: Main screen showing mood picker, status cards, and recently unlocked entries
   - **CreateView.swift**: Multi-step flow for creating new entries with unlock conditions
   - **SearchView.swift**: Search and filter entries
   - **NoteDetailView.swift**: View individual entry details

**Unlock Logic** (`Spark/Services/UnlockService.swift`):
The unlock service implements the core conditional unlock feature:
- If an entry has no conditions set, it unlocks immediately
- Location: Checks if current location is within the geofence radius
- Weather: Compares current weather with required weather condition
- Emotion: Matches current emotion with required emotion
- Time: Checks if current time is after `earliestUnlock` date
- All conditions must be satisfied simultaneously for unlock

**Data Model**:
- `SparkEntry`: Core data structure with fields for title, content, unlock conditions, and metadata
- All dates use ISO8601 format for compatibility between Swift and Python

### DevOps Infrastructure

**Docker Setup** (`docker-compose.yml`):
- Single service configuration for the backend API
- Volume mounting for persistent data storage (`./data:/data`)
- Health checks configured for container monitoring
- Port mapping: `5001:5000` (host:container)

**CI/CD Pipeline** (`.github/workflows/ci.yml`):
- Runs on every push/PR to `main` or `develop` branches
- Steps:
  1. Lint code using flake8
  2. Run pytest with coverage reporting
  3. Build Docker image
  4. Test Docker Compose setup
- Ensures code quality before merging

**Makefile**:
Provides standardized commands for common operations:
- `make build` - Build Docker images
- `make up` - Start services
- `make test` - Run test suite
- `make lint` - Run linting checks
- See `make help` for full list

---

## DevOps Infrastructure
@ -176,6 +294,198 @@ cd SparkDevOps
1. In XCode select your iPhone or a simulator phone (preferably one of the newer ones)
2. Press the play button to build and run the application.

**Important: Backend Connection**
- The iOS app connects to the backend API at `http://localhost:5001` (for iOS Simulator)
- For physical devices, update `APIClient.swift` baseURL to your Mac's IP address:
  ```swift
  private let baseURL = "http://<your-mac-ip>:5001"
  ```
  Find your Mac's IP with: `ifconfig | grep 'inet '`

**Testing the Full Stack:**

1. **Start the Backend:**
   ```bash
   make up
   # Verify it's running:
   curl http://localhost:5001/health
   ```

2. **Run the iOS App:**
   - Open the project in Xcode
   - Select a simulator or device
   - Build and run (⌘R)

3. **Test Features:**
   - **Create Entry**: Tap "Create" tab → Enter title/content → Set unlock conditions → Save
   - **View Entries**: Check "Home" tab for recently unlocked entries
   - **Unlock Conditions**: 
     - Set location lock and move to that location
     - Set weather lock and wait for matching weather
     - Set emotion lock and select matching emotion
   - **Search**: Use "Search" tab to find entries

---

## How to Test/View What You've Built

### Backend API Testing

**1. Health Check:**
```bash
curl http://localhost:5001/health
# Expected: {"status": "healthy", "service": "spark-backend"}
```

**2. Create an Entry:**
```bash
curl -X POST http://localhost:5001/api/entries \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Entry",
    "content": "This is a test journal entry",
    "emotion": "happy",
    "weather": "clear"
  }'
```

**3. Get All Entries:**
```bash
curl http://localhost:5001/api/entries
```

**4. Get Specific Entry:**
```bash
# Replace <entry-id> with actual UUID from create response
curl http://localhost:5001/api/entries/<entry-id>
```

**5. Update an Entry:**
```bash
curl -X PUT http://localhost:5001/api/entries/<entry-id> \
  -H "Content-Type: application/json" \
  -d '{"title": "Updated Title"}'
```

**6. Unlock an Entry:**
```bash
curl -X POST http://localhost:5001/api/entries/<entry-id>/unlock
```

**7. Delete an Entry:**
```bash
curl -X DELETE http://localhost:5001/api/entries/<entry-id>
```

### Automated Testing

**Run All Tests:**
```bash
make test
```

**Run Tests with Coverage:**
```bash
cd backend
pytest -v --cov=app --cov-report=term-missing
```

**Run Tests in Docker:**
```bash
docker-compose exec backend pytest -v
```

**View Test Coverage:**
The test suite (`backend/test_app.py`) covers:
- Health check endpoint
- CRUD operations (Create, Read, Update, Delete)
- Entry unlocking
- Error handling (404s, validation errors)
- Date normalization

### iOS App Testing

**Manual Testing Checklist:**

1. **Entry Creation:**
   - ✅ Create entry with title and content
   - ✅ Set location-based unlock condition
   - ✅ Set weather-based unlock condition
   - ✅ Set emotion-based unlock condition
   - ✅ Set time-based unlock (earliestUnlock)
   - ✅ Create entry without any conditions (should unlock immediately)

2. **Entry Viewing:**
   - ✅ View all entries on Home screen
   - ✅ View recently unlocked entries
   - ✅ View entry details
   - ✅ Search entries

3. **Unlock Conditions:**
   - ✅ Location: Move to geofence location → entry unlocks
   - ✅ Weather: Wait for matching weather → entry unlocks
   - ✅ Emotion: Select matching emotion → entry unlocks
   - ✅ Time: Wait until earliestUnlock date → entry unlocks
   - ✅ Multiple conditions: All must be met simultaneously

4. **UI/UX:**
   - ✅ Mood picker updates current emotion
   - ✅ Status cards show current weather and location
   - ✅ Refresh button updates all data
   - ✅ Smooth navigation between screens
   - ✅ Empty states display correctly

**Testing Unlock Conditions:**

1. **Location Unlock:**
   - Create entry with geofence at your current location
   - Move away, then return to location
   - Entry should unlock automatically

2. **Weather Unlock:**
   - Create entry with current weather condition
   - Wait for weather to change, then return to original condition
   - Entry should unlock

3. **Emotion Unlock:**
   - Create entry with specific emotion
   - Select that emotion in mood picker
   - Entry should unlock immediately

4. **Time Unlock:**
   - Create entry with `earliestUnlock` set to future date
   - Entry should remain locked until that date
   - After date passes, entry unlocks (if other conditions met)

### Viewing Logs

**Backend Logs:**
```bash
make logs
# or
docker-compose logs -f backend
```

**Check Service Status:**
```bash
make health
# or
curl http://localhost:5001/health | python3 -m json.tool
```

### Data Inspection

**View Stored Entries:**
```bash
cat data/spark_entries.json | python3 -m json.tool
```

**Clear All Data:**
```bash
make clean
# This removes containers, volumes, and data files
```

---

## Development Timeline
