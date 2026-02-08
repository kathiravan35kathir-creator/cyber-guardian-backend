import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MessageScanPage extends StatefulWidget {
  const MessageScanPage({super.key});

  @override
  State<MessageScanPage> createState() => _MessageScanPageState();
}

class _MessageScanPageState extends State<MessageScanPage> {
  final TextEditingController _controller = TextEditingController();
  String result = "";
  bool loading = false;

  void scanMessage() async {
    setState(() {
      loading = true;
      result = "";
    });

    try {
      final response = await ApiService.analyzeMessage(_controller.text);

      setState(() {
        result = response.toString();
      });
    } catch (e) {
      setState(() {
        result = "Error: $e";
      });
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Message Scam Scanner")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Enter message",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: loading ? null : scanMessage,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Scan Message"),
            ),
            const SizedBox(height: 20),
            Text(result),
          ],
        ),
      ),
    );
  }
}
