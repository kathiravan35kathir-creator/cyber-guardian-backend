import tldextract
from difflib import SequenceMatcher

popular_brands = ["amazon", "google", "paypal", "bank", "instagram"]

def brand_similarity(domain):
    score = 0
    for brand in popular_brands:
        similarity = SequenceMatcher(None, brand, domain).ratio()
        if similarity > 0.7 and similarity < 1:
            score += 3
    return score


def analyze_link(url):
    ext = tldextract.extract(url)
    domain = ext.domain.lower()

    length_score = 2 if len(domain) > 15 else 0
    brand_score = brand_similarity(domain)

    total = length_score + brand_score

    return {
        "domain": domain,
        "length_score": length_score,
        "brand_similarity_score": brand_score,
        "total_link_score": total
    }