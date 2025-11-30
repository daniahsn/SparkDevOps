"""
Tests for Spark Backend API
"""

import pytest
import json
import os
import tempfile
from app import app as flask_app

@pytest.fixture
def client(monkeypatch):
    """Create a test client"""
    # Use a temporary file for testing
    with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.json') as f:
        test_data_file = f.name
    
    # Import app module to patch DATA_FILE
    import app as app_module
    monkeypatch.setattr(app_module, 'DATA_FILE', test_data_file)
    
    flask_app.config['TESTING'] = True
    with flask_app.test_client() as client:
        yield client
    
    # Cleanup
    if os.path.exists(test_data_file):
        os.unlink(test_data_file)

@pytest.fixture
def sample_entry():
    """Sample journal entry for testing"""
    return {
        'title': 'Test Entry',
        'content': 'This is a test journal entry',
        'emotion': 'happy',
        'weather': 'clear'
    }

def test_health_endpoint(client):
    """Test health check endpoint"""
    response = client.get('/health')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['status'] == 'healthy'
    assert data['service'] == 'spark-backend'

def test_create_entry(client, sample_entry):
    """Test creating a new entry"""
    response = client.post('/api/entries', 
                          data=json.dumps(sample_entry),
                          content_type='application/json')
    assert response.status_code == 201
    data = json.loads(response.data)
    assert data['title'] == sample_entry['title']
    assert data['content'] == sample_entry['content']
    assert 'id' in data

def test_create_entry_missing_fields(client):
    """Test creating entry without required fields"""
    response = client.post('/api/entries',
                          data=json.dumps({'content': 'Missing title'}),
                          content_type='application/json')
    assert response.status_code == 400

def test_get_entries(client, sample_entry):
    """Test getting all entries"""
    # Create an entry first
    client.post('/api/entries',
               data=json.dumps(sample_entry),
               content_type='application/json')
    
    # Get all entries
    response = client.get('/api/entries')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert isinstance(data, list)
    assert len(data) == 1
    assert data[0]['title'] == sample_entry['title']

def test_get_entry_by_id(client, sample_entry):
    """Test getting a specific entry by ID"""
    # Create an entry
    create_response = client.post('/api/entries',
                                 data=json.dumps(sample_entry),
                                 content_type='application/json')
    entry_id = json.loads(create_response.data)['id']
    
    # Get the entry
    response = client.get(f'/api/entries/{entry_id}')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['id'] == entry_id
    assert data['title'] == sample_entry['title']

def test_get_nonexistent_entry(client):
    """Test getting an entry that doesn't exist"""
    response = client.get('/api/entries/nonexistent-id')
    assert response.status_code == 404

def test_update_entry(client, sample_entry):
    """Test updating an entry"""
    # Create an entry
    create_response = client.post('/api/entries',
                                 data=json.dumps(sample_entry),
                                 content_type='application/json')
    entry_id = json.loads(create_response.data)['id']
    
    # Update the entry
    update_data = {'title': 'Updated Title', 'content': 'Updated content'}
    response = client.put(f'/api/entries/{entry_id}',
                         data=json.dumps(update_data),
                         content_type='application/json')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['title'] == 'Updated Title'
    assert data['content'] == 'Updated content'

def test_update_nonexistent_entry(client):
    """Test updating an entry that doesn't exist"""
    response = client.put('/api/entries/nonexistent-id',
                        data=json.dumps({'title': 'New Title'}),
                        content_type='application/json')
    assert response.status_code == 404

def test_delete_entry(client, sample_entry):
    """Test deleting an entry"""
    # Create an entry
    create_response = client.post('/api/entries',
                                 data=json.dumps(sample_entry),
                                 content_type='application/json')
    entry_id = json.loads(create_response.data)['id']
    
    # Delete the entry
    response = client.delete(f'/api/entries/{entry_id}')
    assert response.status_code == 200
    
    # Verify it's deleted
    get_response = client.get(f'/api/entries/{entry_id}')
    assert get_response.status_code == 404

def test_delete_nonexistent_entry(client):
    """Test deleting an entry that doesn't exist"""
    response = client.delete('/api/entries/nonexistent-id')
    assert response.status_code == 404

def test_unlock_entry(client, sample_entry):
    """Test unlocking an entry"""
    # Create an entry
    create_response = client.post('/api/entries',
                                 data=json.dumps(sample_entry),
                                 content_type='application/json')
    entry_id = json.loads(create_response.data)['id']
    
    # Unlock the entry
    response = client.post(f'/api/entries/{entry_id}/unlock')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['unlockedAt'] is not None

def test_unlock_nonexistent_entry(client):
    """Test unlocking an entry that doesn't exist"""
    response = client.post('/api/entries/nonexistent-id/unlock')
    assert response.status_code == 404

