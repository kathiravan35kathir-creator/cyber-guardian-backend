from flask import Flask, request, jsonify
import re
import requests
from urllib.parse import urlparse

app = Flask(__name__)

# ------------------- BASIC KEYWORDS -------------------
SCAM_KEYWORDS = [
    "account blocked",
    "urgent",
    "verify now",
    "click here",
    "limited time",
    "otp",
    "bank",
    "upi",
    "payment failed",
    "claim reward",
    "congratulations",
    "lottery",
    "police case",
    "suspend",
    "reset password",
    "login now",
    "update kyc",
    "aadhaar",
    "pan",
    "refund",
    "amazon offer",
    "flipkart offer"
]

SUSPICIOUS_TLDS = [".xyz", ".top", ".tk", ".club", ".live", ".click"]

SHORTENER_DOMAINS = [
    "bit.ly", "tinyurl.com", "t.co", "goo.gl", "rebrand.ly", "cutt.ly",
    "is.gd", "buff.ly", "ow.ly", "shorte.st"
]

# ------------------- HELPER FUNCTIONS -------------------

def expand_short_url(url):
    try:
        response = requests.get(url, timeout=5, allow_redirects=True)
        return response.url
    except:
        return url

def get_domain(url):
    try:
        parsed = urlparse(url)
        domain = parsed.netloc.lower()
        if domain.startswith("www."):
            domain = domain.replace("www.", "")
        return domain
    except:
        return ""

def analyze_link(url):
    reasons = []
    risk_score = 0

    domain = get_domain(url)

    if domain in SHORTENER_DOMAINS:
        expanded = expand_short_url(url)
        reasons.append(f"Short URL detected, expanded to: {expanded}")
        url = expanded
        domain = get_domain(url)
        risk_score += 20

    for tld in SUSPICIOUS_TLDS:
        if domain.endswith(tld):
            reasons.append(f"Suspicious domain extension detected: {tld}")
            risk_score += 25

    if url.startswith("http://"):
        reasons.append("Insecure HTTP link detected (not HTTPS)")
        risk_score += 15

    lower_url = url.lower()
    for word in SCAM_KEYWORDS:
        if word in lower_url:
            reasons.append(f"Suspicious keyword found in URL: '{word}'")
            risk_score += 10

    if "-" in domain and len(domain.split("-")) >= 3:
        reasons.append("Domain has too many '-' which looks suspicious")
        risk_score += 15

    if len(domain) > 25:
        reasons.append("Very long domain detected")
        risk_score += 10

    if risk_score >= 60:
        status = "Danger"
    elif risk_score >= 30:
        status = "Caution"
    else:
        status = "Safe"

    return {
        "type": "link",
        "status": status,
        "risk_score": risk_score,
        "reasons": reasons
    }

# ------------------- ROUTES -------------------

@app.route("/")
def home():
    return "Cyber Guardian Backend Running!"

@app.route("/analyze/message", methods=["POST"])
def analyze_message():
    data = request.json
    message = data.get("message", "").lower()

    reasons = []
    risk_score = 0

    for word in SCAM_KEYWORDS:
        if word in message:
            reasons.append(f"Scam keyword detected: '{word}'")
            risk_score += 10

    if risk_score >= 60:
        status = "Danger"
    elif risk_score >= 30:
        status = "Caution"
    else:
        status = "Safe"

    return jsonify({
        "type": "message",
        "status": status,
        "risk_score": risk_score,
        "reasons": reasons
    })

@app.route("/analyze/link", methods=["POST"])
def analyze_link_api():
    data = request.json
    url = data.get("link", "").strip()

    if not url.startswith("http"):
        return jsonify({
            "status": "Error",
            "risk_score": 0,
            "reasons": ["Invalid URL format"]
        }), 400

    result = analyze_link(url)
    return jsonify(result)

# ----------- NEW ENDPOINTS FOR CALL & VOICE ------------

@app.route("/analyze/call", methods=["POST"])
def analyze_call():
    data = request.json
    call_info = data.get("call_info", "").lower()

    reasons = []
    risk_score = 0

    for word in SCAM_KEYWORDS:
        if word in call_info:
            reasons.append(f"Suspicious keyword detected in call: '{word}'")
            risk_score += 10

    if risk_score >= 60:
        status = "Danger"
    elif risk_score >= 30:
        status = "Caution"
    else:
        status = "Safe"

    return jsonify({
        "type": "call",
        "status": status,
        "risk_score": risk_score,
        "reasons": reasons
    })

@app.route("/analyze/voice", methods=["POST"])
def analyze_voice():
    data = request.json
    voice_text = data.get("voice_text", "").lower()

    reasons = []
    risk_score = 0

    for word in SCAM_KEYWORDS:
        if word in voice_text:
            reasons.append(f"Suspicious keyword detected in voice: '{word}'")
            risk_score += 10

    if risk_score >= 60:
        status = "Danger"
    elif risk_score >= 30:
        status = "Caution"
    else:
        status = "Safe"

    return jsonify({
        "type": "voice",
        "status": status,
        "risk_score": risk_score,
        "reasons": reasons
    })

# ------------------- RUN -------------------

if __name__ == "__main__":
    app.run(debug=True)
