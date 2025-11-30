FROM python:3.11-slim
# INTENTIONAL ERROR FOR TESTING (FORK ONLY - DO NOT MERGE)
RUN invalid-command-that-will-fail

WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py .
COPY test_app.py .
COPY pytest.ini .

# Create data directory
RUN mkdir -p /data

# Expose port
EXPOSE 5000

# Set environment variables
ENV FLASK_APP=app.py
ENV DATA_FILE=/data/spark_entries.json

# Run the application
CMD ["python", "app.py"]

