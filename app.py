from flask import Flask, request, jsonify
import re
import requests
import psycopg2
import os
from urllib.parse import urlparse
from datetime import datetime
from database import get_db_connection

app = Flask(__name__)

# ------------------- DATABASE CONFIG -------------------
DATABASE_URL = os.environ.get("DATABASE_URL")

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
    "flipkart offer",
    "your sim will be blocked",
    "fraud",
    "immediate action",
    "pay now",
    "income tax",
    "parcel",
    "customs",
    "courier",
    "winner",
    "free recharge"
]

SUSPICIOUS_TLDS = [".xyz", ".top", ".tk", ".club", ".live", ".click", ".buzz", ".work"]

SHORTENER_DOMAINS = [
    "bit.ly", "tinyurl.com", "t.co", "goo.gl", "rebrand.ly", "cutt.ly",
    "is.gd", "buff.ly", "ow.ly", "shorte.st"
]

FAKE_BRAND_WORDS = [
    "paytm", "phonepe", "gpay", "googlepay", "amazon", "flipkart",
    "sbi", "hdfc", "icici", "axis", "upi", "netbanking"
]


# ------------------- DB FUNCTIONS -------------------
def init_db():
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("""
    CREATE TABLE IF NOT EXISTS threats (
        id SERIAL PRIMARY KEY,
        type TEXT,
        input_text TEXT,
        status TEXT,
        risk_score INT,
        reasons TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    """)

    conn.commit()
    cursor.close()
    conn.close()



def save_threat(threat_type, input_text, status, risk_score, reasons):
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("""
    INSERT INTO threats (type, input_text, status, risk_score, reasons)
    VALUES (%s, %s, %s, %s, %s)
    """, (
        threat_type,
        input_text,
        status,
        risk_score,
        ", ".join(reasons)
    ))

    conn.commit()
    cursor.close()
    conn.close()


def get_recent_threats(limit=10):
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("""
    SELECT id, type, input_text, status, risk_score, reasons, created_at
    FROM threats
    ORDER BY id DESC
    LIMIT %s
    """, (limit,))

    rows = cursor.fetchall()
    cursor.close()
    conn.close()

    threats = []
    for row in rows:
        threats.append({
            "id": row[0],
            "type": row[1],
            "input_text": row[2],
            "status": row[3],
            "risk_score": row[4],
            "reasons": row[5].split(", ") if row[5] else [],
            "created_at": str(row[6])
        })

    return threats



def get_dashboard_stats():
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT COUNT(*) FROM threats")
    total = cursor.fetchone()[0]

    cursor.execute("SELECT COUNT(*) FROM threats WHERE status='Safe'")
    safe = cursor.fetchone()[0]

    cursor.execute("SELECT COUNT(*) FROM threats WHERE status='Caution'")
    caution = cursor.fetchone()[0]

    cursor.execute("SELECT COUNT(*) FROM threats WHERE status='Danger'")
    danger = cursor.fetchone()[0]

    cursor.close()
    conn.close()

    return {
        "total": total,
        "safe": safe,
        "caution": caution,
        "danger": danger
    }



# ------------------- HELPER FUNCTIONS -------------------
def extract_urls(text):
    url_pattern = r"(https?://[^\s]+)"
    return re.findall(url_pattern, text)


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

    # Expand shortened URL
    if domain in SHORTENER_DOMAINS:
        expanded = expand_short_url(url)
        reasons.append(f"Short URL detected, expanded to: {expanded}")
        url = expanded
        domain = get_domain(url)
        risk_score += 25

    # Suspicious TLD check
    for tld in SUSPICIOUS_TLDS:
        if domain.endswith(tld):
            reasons.append(f"Suspicious domain extension detected: {tld}")
            risk_score += 25

    # HTTP check
    if url.startswith("http://"):
        reasons.append("Insecure HTTP detected (not HTTPS)")
        risk_score += 15

    # Brand spoofing words check
    for brand in FAKE_BRAND_WORDS:
        if brand in domain and not domain.endswith(".com") and not domain.endswith(".in"):
            reasons.append(f"Possible fake brand spoofing detected: '{brand}' in domain")
            risk_score += 20

    # Keywords in URL
    lower_url = url.lower()
    for word in SCAM_KEYWORDS:
        if word in lower_url:
            reasons.append(f"Suspicious keyword found in URL: '{word}'")
            risk_score += 10

    # Too many hyphens
    if "-" in domain and len(domain.split("-")) >= 3:
        reasons.append("Domain has too many '-' which looks suspicious")
        risk_score += 15

    # Very long domain
    if len(domain) > 25:
        reasons.append("Very long domain detected")
        risk_score += 10

    # IP address domain check
    ip_pattern = r"^\d{1,3}(\.\d{1,3}){3}$"
    if re.match(ip_pattern, domain):
        reasons.append("URL uses direct IP address instead of domain")
        risk_score += 30

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
        "reasons": reasons,
        "final_url": url,
        "domain": domain
    }


