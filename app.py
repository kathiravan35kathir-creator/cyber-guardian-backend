from flask import Flask, request, jsonify
import re
import requests
from urllib.parse import urlparse
from langdetect import detect
from dotenv import load_dotenv
from textblob import TextBlob
from supabase_client import supabase

load_dotenv()

app = Flask(__name__)

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


# ------------------- AUTH HELPER -------------------
def get_user_id_from_token():
    auth_header = request.headers.get("Authorization")

    if not auth_header:
        return None

    if not auth_header.startswith("Bearer "):
        return None

    token = auth_header.replace("Bearer ", "")

    try:
        user = supabase.auth.get_user(token)
        return user.user.id
    except Exception as e:
        print("Auth error:", e)
        return None


# ------------------- SAVE THREAT -------------------
def save_threat(user_id, type_, input_text, status, risk_score, reasons):
    try:
        supabase.table("threats").insert({
            "user_id": user_id,
            "type": type_,
            "input_text": input_text,
            "status": status,
            "risk_score": risk_score,
            "reasons": ", ".join(reasons)
        }).execute()

        print("✅ Threat saved to Supabase")

    except Exception as e:
        print("❌ Supabase insert error:", e)


# ------------------- FETCH HISTORY -------------------
def get_recent_threats(user_id, limit=50):
    try:
        res = supabase.table("threats") \
            .select("*") \
            .eq("user_id", user_id) \
            .order("id", desc=True) \
            .limit(limit) \
            .execute()

        return res.data

    except Exception as e:
        print("❌ Supabase fetch error:", e)
        return []


# ------------------- DASHBOARD STATS -------------------
def get_dashboard_stats(user_id):
    try:
        total = supabase.table("threats").select("id", count="exact").eq("user_id", user_id).execute().count
        safe = supabase.table("threats").select("id", count="exact").eq("user_id", user_id).eq("status", "Safe").execute().count
        caution = supabase.table("threats").select("id", count="exact").eq("user_id", user_id).eq("status", "Caution").execute().count
        danger = supabase.table("threats").select("id", count="exact").eq("user_id", user_id).eq("status", "Danger").execute().count

        return {
            "total": total,
            "safe": safe,
            "caution": caution,
            "danger": danger
        }

    except Exception as e:
        print("❌ Supabase stats error:", e)
        return {"total": 0, "safe": 0, "caution": 0, "danger": 0}


# ------------------- NLP HELPERS -------------------
def detect_language(text):
    try:
        return detect(text)
    except:
        return "unknown"


def sentiment_score(text):
    try:
        blob = TextBlob(text)
        polarity = blob.sentiment.polarity

        if polarity < -0.3:
            return "negative", polarity
        elif polarity > 0.3:
            return "positive", polarity
        else:
            return "neutral", polarity
    except:
        return "unknown", 0





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


# ------------------- LINK ANALYSIS -------------------
def analyze_link(url):
    reasons = []
    risk_score = 0

    domain = get_domain(url)

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

    if domain in SHORTENER_DOMAINS:
        expanded = expand_short_url(url)
        reasons.append(f"Short URL detected, expanded to: {expanded}")
        url = expanded
        domain = get_domain(url)
        risk_score += 25

    for tld in SUSPICIOUS_TLDS:
        if domain.endswith(tld):
            reasons.append(f"Suspicious domain extension detected: {tld}")
            risk_score += 25

    if url.startswith("http://"):
        reasons.append("Insecure HTTP detected (not HTTPS)")
        risk_score += 15

    for brand in FAKE_BRAND_WORDS:
        if brand in domain and not domain.endswith(".com") and not domain.endswith(".in"):
            reasons.append(f"Possible fake brand spoofing detected: {brand}")
            risk_score += 20

    lower_url = url.lower()
    for word in HIGH_RISK_KEYWORDS:
        if word in lower_url:
            reasons.append(f"Suspicious keyword found in URL: {word}")
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
        "reasons": reasons,
        "final_url": url,
        "domain": domain
    }


# ------------------- MESSAGE ANALYSIS -------------------
def analyze_text_common(text, analysis_type="message"):
    reasons = []
    risk_score = 0

    translated_text = text
    detected_lang = detect_language(text)
    lower_text = translated_text.lower()

    sentiment, polarity = sentiment_score(translated_text)

    if sentiment == "negative":
        reasons.append("NLP detected negative/fear sentiment in message")
        risk_score += 15

    for word in HIGH_RISK_KEYWORDS:
        if word in lower_text:
            reasons.append(f"High risk keyword detected: {word}")
            risk_score += 25

    for word in MEDIUM_RISK_KEYWORDS:
        if word in lower_text:
            reasons.append(f"Medium risk keyword detected: {word}")
            risk_score += 15

    urls = extract_urls(text)
    for url in urls:
        link_result = analyze_link(url)
        if link_result["status"] == "Danger":
            reasons.append(f"Dangerous link found: {url}")
            risk_score += 25
        elif link_result["status"] == "Caution":
            reasons.append(f"Suspicious link found: {url}")
            risk_score += 15

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
        "detected_language": detected_lang,
        "translated_text": translated_text,
        "status": status,
        "risk_score": risk_score,
        "reasons": reasons,
        "urls_found": urls
    }

# ------------------- BEHAVIOR ENGINE -------------------
import statistics

user_behavior_cache = {}

