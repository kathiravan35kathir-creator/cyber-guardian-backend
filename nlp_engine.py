import re
import nltk
from nltk.tokenize import word_tokenize
from nltk.corpus import stopwords

fear_words = [
    "blocked", "suspended", "legal action",
    "police", "court", "urgent", "immediately",
    "verify now", "last warning"
]

def detect_fear_tone(message):
    tokens = word_tokenize(message.lower())
    score = 0
    
    for word in fear_words:
        if word in message.lower():
            score += 2

    return score


def detect_urgency(message):
    urgency_patterns = [
        r"within \d+ hours",
        r"immediate action",
        r"act now",
        r"limited time"
    ]

    score = 0
    for pattern in urgency_patterns:
        if re.search(pattern, message.lower()):
            score += 2

    return score


def detect_suspicious_link(message):
    links = re.findall(r'(https?://\S+)', message)
    if links:
        return 3
    return 0


def analyze_message(message):
    fear_score = detect_fear_tone(message)
    urgency_score = detect_urgency(message)
    link_score = detect_suspicious_link(message)

    total = fear_score + urgency_score + link_score

    return {
        "fear_score": fear_score,
        "urgency_score": urgency_score,
        "link_score": link_score,
        "total_score": total
    }