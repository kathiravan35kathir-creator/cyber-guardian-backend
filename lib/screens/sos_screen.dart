import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SosScreen extends StatefulWidget {
  final String userPhone;
  const SosScreen({super.key, required this.userPhone});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  String status = "";

  Future<void> sendSOS() async {
    final res = await ApiService.postRequest("/sos", {
      "user_phone": widget.userPhone,
      "reason": "Emergency Triggered"
    });

    setState(() {
      status = res["message"] ?? "SOS Sent";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, title: const Text("SOS Emergency")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(80),
              ),
              onPressed: sendSOS,
              child: const Text("SOS", style: TextStyle(fontSize: 30, color: Colors.white)),
            ),
            const SizedBox(height: 20),
            Text(status, style: const TextStyle(color: Colors.greenAccent, fontSize: 18))
          ],
        ),
      ),
    );
  }
}
