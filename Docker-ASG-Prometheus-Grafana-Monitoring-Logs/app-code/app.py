from flask import Flask
import random
import logging
import os

app = Flask(__name__)

jokes = [
    "Why don't eggs tell jokes? They'd crack each other up.",
    "I'm afraid for the calendar. Its days are numbered.",
    "Why did the scarecrow win an award? He was outstanding in his field.",
    "Dad, can you put my shoes on? No, I don't think they'll fit me.",
]

# Configure basic logging to /app/logs
log_dir = '/app/logs'
os.makedirs(log_dir, exist_ok=True)
log_file = os.path.join(log_dir, 'app.log')

logging.basicConfig(
    filename=log_file,
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s: %(message)s'
)

@app.route("/")
def get_joke():
    joke = random.choice(jokes)
    app.logger.info(f"Served joke: {joke}")
    return f"<h1>😂 {joke}</h1>"

if __name__ == "__main__":
    app.logger.info("Starting Flask application")
    app.run(host="0.0.0.0", port=80)

