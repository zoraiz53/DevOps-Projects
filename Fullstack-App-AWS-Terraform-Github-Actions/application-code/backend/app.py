from flask import Flask, jsonify, request
from flask_cors import CORS
import os

app = Flask(__name__)

# Allow CORS from any origin for cross-server deployment
CORS(app, origins="*", methods=["GET", "POST", "PUT", "DELETE"], allow_headers=["Content-Type"])

# Sample data
users = [
    {"id": 1, "name": "John Doe", "email": "john@example.com"},
    {"id": 2, "name": "Jane Smith", "email": "jane@example.com"},
    {"id": 3, "name": "Bob Johnson", "email": "bob@example.com"}
]

@app.route('/')
def home():
    return jsonify({"message": "Backend API is running!", "status": "success"})

@app.route('/api/users', methods=['GET'])
def get_users():
    return jsonify({"users": users, "count": len(users)})

@app.route('/api/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    user = next((user for user in users if user["id"] == user_id), None)
    if user:
        return jsonify({"user": user})
    return jsonify({"error": "User not found"}), 404

@app.route('/api/users', methods=['POST'])
def create_user():
    data = request.get_json()
    if not data or 'name' not in data or 'email' not in data:
        return jsonify({"error": "Name and email are required"}), 400
    
    new_user = {
        "id": max(user["id"] for user in users) + 1,
        "name": data["name"],
        "email": data["email"]
    }
    users.append(new_user)
    return jsonify({"user": new_user, "message": "User created successfully"}), 201

@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy", "service": "backend"})

@app.route('/api/info', methods=['GET'])
def api_info():
    """Return API information"""
    return jsonify({
        "service": "backend",
        "version": "1.0.0",
        "endpoints": [
            {"path": "/", "method": "GET", "description": "Home page"},
            {"path": "/api/health", "method": "GET", "description": "Health check"},
            {"path": "/api/users", "method": "GET", "description": "Get all users"},
            {"path": "/api/users/<id>", "method": "GET", "description": "Get specific user"},
            {"path": "/api/users", "method": "POST", "description": "Create new user"}
        ]
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=True) 