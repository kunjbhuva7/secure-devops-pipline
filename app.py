from flask import Flask, jsonify, request
from werkzeug.exceptions import HTTPException
import logging

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

@app.route('/')
def index():
    return jsonify({"message": "Welcome to Secure Flask App!"})

@app.route('/health')
def health():
    return jsonify({"status": "UP"}), 200

@app.route('/greet/<username>', methods=['GET'])
def greet_user(username):
    return jsonify({"message": f"Hello, {username}!"})

@app.errorhandler(HTTPException)
def handle_exception(e):
    response = e.get_response()
    response.data = jsonify({"error": e.name, "description": e.description}).get_data()
    response.content_type = "application/json"
    return response, e.code

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