def analyze_text_common(text, analysis_type="message"):
    reasons = []
    risk_score = 0

    lower_text = text.lower()

    # Scam keywords detection
    for word in SCAM_KEYWORDS:
        if word in lower_text:
            reasons.append(f"Scam keyword detected: '{word}'")
            risk_score += 10

    # OTP pattern detection
    otp_pattern = r"\b\d{4,6}\b"
    if re.search(otp_pattern, lower_text):
        reasons.append("OTP-like number detected")
        risk_score += 15

    # Fear tactic detection
    fear_words = ["blocked", "suspended", "police", "case", "arrest", "court", "urgent", "immediately"]
    for fw in fear_words:
        if fw in lower_text:
            reasons.append(f"Fear tactic word detected: '{fw}'")
            risk_score += 8

    # URL extraction and analysis
    urls = extract_urls(text)
    for url in urls:
        link_result = analyze_link(url)
        if link_result["status"] == "Danger":
            reasons.append(f"Dangerous link found: {url}")
            risk_score += 25
        elif link_result["status"] == "Caution":
            reasons.append(f"Suspicious link found: {url}")
            risk_score += 15

    # Final status
    if risk_score >= 60:
        status = "Danger"
    elif risk_score >= 30:
        status = "Caution"
    else:
        status = "Safe"

    return {
        "type": analysis_type,
        "status": status,
        "risk_score": risk_score,
        "reasons": reasons,
        "urls_found": urls
    }


# ------------------- ROUTES -------------------
@app.route("/analyze/message", methods=["GET"])
def analyze_message_get():
    return jsonify({
        "msg": "Use POST method with JSON body {message: ...}"
    })



@app.route("/analyze/message", methods=["POST"])
def analyze_message():
    data = request.json
    message = data.get("message", "").strip()

    if not message:
        return jsonify({"status": "Error", "message": "Message is empty"}), 400

    result = analyze_text_common(message, "message")
    save_threat("message", message, result["status"], result["risk_score"], result["reasons"])

    return jsonify(result)


@app.route("/analyze/link", methods=["POST"])
def analyze_link_api():
    data = request.json
    url = data.get("link", "").strip()

    if not url.startswith("http"):
        return jsonify({
            "status": "Error",
            "risk_score": 0,
            "reasons": ["Invalid URL format. Must start with http or https"]
        }), 400

    result = analyze_link(url)
    save_threat("link", url, result["status"], result["risk_score"], result["reasons"])

    return jsonify(result)


@app.route("/analyze/call", methods=["POST"])
def analyze_call():
    data = request.json
    call_info = data.get("call_info", "").strip()

    if not call_info:
        return jsonify({"status": "Error", "message": "Call info is empty"}), 400

    result = analyze_text_common(call_info, "call")
    save_threat("call", call_info, result["status"], result["risk_score"], result["reasons"])

    return jsonify(result)


@app.route("/analyze/voice", methods=["POST"])
def analyze_voice():
    data = request.json
    voice_text = data.get("voice_text", "").strip()

    if not voice_text:
        return jsonify({"status": "Error", "message": "Voice text is empty"}), 400

    result = analyze_text_common(voice_text, "voice")
    save_threat("voice", voice_text, result["status"], result["risk_score"], result["reasons"])

    return jsonify(result)


# ------------------- DASHBOARD ROUTES -------------------
@app.route("/dashboard/stats", methods=["GET"])
def dashboard_stats():
    stats = get_dashboard_stats()
    return jsonify(stats)


@app.route("/dashboard/recent", methods=["GET"])
def dashboard_recent():
    threats = get_recent_threats(limit=10)
    return jsonify({"recent_threats": threats})


@app.route("/history/all", methods=["GET"])
def history_all():
    threats = get_recent_threats(limit=100)
    return jsonify({"history": threats})


# ------------------- RUN -------------------
if __name__ == "__main__":
    init_db()
    app.run(debug=True)
