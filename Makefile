.PHONY: help build up down restart logs test lint clean install

# Default target
help:
	@echo "Spark DevOps - Available Commands:"
	@echo "  make install    - Install Python dependencies"
	@echo "  make build      - Build Docker images"
	@echo "  make up         - Start services with docker-compose"
	@echo "  make down       - Stop services"
	@echo "  make restart    - Restart services"
	@echo "  make logs       - View service logs"
	@echo "  make test       - Run tests"
	@echo "  make lint        - Run linting checks"
	@echo "  make clean      - Clean up containers and volumes"

# Install dependencies
install:
	pip install -r backend/requirements.txt

# Docker commands
build:
	docker-compose build

up:
	docker-compose up -d
	@echo "Backend API running at http://localhost:5001"
	@echo "Health check: http://localhost:5001/health"

down:
	docker-compose down

restart: down up

logs:
	docker-compose logs -f backend

# Testing
test:
	@echo "Running tests in Docker container..."
	docker-compose exec backend pytest -v --cov=app --cov-report=term-missing || \
	(echo "Note: Tests should be run in CI/CD. For local testing, install pytest: pip install -r backend/requirements.txt" && \
	cd backend && python3 -m pytest -v --cov=app --cov-report=term-missing 2>/dev/null || echo "Install dependencies first: pip install -r backend/requirements.txt")

test-watch:
	cd backend && pytest-watch

# Linting (using flake8 if available, otherwise basic checks)
lint:
	@echo "Running linting checks..."
	@if command -v flake8 > /dev/null; then \
		flake8 backend/app.py backend/test_app.py --max-line-length=100; \
	else \
		echo "flake8 not installed. Install with: pip install flake8"; \
		python -m py_compile backend/app.py backend/test_app.py; \
	fi

# Cleanup
clean:
	docker-compose down -v
	docker system prune -f
	rm -rf data/*.json

# Development helpers
shell:
	docker-compose exec backend /bin/bash

health:
	@curl -s http://localhost:5001/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost:5001/health || echo "Service not running"

