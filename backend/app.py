"""
Spark Backend API
REST API for managing journal entries

This API provides endpoints for creating, reading, updating, and deleting
journal entries with conditional unlock features.
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
from datetime import datetime
import json
import os
import uuid
from typing import Optional, Dict, Any

app = Flask(__name__)
CORS(app)  # Enable CORS for iOS app

# Data storage file
DATA_FILE = os.getenv('DATA_FILE', '/data/spark_entries.json')

def ensure_data_dir():
    """Ensure data directory exists"""
    os.makedirs(os.path.dirname(DATA_FILE), exist_ok=True)

def load_entries() -> list:
    """Load entries from JSON file"""
    ensure_data_dir()
    if os.path.exists(DATA_FILE):
        try:
            with open(DATA_FILE, 'r') as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            return []
    return []

def save_entries(entries: list):
    """Save entries to JSON file"""
    ensure_data_dir()
    with open(DATA_FILE, 'w') as f:
        json.dump(entries, f, indent=2, default=str)

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'service': 'spark-backend'}), 200

@app.route('/api/entries', methods=['GET'])
def get_entries():
    """Get all journal entries"""
    entries = load_entries()
    return jsonify(entries), 200

@app.route('/api/entries/<entry_id>', methods=['GET'])
def get_entry(entry_id: str):
    """Get a specific journal entry by ID"""
    entries = load_entries()
    entry = next((e for e in entries if e.get('id') == entry_id), None)
    
    if not entry:
        return jsonify({'error': 'Entry not found'}), 404
    
    return jsonify(entry), 200

@app.route('/api/entries', methods=['POST'])
def create_entry():
    """Create a new journal entry"""
    data = request.get_json()
    
    # Validate required fields
    if not data or 'title' not in data or 'content' not in data:
        return jsonify({'error': 'Title and content are required'}), 400
    
    # Create entry with defaults
    entry = {
        'id': str(uuid.uuid4()),
        'title': data['title'],
        'content': data['content'],
        'creationDate': data.get('creationDate', datetime.utcnow().isoformat()),
        'geofence': data.get('geofence'),
        'weather': data.get('weather'),
        'emotion': data.get('emotion'),
        'earliestUnlock': data.get('earliestUnlock', datetime.utcnow().isoformat()),
        'unlockedAt': data.get('unlockedAt')
    }
    
    entries = load_entries()
    entries.append(entry)
    save_entries(entries)
    
    return jsonify(entry), 201

@app.route('/api/entries/<entry_id>', methods=['PUT'])
def update_entry(entry_id: str):
    """Update an existing journal entry"""
    data = request.get_json()
    entries = load_entries()
    
    entry_index = next((i for i, e in enumerate(entries) if e.get('id') == entry_id), None)
    
    if entry_index is None:
        return jsonify({'error': 'Entry not found'}), 404
    
    # Update entry fields
    entry = entries[entry_index]
    entry.update({
        'title': data.get('title', entry['title']),
        'content': data.get('content', entry['content']),
        'geofence': data.get('geofence', entry.get('geofence')),
        'weather': data.get('weather', entry.get('weather')),
        'emotion': data.get('emotion', entry.get('emotion')),
        'earliestUnlock': data.get('earliestUnlock', entry.get('earliestUnlock')),
        'unlockedAt': data.get('unlockedAt', entry.get('unlockedAt'))
    })
    
    save_entries(entries)
    return jsonify(entry), 200

@app.route('/api/entries/<entry_id>', methods=['DELETE'])
def delete_entry(entry_id: str):
    """Delete a journal entry"""
    entries = load_entries()
    original_count = len(entries)
    entries = [e for e in entries if e.get('id') != entry_id]
    
    if len(entries) == original_count:
        return jsonify({'error': 'Entry not found'}), 404
    
    save_entries(entries)
    return jsonify({'message': 'Entry deleted'}), 200

@app.route('/api/entries/<entry_id>/unlock', methods=['POST'])
def unlock_entry(entry_id: str):
    """Mark an entry as unlocked"""
    entries = load_entries()
    entry_index = next((i for i, e in enumerate(entries) if e.get('id') == entry_id), None)
    
    if entry_index is None:
        return jsonify({'error': 'Entry not found'}), 404
    
    entries[entry_index]['unlockedAt'] = datetime.utcnow().isoformat()
    save_entries(entries)
    
    return jsonify(entries[entry_index]), 200

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=os.getenv('FLASK_ENV') == 'development')

