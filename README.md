# Spark - Journaling App with DevOps Infrastructure

[![CI/CD Pipeline](https://github.com/daniahsn/SparkDevOps/actions/workflows/ci.yml/badge.svg)](https://github.com/daniahsn/SparkDevOps/actions/workflows/ci.yml)

## Project Description & Accomplishments

Spark is a journaling app with conditional unlock features. This repository demonstrates a complete DevOps infrastructure setup for containerization, CI/CD, automated testing, and deployment automation.

### DevOps Accomplishments

**Containerization:**
- **Docker**: Containerized Flask backend API with optimized Dockerfile
- **Docker Compose**: Multi-container orchestration with volume mounting for persistent data (`./data:/data`)
- **Health Checks**: Configured container health monitoring with automatic restart policies
- **Port Mapping**: Proper port configuration (`5001:5000`) for service exposure

**CI/CD Pipeline:**
- **GitHub Actions**: Automated CI/CD pipeline that runs on every push/PR to `main` or `develop` branches
- **Multi-Stage Validation**: Pipeline includes 4 independent jobs:
  1. **Lint**: Code quality checks using flake8
  2. **Test**: Automated pytest suite with coverage reporting
  3. **Build**: Docker image build verification
  4. **Docker Compose**: Full stack integration testing
- **Automated Quality Gates**: All jobs must pass before code can be merged
- **Coverage Reporting**: Integrated codecov for test coverage tracking

**Testing Infrastructure:**
- **Comprehensive Test Suite**: pytest-based tests covering all API endpoints, error handling, and edge cases
- **Coverage Reporting**: Test coverage tracking with detailed reports
- **Docker Testing**: Tests run both locally and in containerized environments
- **Integration Testing**: Docker Compose setup verified in CI pipeline

**Automation & Tooling:**
- **Makefile**: Standardized development commands for build, test, deploy, and cleanup
- **Reproducible Builds**: Docker ensures consistent environments across development, CI, and production
- **Environment Configuration**: Environment variables for flexible deployment (`DATA_FILE`, `PORT`, `FLASK_ENV`)

**Application Context:**
The backend API (`backend/app.py`) is a Flask REST API that manages journal entries. The DevOps infrastructure supports this application with:
- RESTful API endpoints (GET, POST, PUT, DELETE)
- Health check endpoint (`/health`) for monitoring
- JSON-based persistent storage
- CORS support for frontend integration

---

## Explanation of Relevant Code

### Dockerfile (`backend/Dockerfile`)

**Base Image (line 1):** Uses Python 3.11-slim base image for smaller container size (~45MB vs ~900MB for full Python image).

**Working Directory (line 3):** Sets `/app` as the working directory for all subsequent commands.

**Dependency Installation (lines 5-7):** Copies `requirements.txt` first (before app code) to leverage Docker layer caching. If dependencies don't change, Docker reuses this layer. `--no-cache-dir` reduces image size.

**Application Code (lines 9-12):** Copies application files (`app.py`, `test_app.py`, `pytest.ini`). These are separate from dependencies to optimize caching.

**Data Directory (line 15):** Creates `/data` directory for persistent storage (mounted via docker-compose volume).

**Port Exposure (line 18):** Documents that the container listens on port 5000 (doesn't publish it - that's done in docker-compose).

**Environment Variables (lines 21-22):** Sets Flask app name (`FLASK_APP=app.py`) and data file path (`DATA_FILE=/data/spark_entries.json`) as environment variables.

**Command (line 25):** Default command to run when container starts. Uses exec form (`CMD ["python", "app.py"]`) for proper signal handling.

### Docker Compose (`docker-compose.yml`)

**Service Definition (lines 1-2):** Defines a service named `backend`.

**Build Configuration (lines 3-5):** Builds image from `./backend` directory using `Dockerfile`. Context is the build directory.

**Container Name (line 6):** Sets explicit container name (`spark-backend`) instead of auto-generated one.

**Port Mapping (lines 7-8):** Maps host port 5001 to container port 5000. Format: `"host:container"`.

**Volume Mounting (lines 9-10):** Mounts `./data` directory on host to `/data` in container for persistent storage. Data survives container restarts.

**Environment Variables (lines 11-14):** Sets environment variables (`FLASK_ENV`, `PORT`, `DATA_FILE`) for the container. Overrides Dockerfile ENV values.

**Health Check (lines 15-20):** Configures health monitoring:
- `test`: Command to check health (hits `/health` endpoint)
- `interval`: Check every 30 seconds
- `timeout`: 10 second timeout per check
- `retries`: 3 consecutive failures mark unhealthy
- `start_period`: 40 second grace period before checks start (allows app startup)

**Restart Policy (line 21):** Automatically restarts container if it crashes, unless manually stopped (`restart: unless-stopped`).

### CI/CD Pipeline (`.github/workflows/ci.yml`)

**Workflow Trigger (lines 3-7):** Triggers pipeline on pushes or PRs to `main`/`develop` branches.

**Lint Job (lines 10-29):**
- Checks out code using `actions/checkout@v4`
- Sets up Python 3.11 using `actions/setup-python@v5`
- Installs flake8 and dependencies
- Runs flake8 linting (line 28: `|| true` prevents failure from stopping pipeline)
- Compiles Python files to catch syntax errors

**Test Job (lines 31-55):**
- Sets up Python 3.11 environment
- Installs dependencies from `requirements.txt`
- Runs pytest with coverage (line 49), generating terminal and XML reports
- Uploads XML coverage to codecov (line 55: `fail_ci_if_error: false` prevents coverage upload failures from failing the job)

**Build Job (lines 57-77):**
- `needs: [lint, test]` (line 60): Only runs if lint and test jobs pass
- Sets up Docker Buildx for building images
- Builds Docker image (line 69)
- Tests image by running container and checking health endpoint (lines 73-76)
- Cleans up test container (lines 76-77)

**Docker Compose Job (lines 79-93):**
- `needs: [lint, test]` (line 82): Runs in parallel with build job
- Builds services with docker-compose (line 89)
- Starts services in detached mode (line 90)
- Waits 10 seconds for startup (line 91)
- Tests health endpoint (line 92: `|| exit 1` fails job if health check fails)
- Stops and removes services (line 93)

### Test Code (`backend/test_app.py`)

**Test Fixture (lines 11-28):**
- Creates temporary JSON file for each test (line 15) using `tempfile.NamedTemporaryFile`
- Uses `monkeypatch` to override `DATA_FILE` environment variable (line 20)
- Enables Flask test mode (line 22)
- Yields test client, then cleans up temp file (lines 24-28)

**Sample Entry Fixture (lines 30-38):** Reusable test data fixture returning a sample journal entry dictionary for creating test entries.

**Test Examples:**
- `test_health_endpoint` (lines 40-46): Tests `/health` returns 200 with correct JSON
- `test_create_entry` (lines 48-57): Tests POST creates entry with 201 status and returns entry with ID
- `test_create_entry_missing_fields` (lines 59-64): Tests validation - returns 400 if required fields missing
- `test_get_entries` (lines 66-79): Tests GET returns list of entries
- `test_get_entry_by_id` (lines 81-94): Tests GET with ID returns specific entry
- `test_get_nonexistent_entry` (lines 96-99): Tests 404 for non-existent entry
- `test_update_entry` (lines 101-117): Tests PUT updates entry
- `test_delete_entry` (lines 126-140): Tests DELETE removes entry and verifies deletion
- `test_unlock_entry` (lines 147-159): Tests unlock endpoint sets `unlockedAt` timestamp

### Makefile (`Makefile`)

**PHONY Declaration (line 1):** Declares targets as phony (not files) so Make doesn't check for files with these names.

**Help Target (lines 4-14):** Default target shows available commands. `@` prefix suppresses echoing the command itself.

**Docker Commands:**
- `build` (lines 21-22): Runs `docker-compose build` to build images
- `up` (lines 24-27): Runs `docker-compose up -d` (detached mode) and prints helpful messages
- `down` (lines 29-30): Stops and removes containers
- `restart` (line 32): Chains `down` and `up` targets

**Test Command (lines 38-42):**
- Tries to run tests in Docker container first (line 40)
- Falls back to local pytest if Docker fails (line 41)
- Uses `||` for fallback logic

**Lint Command (lines 48-55):**
- Checks if flake8 is installed (line 50)
- Runs flake8 if available, otherwise falls back to Python compile check (line 54)

**Clean Command (lines 58-61):**
- `down -v`: Removes containers and volumes
- `system prune -f`: Cleans up unused Docker resources
- Removes JSON data files

---

## How to Test/View the DevOps Infrastructure

### Quick Start

**1. Start Backend with Docker Compose:**
```bash
make build
make up
# Verify: curl http://localhost:5001/health
```

**2. View Running Services:**
```bash
docker-compose ps
make logs  # View service logs
```

**3. Test Full Stack Integration (Optional):**
- Open `Spark.xcodeproj` in Xcode
- Select iOS Simulator or physical device and run (⌘R)
- **Note**: For physical devices, update `Spark/Services/APIClient.swift` baseURL to your Mac's IP address
- Verify app connects to backend and test data persistence: `curl http://localhost:5001/api/entries`

This verifies that the DevOps infrastructure (Docker, volume mounting, networking) properly supports the full application stack.

### Testing Containerization

**Test Docker Image Build:**
```bash
docker build -t spark-backend:latest ./backend
docker run -d -p 5001:5000 --name test-backend spark-backend:latest
curl http://localhost:5001/health
docker stop test-backend && docker rm test-backend
```

**Test Docker Compose:**
```bash
docker compose build
docker compose up -d
sleep 5
curl http://localhost:5001/health
docker compose down
```

**Verify Volume Mounting:**
```bash
make up
# Create data via API
curl -X POST http://localhost:5001/api/entries \
  -H "Content-Type: application/json" \
  -d '{"title": "Test", "content": "Test entry"}'
# Check persistent storage
cat data/spark_entries.json
make down
# Data persists in ./data directory
```

### Testing CI/CD Pipeline

**Local Testing (Simulate CI Steps):**

```bash
# Step 1: Lint (matches CI lint job)
pip install flake8
flake8 backend/app.py backend/test_app.py --max-line-length=100

# Step 2: Tests (matches CI test job)
pip install -r backend/requirements.txt
cd backend
pytest -v --cov=app --cov-report=term-missing --cov-report=xml

# Step 3: Build Docker image (matches CI build job)
docker build -t spark-backend:latest ./backend
docker run -d -p 5001:5000 --name test-backend spark-backend:latest
sleep 5
curl -f http://localhost:5001/health || exit 1
docker stop test-backend && docker rm test-backend

# Step 4: Docker Compose (matches CI docker-compose job)
docker compose build
docker compose up -d
sleep 10
curl -f http://localhost:5001/health || exit 1
docker compose down
```

**Trigger GitHub Actions Pipeline:**
- Push to `main` or `develop` branch → automatically triggers pipeline
- Create Pull Request → triggers pipeline for validation
- View in GitHub Actions tab → monitor all 4 jobs (lint, test, build, docker-compose)
- Check badge status → green badge indicates all checks passing

**Verify Pipeline Success:**
- All 4 jobs show green checkmarks
- Badge at top of README shows "passing"
- PR shows "All checks have passed"

### Automated Testing

**Run Tests Locally:**
```bash
make test
# or
cd backend && pytest -v --cov=app --cov-report=term-missing
```

**Run Tests in Docker:**
```bash
docker-compose exec backend pytest -v
```

**View Test Coverage:**
```bash
cd backend
pytest --cov=app --cov-report=html
open htmlcov/index.html  # View coverage report
```

### API Testing (Verify Backend Works)

```bash
# Health check
curl http://localhost:5001/health

# Create entry
curl -X POST http://localhost:5001/api/entries \
  -H "Content-Type: application/json" \
  -d '{"title": "Test", "content": "Test entry"}'

# Get all entries
curl http://localhost:5001/api/entries
```

### Cleanup

```bash
make down      # Stop services
make clean     # Remove containers, volumes, and data files
```
