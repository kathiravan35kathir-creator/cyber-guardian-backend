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

    # Expand shortened URL
    domain = get_domain(url)

    if domain in SHORTENER_DOMAINS:
        expanded = expand_short_url(url)
        reasons.append(f"Short URL detected, expanded to: {expanded}")
        url = expanded
        domain = get_domain(url)
        risk_score += 20

    # Domain suspicious TLD check
    for tld in SUSPICIOUS_TLDS:
        if domain.endswith(tld):
            reasons.append(f"Suspicious domain extension detected: {tld}")
            risk_score += 25

    # HTTP check
    if url.startswith("http://"):
        reasons.append("Insecure HTTP link detected (not HTTPS)")
        risk_score += 15

    # Keywords in URL
    lower_url = url.lower()
    for word in SCAM_KEYWORDS:
        if word in lower_url:
            reasons.append(f"Suspicious keyword found in URL: '{word}'")
            risk_score += 10

    # Too many redirects / strange pattern
    if "-" in domain and len(domain.split("-")) >= 3:
        reasons.append("Domain has too many '-' which looks suspicious")
        risk_score += 15

    if len(domain) > 25:
        reasons.append("Very long domain detected")
        risk_score += 10

    # Final status
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

def analyze_text(text):
    """
    General text analysis for message, call info, voice transcript
    """
    text = text.lower()
    reasons = []
    risk_score = 0

    for word in SCAM_KEYWORDS:
        if word in text:
            reasons.append(f"Scam keyword detected: '{word}'")
            risk_score += 10

    # Status calculation
    if risk_score >= 60:
        status = "Danger"
    elif risk_score >= 30:
        status = "Caution"
    else:
        status = "Safe"

    return {
        "type": "text",
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
    message = data.get("message", "")
    result = analyze_text(message)
    result["type"] = "message"
    return jsonify(result)

@app.route("/analyze/call", methods=["POST"])
def analyze_call():
    data = request.json
    call_info = data.get("call_info", "")
    result = analyze_text(call_info)
    result["type"] = "call"
    return jsonify(result)

@app.route("/analyze/voice", methods=["POST"])
def analyze_voice():
    data = request.json
    voice_text = data.get("voice_text", "")
    result = analyze_text(voice_text)
    result["type"] = "voice"
    return jsonify(result)

@app.route("/analyze/link", methods=["POST"])
def analyze_link_api():
    data = request.json
    url = data.get("url", "").strip()

    if not url.startswith("http"):
        return jsonify({
            "status": "Error",
            "risk_score": 0,
            "reasons": ["Invalid URL format"]
        }), 400

    result = analyze_link(url)
    return jsonify(result)

# ------------------- RUN -------------------

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=8000)
