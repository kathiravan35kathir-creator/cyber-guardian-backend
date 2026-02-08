import 'dart:convert';
import 'package:http/http.dart' as http;

class SosService {
  static Future<bool> sendSOS({
    required String phone,
    required String reason,
  }) async {
    final res = await http.post(
      Uri.parse("http://10.0.2.2:5000/sos"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_phone": phone,
        "reason": reason,
      }),
    );

    final data = jsonDecode(res.body);
    print("Guardians Notified: ${data['guardians']}");
    return data["success"] == true;
  }
}
