from flask import Flask, render_template, request, jsonify, redirect, url_for
import requests
import os

app = Flask(__name__)

# Backend API endpoint - can be configured via environment variable
# For cross-server deployment, set this to your backend EC2's public IP or domain
BACKEND_URL = os.environ.get('BACKEND_URL', 'http://localhost:5000')

@app.route('/')
def index():
    return render_template('index.html', backend_url=BACKEND_URL)

@app.route('/api/connect', methods=['POST'])
def connect_backend():
    """Test connection to backend"""
    try:
        response = requests.get(f"{BACKEND_URL}/api/health", timeout=10)
        if response.status_code == 200:
            return jsonify({"status": "success", "message": "Connected to backend successfully!"})
        else:
            return jsonify({"status": "error", "message": f"Backend responded with status {response.status_code}"})
    except requests.exceptions.RequestException as e:
        return jsonify({"status": "error", "message": f"Failed to connect to backend: {str(e)}"})

@app.route('/api/users', methods=['GET'])
def get_users():
    """Get users from backend"""
    try:
        response = requests.get(f"{BACKEND_URL}/api/users", timeout=10)
        return jsonify(response.json())
    except requests.exceptions.RequestException as e:
        return jsonify({"error": f"Failed to fetch users: {str(e)}"}), 500

@app.route('/api/users', methods=['POST'])
def create_user():
    """Create user via backend"""
    try:
        data = request.get_json()
        response = requests.post(f"{BACKEND_URL}/api/users", json=data, timeout=10)
        return jsonify(response.json()), response.status_code
    except requests.exceptions.RequestException as e:
        return jsonify({"error": f"Failed to create user: {str(e)}"}), 500

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "frontend", "backend_url": BACKEND_URL})

@app.route('/config')
def config():
    """Show current configuration"""
    return jsonify({
        "backend_url": BACKEND_URL,
        "frontend_port": os.environ.get('PORT', 3000),
        "environment": os.environ.get('FLASK_ENV', 'development')
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 3000))
    app.run(host='0.0.0.0', port=port, debug=True) 