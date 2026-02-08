import 'package:flutter/material.dart';
import 'pin_lock_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PinLockScreen()),
      );
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.shield, size: 80, color: Colors.blue),
            SizedBox(height: 16),
            Text("SENTINEL GUARD",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text("Active Phone Protection",
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
