from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# 🔐 TEMP STORAGE (DB illa – FREE demo)
guardians = {
    "9876543210": ["9999911111", "8888822222"]
}

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

    return jsonify({
        "success": True,
        "message": "SOS sent to guardians",
        "guardians": guardian_list
    })

if __name__ == "__main__":
    app.run(debug=True)
