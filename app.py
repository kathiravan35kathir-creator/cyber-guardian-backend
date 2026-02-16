from flask import Flask, request, jsonify
import re
import requests
from urllib.parse import urlparse
from database import get_db_connection, init_db

app = Flask(__name__)

# ------------------- INIT DB -------------------
# Render/Gunicorn start agumbodhe table create aagum
init_db()

# ------------------- BASIC KEYWORDS -------------------
HIGH_RISK_KEYWORDS = [
    "otp", "password", "processing fee", "bank", "kyc",
    "account blocked", "suspended", "blocked",
    "police case", "arrest", "legal action"
]

MEDIUM_RISK_KEYWORDS = [
    "urgent", "immediate action", "verify now",
    "refund", "loan approved", "gift card", "update"
]

LOW_RISK_KEYWORDS = [
    "winner", "prize", "lottery", "limited time", "offer"
]


SHORTENER_DOMAINS = [
    "bit.ly", "tinyurl.com", "t.co", "goo.gl",
    "is.gd", "cutt.ly", "rb.gy"
]

SUSPICIOUS_TLDS = [".xyz", ".top", ".tk", ".ru", ".cn", ".club", ".live", ".click"]

FAKE_BRAND_WORDS = [
    "paytm", "phonepe", "gpay", "googlepay",
    "amazon", "flipkart", "sbi", "hdfc",
    "icici", "axis", "upi", "netbanking"
]

# ------------------- DB FUNCTIONS -------------------
def save_threat(type_, input_text, status, risk_score, reasons):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute("""
            INSERT INTO threats (type, input_text, status, risk_score, reasons)
            VALUES (%s, %s, %s, %s, %s)
        """, (type_, input_text, status, risk_score, ", ".join(reasons)))

        conn.commit()
        cursor.close()
        conn.close()
    except Exception as e:
        print("DB Save Error:", e)


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
    url_pattern = r"(https?://[^\s]+|www\.[^\s]+)"
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

    # ✅ ADD THESE (new checks)
    if "@" in url:
        reasons.append("URL contains '@' trick (redirect scam)")
        risk_score += 30

if domain.count(".") >= 3:
        reasons.append("Too many subdomains detected")
        risk_score += 20

if len(url) > 80:
        reasons.append("Very long URL detected")
        risk_score += 15

suspicious_paths = ["login", "verify", "secure", "update", "bank", "kyc", "otp"]
for sp in suspicious_paths:
        if f"/{sp}" in url.lower():
            reasons.append(f"Suspicious URL path keyword detected: {sp}")
            risk_score += 15
            
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

    # Brand spoofing check
for brand in FAKE_BRAND_WORDS:
        if brand in domain and not domain.endswith(".com") and not domain.endswith(".in"):
            reasons.append(f"Possible fake brand spoofing detected: {brand}")
            risk_score += 20

    # Keyword check inside URL
lower_url = url.lower()
for word in SCAM_KEYWORDS:
        if word in lower_url:
            reasons.append(f"Suspicious keyword found in URL: {word}")
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
    urls = []

    # Scam keywords detection
    for word in HIGH_RISK_KEYWORDS:
        if word in lower_text:
            reasons.append(f"High risk keyword detected: {word}")
            risk_score += 25

    for word in MEDIUM_RISK_KEYWORDS:
        if word in lower_text:
            reasons.append(f"Medium risk keyword detected: {word}")
            risk_score += 15

    for word in LOW_RISK_KEYWORDS:
        if word in lower_text:
            reasons.append(f"Low risk keyword detected: {word}")
            risk_score += 8

    money_pattern = r"(\$|₹|rs\.?|inr)\s?\d+"
    if re.search(money_pattern, lower_text):
        reasons.append("Money amount detected")
        risk_score += 20

    upi_pattern = r"\b[a-zA-Z0-9.\-_]{2,}@[a-zA-Z]{2,}\b"
    if re.search(upi_pattern, text):
        reasons.append("UPI ID detected")
        risk_score += 35

    if "prize" in lower_text and "processing fee" in lower_text:
        reasons.append("Prize + processing fee scam combo detected")
        risk_score += 40

    if "otp" in lower_text and ("bank" in lower_text or "account" in lower_text):
        reasons.append("OTP request with banking context detected")
        risk_score += 35

    # OTP detection
    otp_pattern = r"\b\d{4,6}\b"
    if re.search(otp_pattern, lower_text):
        reasons.append("OTP-like number detected")
        risk_score += 15

    # Fear tactics
    fear_words = ["blocked", "suspended", "police", "case", "arrest", "court", "urgent", "immediately"]
    for fw in fear_words:
        if fw in lower_text:
            reasons.append(f"Fear tactic word detected: {fw}")
            risk_score += 8

    # URL detection
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
    if risk_score >= 70:
        status = "Danger"
    elif risk_score >= 40:
        status = "Caution"
    else:
        status = "Safe"

    if len(reasons) == 0:
        reasons.append("No scam patterns detected")

    return {
        "type": analysis_type,
        "input": text,
        "status": status,
        "risk_score": risk_score,
        "reasons": reasons,
        "urls_found": urls
    }

# ------------------- ROUTES -------------------
@app.route("/", methods=["GET"])
def home():
    return jsonify({
        "status": "success",
        "message": "Cyber Guardian Backend Running 🚀"
    })


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "success", "message": "Cyber Guardian Backend Running 🚀"})


@app.route("/analyze/message", methods=["POST"])
def analyze_message():
    data = request.get_json()
    message = data.get("message", "").strip()

    if not message:
        return jsonify({"error": "Message is empty"}), 400

    result = analyze_text_common(message, "message")
    save_threat("message", message, result["status"], result["risk_score"], result["reasons"])

    return jsonify(result)


@app.route("/analyze/link", methods=["POST"])
def analyze_link_api():
    data = request.get_json()
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
    data = request.get_json()
    call_info = data.get("call_info", "").strip()

    if not call_info:
        return jsonify({"status": "Error", "message": "Call info is empty"}), 400

    result = analyze_text_common(call_info, "call")
    save_threat("call", call_info, result["status"], result["risk_score"], result["reasons"])

    return jsonify(result)


@app.route("/analyze/voice", methods=["POST"])
def analyze_voice():
    data = request.get_json()
    voice_text = data.get("voice_text", "").strip()

    if not voice_text:
        return jsonify({"status": "Error", "message": "Voice text is empty"}), 400

    result = analyze_text_common(voice_text, "voice")
    save_threat("voice", voice_text, result["status"], result["risk_score"], result["reasons"])

    return jsonify(result)


@app.route("/dashboard/stats", methods=["GET"])
def dashboard_stats_api():
    stats = get_dashboard_stats()
    return jsonify(stats)


@app.route("/dashboard/recent", methods=["GET"])
def dashboard_recent_api():
    threats = get_recent_threats(limit=10)
    return jsonify({"recent_threats": threats})


@app.route("/history/all", methods=["GET"])
def history_all():
    threats = get_recent_threats(limit=100)
    return jsonify({"history": threats})


@app.route("/history", methods=["GET"])
def history():
    threats = get_recent_threats(limit=50)
    return jsonify(threats)


@app.route("/guardians", methods=["GET"])
def guardians():
    return jsonify([])


# ------------------- RUN -------------------
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=10000)
