import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;
const String backendBaseUrl = "https://cyber-guardian-backend-u7en.onrender.com";

class VoiceScannerScreen extends StatefulWidget {
  const VoiceScannerScreen({super.key});

  @override
  State<VoiceScannerScreen> createState() => _VoiceScannerScreenState();
}

class _VoiceScannerScreenState extends State<VoiceScannerScreen> {
  bool loading = false;
  String status = "";
  int riskScore = 0;
  List reasons = [];
  final voiceController = TextEditingController(); // For simplicity, paste transcript

  Future<void> scanVoice() async {
    setState(() {
      loading = true;
      status = "";
      riskScore = 0;
      reasons = [];
    });

    try {
      final response = await http.post(
        Uri.parse("$backendBaseUrl/analyze/voice"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"voice_text": voiceController.text.trim()}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        status = data["status"] ?? "Unknown";
        riskScore = data["risk_score"] ?? 0;
        reasons = data["reasons"] ?? [];

        await saveHistory(voiceController.text.trim(), data);
      } else {
        status = "Error";
        reasons = ["Backend error: ${response.statusCode}"];
      }
    } catch (e) {
      status = "Error";
      reasons = ["$e"];
    }

    setState(() {
      loading = false;
    });
  }

  Future<void> saveHistory(String voiceText, Map data) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from("threat_history").insert({
        "user_id": user.id,
        "type": "voice",
        "content": voiceText,
        "status": data["status"] ?? "Unknown",
        "risk_score": data["risk_score"] ?? 0,
        "reasons": data["reasons"] ?? [],
      });
    } catch (e) {
      debugPrint("Voice history save error: $e");
    }
  }

  Color getStatusColor(String status) {
    if (status.toLowerCase() == "danger") return Colors.red;
    if (status.toLowerCase() == "caution") return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Voice Scam Scanner")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: voiceController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Paste call/voice transcript here",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: loading ? null : scanVoice,
              icon: const Icon(Icons.mic),
              label: const Text("Scan Voice"),
            ),
            const SizedBox(height: 20),
            if (loading) const CircularProgressIndicator(),
            if (!loading && status.isNotEmpty) ...[
              Text(
                "Status: $status",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: getStatusColor(status),
                ),
              ),
              const SizedBox(height: 8),
              Text("Risk Score: $riskScore", style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Reasons:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: reasons.isEmpty
                    ? const Text("No reasons found")
                    : ListView.builder(
                  itemCount: reasons.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.warning),
                        title: Text(reasons[index].toString()),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
