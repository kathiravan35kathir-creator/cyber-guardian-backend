from flask import Flask, request, jsonify
from flask_cors import CORS
import re
import requests
from bs4 import BeautifulSoup
import tldextract

app = Flask(__name__)
CORS(app)

# ---------------- CONFIG ---------------- #

SCAM_KEYWORDS = [
    "account blocked", "account suspended", "urgent", "immediately",
    "verify now", "click here", "limited time", "otp", "bank",
    "police case", "arrest", "fraud", "congratulations",
    "you won", "prize", "claim", "loan approved", "pay now",
    "upi", "password", "login now", "security alert"
]

SHORTENERS = [
    "bit.ly", "tinyurl.com", "t.co", "goo.gl", "is.gd", "cutt.ly"
]


# ---------------- UTIL FUNCTIONS ---------------- #

def calculate_message_risk(message: str):
    message_lower = message.lower()
    score = 0
    reasons = []

    for keyword in SCAM_KEYWORDS:
        if keyword in message_lower:
            score += 10
            reasons.append(f"Scam keyword detected: '{keyword}'")

    if re.search(r"\b\d{6}\b", message):
        score += 10
        reasons.append("OTP-like 6 digit number detected")

    if "http" in message_lower:
        score += 10
        reasons.append("Contains link inside message")

    if "upi" in message_lower or "pay" in message_lower:
        score += 15
        reasons.append("Payment / UPI related content detected")

    if score >= 70:
        status = "Danger"
    elif score >= 40:
        status = "Caution"
    else:
        status = "Safe"

    return status, min(score, 100), reasons


def extract_domain(url: str):
    ext = tldextract.extract(url)
    return f"{ext.domain}.{ext.suffix}"


def analyze_link(url: str):
    score = 0
    reasons = []

    domain = extract_domain(url)

    # Short link detection
    for short in SHORTENERS:
        if short in url:
            score += 30
            reasons.append("Shortened URL detected")

    # Suspicious patterns
    if "login" in url.lower() or "verify" in url.lower():
        score += 20
        reasons.append("URL contains login/verify pattern")

    if "free" in url.lower() or "offer" in url.lower() or "prize" in url.lower():
        score += 20
        reasons.append("URL contains offer/prize keywords")

    if url.count("-") > 3:
        score += 10
        reasons.append("Too many hyphens in URL (common in phishing)")

    if url.count(".") > 4:
        score += 10
        reasons.append("Too many subdomains (possible fake site)")

    # Look-alike detection examples
    if "paytm" in domain and domain != "paytm.com":
        score += 40
        reasons.append("Look-alike domain detected (paytm clone)")

    if "google" in domain and domain != "google.com":
        score += 40
        reasons.append("Look-alike domain detected (google clone)")

    if "instagram" in domain and domain != "instagram.com":
        score += 40
        reasons.append("Look-alike domain detected (instagram clone)")

    if score >= 70:
        status = "Danger"
    elif score >= 40:
        status = "Caution"
    else:
        status = "Safe"

    return status, min(score, 100), reasons, domain


def detect_fake_login_page(url: str):
    score = 0
    reasons = []

    try:
        response = requests.get(url, timeout=6)
        html = response.text.lower()

        soup = BeautifulSoup(html, "html.parser")
        forms = soup.find_all("form")
        password_inputs = soup.find_all("input", {"type": "password"})

        if len(forms) > 0:
            score += 20
            reasons.append("Login form detected")

        if len(password_inputs) > 0:
            score += 30
            reasons.append("Password field detected")

        if "otp" in html:
            score += 20
            reasons.append("OTP keyword found in page")

        if "bank" in html or "upi" in html:
            score += 20
            reasons.append("Bank/UPI keywords found")

        if score >= 60:
            status = "Danger"
        elif score >= 30:
            status = "Caution"
        else:
            status = "Safe"

        return status, min(score, 100), reasons

    except Exception as e:
        return "Caution", 50, [f"Could not analyze page properly: {str(e)}"]


# ---------------- ROUTES ---------------- #

@app.route("/", methods=["GET"])
def home():
    return jsonify({"message": "Cyber Guardian Backend Running"})


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"})


@app.route("/analyze/message", methods=["POST"])
def analyze_message():
    data = request.json
    message = data.get("message", "")

    status, score, reasons = calculate_message_risk(message)

    return jsonify({
        "type": "message",
        "status": status,
        "risk_score": score,
        "reasons": reasons
    })


@app.route("/analyze/link", methods=["POST"])
def analyze_link_api():
    data = request.json
    url = data.get("url", "")

    status, score, reasons, domain = analyze_link(url)

    return jsonify({
        "type": "link",
        "domain": domain,
        "status": status,
        "risk_score": score,
        "reasons": reasons
    })


@app.route("/analyze/loginpage", methods=["POST"])
def analyze_loginpage():
    data = request.json
    url = data.get("url", "")

    status, score, reasons = detect_fake_login_page(url)

    return jsonify({
        "type": "loginpage",
        "status": status,
        "risk_score": score,
        "reasons": reasons
    })


@app.route("/risk/score", methods=["POST"])
def overall_risk():
    data = request.json
    message = data.get("message", "")
    url = data.get("url", "")

    total_score = 0
    reasons = []

    if message:
        _, sc, rs = calculate_message_risk(message)
        total_score += sc
        reasons.extend(rs)

    if url:
        _, sc2, rs2, _ = analyze_link(url)
        total_score += sc2
        reasons.extend(rs2)

    total_score = min(total_score, 100)

    if total_score >= 70:
        status = "Danger"
    elif total_score >= 40:
        status = "Caution"
    else:
        status = "Safe"

    return jsonify({
        "status": status,
        "risk_score": total_score,
        "reasons": reasons
    })


if __name__ == "__main__":
    app.run(debug=True)
