import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      "https://cyber-guardian-backend-u7en.onrender.com";

  static Future<Map<String, dynamic>> analyzeMessage(String message) async {
    final url = Uri.parse("$baseUrl/analyze/message");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"message": message}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed: ${response.statusCode}");
    }
  }
}
