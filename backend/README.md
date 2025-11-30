# Spark Backend API

REST API service for the Spark journaling app.

## Features

- CRUD operations for journal entries
- Health check endpoint
- Persistent JSON storage
- CORS enabled for iOS app integration

## API Endpoints

- `GET /health` - Health check
- `GET /api/entries` - List all entries
- `GET /api/entries/<id>` - Get specific entry
- `POST /api/entries` - Create new entry
- `PUT /api/entries/<id>` - Update entry
- `DELETE /api/entries/<id>` - Delete entry
- `POST /api/entries/<id>/unlock` - Unlock entry

## Local Development

```bash
# Install dependencies
pip install -r requirements.txt

# Run the server
python app.py
```

The server will start on `http://localhost:5001` (when using docker-compose) or `http://localhost:5000` (when running locally)

## Testing

```bash
# Run all tests
pytest -v

# Run with coverage
pytest -v --cov=app --cov-report=term-missing
```

## Docker

```bash
# Build image
docker build -t spark-backend .

# Run container
docker run -p 5001:5000 -v $(pwd)/data:/data spark-backend
```

