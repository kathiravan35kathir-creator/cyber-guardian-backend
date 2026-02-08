import 'dart:async';
import 'package:flutter/material.dart';
import '../services/sos_service.dart';
import 'guardians_screen.dart';

class HomeScreen extends StatefulWidget {
  final String phone;
  const HomeScreen({super.key, required this.phone});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool sosTriggered = false;
  int countdown = 5;
  Timer? timer;

  // 🔴 AUTO SOS LOGIC
  void startAutoSOS() {
    sosTriggered = true;
    countdown = 5;

    timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      setState(() {
        countdown--;
      });

      if (countdown == 0) {
        t.cancel();
        await sendSOS(auto: true);
      }
    });

    setState(() {});
  }

  void cancelSOS() {
    timer?.cancel();
    sosTriggered = false;
    setState(() {});
  }

  // 🔥 SOS SEND
  Future<void> sendSOS({bool auto = false}) async {
    bool success = await SosService.sendSOS(
      phone: widget.phone,
      reason: auto ? "AUTO SOS – Threat detected" : "Manual SOS",
    );

    setState(() {
      sosTriggered = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? "🚨 SOS Sent Successfully" : "❌ SOS Failed",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cyber Guardian"),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GuardiansScreen(userPhone: widget.phone),
                ),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🚨 AUTO SOS UI
            if (sosTriggered) ...[
              const Text(
                "⚠️ Threat Detected",
                style: TextStyle(fontSize: 20, color: Colors.red),
              ),
              const SizedBox(height: 10),
              Text(
                "Sending SOS in $countdown seconds",
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                onPressed: cancelSOS,
                child: const Text("Cancel"),
              ),
            ] else ...[
              // 🔴 MANUAL SOS
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 50, vertical: 20),
                ),
                onPressed: () => sendSOS(),
                child: const Text(
                  "SEND SOS",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              const SizedBox(height: 30),

              // 🧠 AUTO TRIGGER DEMO BUTTON
              ElevatedButton.icon(
                icon: const Icon(Icons.warning),
                label: const Text("Simulate Threat (Auto SOS)"),
                onPressed: startAutoSOS,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
