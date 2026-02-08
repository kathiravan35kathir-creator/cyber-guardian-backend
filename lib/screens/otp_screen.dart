import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class OTPScreen extends StatefulWidget {
  final String phone;
  const OTPScreen({super.key, required this.phone});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final TextEditingController otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("OTP Verification",
                  style: TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("OTP sent to ${widget.phone}", style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 30),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Enter OTP",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15)),
                onPressed: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => DashboardScreen(userPhone: widget.phone)));
                },
                child: const Text("Verify OTP", style: TextStyle(color: Colors.black)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
