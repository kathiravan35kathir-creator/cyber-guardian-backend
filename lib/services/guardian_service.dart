import 'dart:convert';
import 'package:http/http.dart' as http;

class GuardianService {
  static const String baseUrl = "http://10.0.2.2:5000";
  // real phone -> PC IP use pannu

  static Future<bool> addGuardian({
    required String userPhone,
    required String guardianPhone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/add-guardian"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_phone": userPhone,
          "guardian_phone": guardianPhone,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Add guardian error: $e");
      return false;
    }
  }

  static Future<List<String>> getGuardians(String userPhone) async {
    try {
      final response =
          await http.get(Uri.parse("$baseUrl/guardians/$userPhone"));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data["guardians"]);
      }
    } catch (e) {
      print("Get guardians error: $e");
    }
    return [];
  }
}