def detect_behavior_anomaly(user_id, new_score):
    if user_id not in user_behavior_cache:
        user_behavior_cache[user_id] = []

    history = user_behavior_cache[user_id]
    history.append(new_score)

    if len(history) < 5:
        return 0

    mean = statistics.mean(history)
    stdev = statistics.stdev(history) if len(history) > 1 else 0

    if stdev > 0 and new_score > mean + (2 * stdev):
        return 20  # anomaly risk points

    return 0

# ------------------- RISK SCORING ENGINE -------------------

def calculate_unified_risk(call_score, message_score, link_score, behavior_score):
    w1 = 0.2
    w2 = 0.3
    w3 = 0.3
    w4 = 0.2

    final_score = (w1 * call_score) + \
                  (w2 * message_score) + \
                  (w3 * link_score) + \
                  (w4 * behavior_score)

    return round(final_score, 2)


# ------------------- ROUTES -------------------
@app.route("/", methods=["GET"])
def home():
    return jsonify({"status": "success", "message": "Cyber Guardian Backend Running 🚀"})


@app.route("/analyze-message", methods=["POST"])
def analyze_message():
    user_id = get_user_id_from_token()
    if not user_id:
        return jsonify({"error": "Unauthorized"}), 401

    data = request.get_json()
    message = data.get("message", "").strip()

    if not message:
        return jsonify({"error": "Message is empty"}), 400

    result = analyze_text_common(message, "message")
    save_threat(user_id, "message", message, result["status"], result["risk_score"], result["reasons"])

    return jsonify(result)


@app.route("/analyze-message", methods=["POST"])
def analyze_message():

    user_id = get_user_id_from_token()
    if not user_id:
        return jsonify({"error": "Unauthorized"}), 401

    data = request.get_json()
    message = data.get("message", "").strip()
    call_score = data.get("call_score", 0)

    if not message:
        return jsonify({"error": "Message is empty"}), 400

    # Step 1: Message analysis
    msg_result = analyze_text_common(message, "message")

    # Step 2: Extract link score separately
    link_score_total = 0
    for url in msg_result["urls_found"]:
        link_result = analyze_link(url)
        link_score_total += link_result["risk_score"]

    # Step 3: Behavior anomaly detection
    behavior_score = detect_behavior_anomaly(user_id, msg_result["risk_score"])

    # Step 4: Unified Risk Score
    final_risk_score = calculate_unified_risk(
        call_score,
        msg_result["risk_score"],
        link_score_total,
        behavior_score
    )

    # Step 5: Determine final status
    if final_risk_score >= 60:
        final_status = "Danger"
    elif final_risk_score >= 35:
        final_status = "Caution"
    else:
        final_status = "Safe"

    # Step 6: Combine reasons
    combined_reasons = msg_result["reasons"].copy()

    if behavior_score > 0:
        combined_reasons.append("Unusual behavioral spike detected")

    # Step 7: Save to Supabase
    save_threat(
        user_id,
        "message",
        message,
        final_status,
        final_risk_score,
        combined_reasons
    )

    return jsonify({
        "type": "message",
        "status": final_status,
        "final_risk_score": final_risk_score,
        "behavior_score": behavior_score,
        "detected_language": msg_result["detected_language"],
        "translated_text": msg_result["translated_text"],
        "reasons": combined_reasons
    })

@app.route("/analyze-link", methods=["POST"])
def analyze_link_api():

    user_id = get_user_id_from_token()
    if not user_id:
        return jsonify({"error": "Unauthorized"}), 401

    data = request.get_json()
    url = data.get("url", "").strip()
    call_score = data.get("call_score", 0)

    if not url.startswith("http"):
        return jsonify({
            "status": "Error",
            "risk_score": 0,
            "reasons": ["Invalid URL format"]
        }), 400

    link_result = analyze_link(url)

    # Behavior score
    behavior_score = detect_behavior_anomaly(user_id, link_result["risk_score"])

    # Unified Risk
    final_risk_score = calculate_unified_risk(
        call_score,
        0,
        link_result["risk_score"],
        behavior_score
    )

    if final_risk_score >= 60:
        final_status = "Danger"
    elif final_risk_score >= 35:
        final_status = "Caution"
    else:
        final_status = "Safe"

    combined_reasons = link_result["reasons"].copy()

    if behavior_score > 0:
        combined_reasons.append("Unusual behavioral spike detected")

    save_threat(
        user_id,
        "link",
        url,
        final_status,
        final_risk_score,
        combined_reasons
    )

    return jsonify({
        "type": "link",
        "status": final_status,
        "final_risk_score": final_risk_score,
        "behavior_score": behavior_score,
        "reasons": combined_reasons,
        "final_url": link_result["final_url"],
        "domain": link_result["domain"]
    })


@app.route("/threat-history", methods=["GET"])
def threat_history_api():
    user_id = get_user_id_from_token()
    if not user_id:
        return jsonify({"error": "Unauthorized"}), 401

    threats = get_recent_threats(user_id, limit=50)
    return jsonify({"history": threats})


@app.route("/dashboard-stats", methods=["GET"])
def dashboard_stats_api():
    user_id = get_user_id_from_token()
    if not user_id:
        return jsonify({"error": "Unauthorized"}), 401

    stats = get_dashboard_stats(user_id)
    return jsonify(stats)

@app.route("/ping")
def ping():
    return "PONG"


if __name__ == "__main__":
    import os
    port = int(os.environ.get("PORT", 10000))
    app.run(host="0.0.0.0", port=port)
