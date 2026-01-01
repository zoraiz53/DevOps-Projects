from flask import Flask, jsonify
app = Flask(__name__)

@app.route("/")
def root():
    return "Hello from your Future DevOps Engineer 😉!"

@app.route("/health")
def health():
    return jsonify(status="Doing good... 👍🏻"), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
