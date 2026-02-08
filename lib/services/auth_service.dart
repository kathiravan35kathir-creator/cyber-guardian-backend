import '../services/api_service.dart';

class AuthService {
  static Future<bool> login(String phone, String otp) async {
    final res = await ApiService.postRequest("/login", {
      "phone": phone,
      "otp": otp,
    });

    return res["success"] ?? false;
  }
}
