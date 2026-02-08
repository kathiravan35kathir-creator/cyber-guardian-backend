class RiskEngine {
  static String checkMessage(String text) {
    if (text.contains("http")) {
      return "⚠️ Suspicious link detected!";
    }
    return "✅ Message safe";
  }
}
