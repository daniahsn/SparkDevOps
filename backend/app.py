"""
Spark Backend API
REST API for managing journal entries

This API provides endpoints for creating, reading, updating, and deleting
journal entries with conditional unlock features.
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
from datetime import datetime, timezone
import json
import os
import uuid
from typing import Optional, Dict, Any

app = Flask(__name__)
CORS(app)  # Enable CORS for iOS app

# Data storage file
DATA_FILE = os.getenv('DATA_FILE', '/data/spark_entries.json')

def format_iso8601(dt: datetime) -> str:
    """Format datetime as ISO8601 string with timezone (required for Swift)"""
    if dt.tzinfo is None:
        # If no timezone, assume UTC
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.isoformat().replace('+00:00', 'Z')

def parse_date(date_str: Optional[str]) -> Optional[str]:
    """Parse and normalize date string to ISO8601 with timezone"""
    if not date_str:
        return None
    try:
        # If already ends with Z, it's properly formatted
        if isinstance(date_str, str) and date_str.endswith('Z'):
            return date_str
        
        # Replace Z with +00:00 for parsing if present
        if 'Z' in str(date_str):
            date_str = str(date_str).replace('Z', '+00:00')
        
        # Parse the date
        dt = datetime.fromisoformat(str(date_str))
        
        # If no timezone info, assume UTC
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        
        # Format with timezone (will add Z)
        return format_iso8601(dt)
    except (ValueError, AttributeError, TypeError) as e:
        # If parsing fails, log and return the original string (better than None)
        print(f"Warning: Failed to parse date '{date_str}': {e}")
        # Try to add Z if it looks like a date string
        if isinstance(date_str, str) and 'T' in date_str and not date_str.endswith('Z'):
            return date_str + 'Z'
        return date_str

def normalize_entry(entry: dict) -> dict:
    """Normalize entry dates to ISO8601 format with timezone"""
    normalized = entry.copy()
    if 'creationDate' in normalized and normalized['creationDate']:
        parsed = parse_date(normalized['creationDate'])
        if parsed:
            normalized['creationDate'] = parsed
    if 'earliestUnlock' in normalized and normalized['earliestUnlock']:
        parsed = parse_date(normalized['earliestUnlock'])
        if parsed:
            normalized['earliestUnlock'] = parsed
    if 'unlockedAt' in normalized and normalized['unlockedAt']:
        parsed = parse_date(normalized['unlockedAt'])
        if parsed:
            normalized['unlockedAt'] = parsed
    return normalized

def ensure_data_dir():
    """Ensure data directory exists"""
    os.makedirs(os.path.dirname(DATA_FILE), exist_ok=True)

def load_entries() -> list:
    """Load entries from JSON file and normalize dates"""
    ensure_data_dir()
    if os.path.exists(DATA_FILE):
        try:
            with open(DATA_FILE, 'r') as f:
                entries = json.load(f)
                # Normalize all entry dates
                return [normalize_entry(entry) for entry in entries]
        except (json.JSONDecodeError, IOError):
            return []
    return []

def save_entries(entries: list):
    """Save entries to JSON file"""
    ensure_data_dir()
    # Use atomic write to avoid file locking issues
    import tempfile
    import shutil
    temp_file = DATA_FILE + '.tmp'
    try:
        with open(temp_file, 'w') as f:
            json.dump(entries, f, indent=2, default=str)
        shutil.move(temp_file, DATA_FILE)
    except Exception as e:
        print(f"Error saving entries: {e}")
        if os.path.exists(temp_file):
            os.remove(temp_file)
        raise

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'service': 'spark-backend'}), 200

@app.route('/api/entries', methods=['GET'])
def get_entries():
    """Get all journal entries"""
    entries = load_entries()
    # Ensure all dates are normalized before returning
    normalized_entries = [normalize_entry(entry) for entry in entries]
    return jsonify(normalized_entries), 200

@app.route('/api/entries/<entry_id>', methods=['GET'])
def get_entry(entry_id: str):
    """Get a specific journal entry by ID"""
    entries = load_entries()
    # Case-insensitive UUID comparison
    entry_id_lower = entry_id.lower()
    entry = next((e for e in entries if e.get('id', '').lower() == entry_id_lower), None)
    
    if not entry:
        return jsonify({'error': 'Entry not found'}), 404
    
    # Normalize dates before returning
    return jsonify(normalize_entry(entry)), 200

@app.route('/api/entries', methods=['POST'])
def create_entry():
    """Create a new journal entry"""
    data = request.get_json()
    
    # Validate required fields
    if not data or 'title' not in data or 'content' not in data:
        return jsonify({'error': 'Title and content are required'}), 400
    
    # Create entry with defaults
    now = datetime.now(timezone.utc)
    entry = {
        'id': str(uuid.uuid4()),
        'title': data['title'],
        'content': data['content'],
        'creationDate': parse_date(data.get('creationDate')) or format_iso8601(now),
        'geofence': data.get('geofence'),
        'weather': data.get('weather'),
        'emotion': data.get('emotion'),
        'earliestUnlock': parse_date(data.get('earliestUnlock')) or format_iso8601(now),
        'unlockedAt': parse_date(data.get('unlockedAt'))
    }
    
    entries = load_entries()
    entries.append(entry)
    save_entries(entries)
    
    # Normalize before returning
    return jsonify(normalize_entry(entry)), 201

@app.route('/api/entries/<entry_id>', methods=['PUT'])
def update_entry(entry_id: str):
    """Update an existing journal entry"""
    data = request.get_json()
    entries = load_entries()
    
    # Case-insensitive UUID comparison
    entry_id_lower = entry_id.lower()
    entry_index = next((i for i, e in enumerate(entries) if e.get('id', '').lower() == entry_id_lower), None)
    
    if entry_index is None:
        return jsonify({'error': 'Entry not found'}), 404
    
    # Update entry fields
    entry = entries[entry_index]
    
    # Only update fields that are provided and not empty
    # This allows partial updates without overwriting existing data
    if 'title' in data and data['title']:
        entry['title'] = data['title']
    if 'content' in data and data['content']:
        entry['content'] = data['content']
    if 'geofence' in data:
        entry['geofence'] = data['geofence']  # Can be None to clear
    if 'weather' in data:
        entry['weather'] = data['weather']  # Can be None to clear
    if 'emotion' in data:
        entry['emotion'] = data['emotion']  # Can be None to clear
    if 'earliestUnlock' in data:
        parsed = parse_date(data.get('earliestUnlock'))
        if parsed:
            entry['earliestUnlock'] = parsed
    if 'unlockedAt' in data:
        parsed = parse_date(data.get('unlockedAt'))
        if parsed:
            entry['unlockedAt'] = parsed
        elif data.get('unlockedAt') is None:
            # Explicitly allow setting to None to lock an entry
            entry['unlockedAt'] = None
    
    save_entries(entries)
    # Normalize before returning
    return jsonify(normalize_entry(entry)), 200

@app.route('/api/entries/<entry_id>', methods=['DELETE'])
def delete_entry(entry_id: str):
    """Delete a journal entry"""
    entries = load_entries()
    original_count = len(entries)
    # Case-insensitive UUID comparison
    entry_id_lower = entry_id.lower()
    entries = [e for e in entries if e.get('id', '').lower() != entry_id_lower]
    
    if len(entries) == original_count:
        return jsonify({'error': 'Entry not found'}), 404
    
    save_entries(entries)
    return jsonify({'message': 'Entry deleted'}), 200

@app.route('/api/entries/<entry_id>/unlock', methods=['POST'])
def unlock_entry(entry_id: str):
    """Mark an entry as unlocked"""
    entries = load_entries()
    # Case-insensitive UUID comparison
    entry_id_lower = entry_id.lower()
    entry_index = next((i for i, e in enumerate(entries) if e.get('id', '').lower() == entry_id_lower), None)
    
    if entry_index is None:
        return jsonify({'error': 'Entry not found'}), 404
    
    entries[entry_index]['unlockedAt'] = format_iso8601(datetime.now(timezone.utc))
    save_entries(entries)
    
    # Normalize before returning
    return jsonify(normalize_entry(entries[entry_index])), 200

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=os.getenv('FLASK_ENV') == 'development')

