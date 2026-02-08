import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class PermissionScreen extends StatelessWidget {
  const PermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_outlined,
                size: 60, color: Colors.cyan),
            const SizedBox(height: 16),
            const Text("CRITICAL ACCESS",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _permTile("CALL LOGS", "Analyze incoming calls"),
            _permTile("SMS ACCESS", "Detect phishing links"),
            _permTile("DATABASE", "Store evidence securely"),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const DashboardScreen(userPhone: "Unknown")),
                );
              },
              child: const Text("GRANT FULL ACCESS"),
            )
          ],
        ),
      ),
    );
  }

  Widget _permTile(String title, String sub) {
    return ListTile(
      leading: const Icon(Icons.check_circle_outline,
          color: Colors.blueAccent),
      title: Text(title),
      subtitle: Text(sub),
    );
  }
}
