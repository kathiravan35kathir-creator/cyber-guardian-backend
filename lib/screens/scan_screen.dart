import 'package:flutter/material.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final TextEditingController messageController = TextEditingController();
  String result = "";

  void scanMessage() {
    final text = messageController.text;
    setState(() {
      if (text.contains("http")) {
        result = "⚠️ Suspicious link detected!";
      } else {
        result = "✅ Message safe";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Scan Message/Link"), backgroundColor: Colors.black),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Paste message or link",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
              onPressed: scanMessage,
              child: const Text("Scan", style: TextStyle(color: Colors.black)),
            ),
            const SizedBox(height: 20),
            Text(result, style: const TextStyle(color: Colors.greenAccent, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
