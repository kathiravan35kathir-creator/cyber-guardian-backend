from flask import Flask, request, jsonify
from flask_cors import CORS
import os  # <-- Add this to read env variables

app = Flask(__name__)
CORS(app)

# 🔐 TEMP STORAGE (DB illa – FREE demo)
guardians = {
    "9876543210": ["9999911111", "8888822222"]
}

# 🌟 Example of reading an environment variable
# You can set this in Windows or Render
API_KEY = os.getenv("MY_API_KEY", "DUMMY_KEY")  # fallback if not set
print("Your API Key:", API_KEY)

@app.route("/")
def home():
    return "Cyber Guardian Backend Running"

# ➕ ADD GUARDIAN
@app.route("/add-guardian", methods=["POST"])
def add_guardian():
    data = request.json
    user = data["user_phone"]
    guardian = data["guardian_phone"]

    if user not in guardians:
        guardians[user] = []

    guardians[user].append(guardian)

    return jsonify({
        "success": True,
        "guardians": guardians[user]
    })

# 🚨 SOS ENDPOINT
@app.route("/sos", methods=["POST"])
def sos():
    data = request.json
    user = data["user_phone"]
    reason = data.get("reason", "Emergency")

    guardian_list = guardians.get(user, [])

    print("🚨 SOS RECEIVED")
    print("User:", user)
    print("Reason:", reason)
    print("Alerting Guardians:", guardian_list)
    print("Using API_KEY:", API_KEY)  # Example usage of environment variable

    return jsonify({
        "success": True,
        "message": "SOS sent to guardians",
        "guardians": guardian_list
    })

if __name__ == "__main__":
    app.run(debug=True)
