# Spark - Journaling App with DevOps Infrastructure

[![CI/CD Pipeline](https://github.com/daniahsn/SparkDevOps/actions/workflows/ci.yml/badge.svg)](https://github.com/daniahsn/SparkDevOps/actions/workflows/ci.yml)

## Authors

**Names:** Sangitha, Dania and Julius

## Project Mentor

**Name:** Stacy

**Date of Meeting:** October 31

---

## A4 Submission

You can access the A4 submission here: https://docs.google.com/document/d/1hZSMWkMfXquq6jYkNfozzqEGnjY6hOqaJDpuf-w7EPE/edit?usp=sharing

---

## Project Overview

Spark is a journaling app with conditional unlock features. This repository includes:
- **iOS App**: SwiftUI-based journaling application (Xcode project)
- **Backend API**: Flask-based REST API for managing journal entries
- **DevOps Infrastructure**: Containerization, CI/CD, and automation

---

## DevOps Infrastructure

This project includes a complete DevOps setup with containerization, automated testing, and CI/CD pipelines.

### Architecture

- **Backend API**: Python Flask REST API (`backend/`)
- **Containerization**: Docker with Docker Compose orchestration
- **CI/CD**: GitHub Actions for automated testing and building
- **Testing**: Pytest with coverage reporting
- **Automation**: Makefile for standardized commands

### Quick Start (Backend)

#### Prerequisites

- Docker and Docker Compose installed
- Python 3.11+ (for local development)
- Make (optional, for convenience commands)

#### Using Docker Compose (Recommended)

```bash
# Build and start services
make build
make up

# Or use docker-compose directly
docker-compose up -d
```

The backend API will be available at `http://localhost:5001`

#### Using Makefile Commands

```bash
make help          # Show all available commands
make build         # Build Docker images
make up            # Start services
make down          # Stop services
make test          # Run tests
make lint          # Run linting checks
make logs          # View service logs
make clean         # Clean up containers and volumes
```

#### Local Development (Without Docker)

```bash
# Install dependencies
make install
# or
pip install -r backend/requirements.txt

# Run the application
cd backend
python app.py
```

### API Endpoints

- `GET /health` - Health check
- `GET /api/entries` - Get all journal entries
- `GET /api/entries/<id>` - Get a specific entry
- `POST /api/entries` - Create a new entry
- `PUT /api/entries/<id>` - Update an entry
- `DELETE /api/entries/<id>` - Delete an entry
- `POST /api/entries/<id>/unlock` - Unlock an entry

### Testing

```bash
# Run all tests
make test

# Run tests with coverage
cd backend
pytest -v --cov=app --cov-report=term-missing
```

### CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/ci.yml`) automatically:

1. **Lints** code on every push/PR
2. **Runs tests** with coverage reporting
3. **Builds Docker images** to verify containerization
4. **Tests Docker Compose** setup

The pipeline runs on:
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

### Project Structure

```
SparkDevOps/
├── backend/              # Backend API service
│   ├── app.py           # Flask application
│   ├── test_app.py      # Test suite
│   ├── requirements.txt # Python dependencies
│   └── Dockerfile       # Container definition
├── Spark/               # iOS app (SwiftUI)
├── docker-compose.yml   # Service orchestration
├── Makefile            # Automation commands
├── .github/
│   └── workflows/
│       └── ci.yml      # CI/CD pipeline
└── data/               # Persistent data storage
```

---

## iOS App (Xcode Project)

### Prerequisites

* macOS with the latest version compatible with your Xcode installation
* Xcode installed from the Mac App Store

### Clone the Repository

```bash
git clone <repository-url>
cd SparkDevOps
```

### Open the Project in Xcode

1. Locate the `.xcodeproj` or `.xcworkspace` file inside the cloned repository.
2. Double-click to open it in Xcode, **or** open via Terminal:

   ```bash
   open *.xcodeproj
   ```

   or

   ```bash
   open *.xcworkspace
   ```

### Build and Run

1. In XCode select your iPhone or a simulator phone (preferably one of the newer ones)
2. Press the play button to build and run the application.

---

## Development Timeline

- **Nov 13 – 17**: Containerize the backend and verify with Docker Compose locally
- **Nov 18 – 22**: Add tests and configure CI to run linting, tests, and builds
- **Nov 23 – 25**: Polish documentation, Makefile automation, and reproducibility checks

---

## Contributing

1. Create a feature branch
2. Make your changes
3. Ensure tests pass: `make test`
4. Ensure linting passes: `make lint`
5. Submit a pull request

The CI pipeline will automatically validate your changes.

---

## Questions?

If you have questions or encounter issues, please reach out to us! 
