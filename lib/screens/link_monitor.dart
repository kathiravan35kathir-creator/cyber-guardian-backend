import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;
const String backendBaseUrl = "https://cyber-guardian-backend-u7en.onrender.com";

class LinkScannerScreen extends StatefulWidget {
  const LinkScannerScreen({super.key});

  @override
  State<LinkScannerScreen> createState() => _LinkScannerScreenState();
}

class _LinkScannerScreenState extends State<LinkScannerScreen> {
  final linkController = TextEditingController();

  bool loading = false;
  String status = "";
  int riskScore = 0;
  List reasons = [];

  Future<void> scanLink() async {
    setState(() {
      loading = true;
      status = "";
      riskScore = 0;
      reasons = [];
    });

    try {
      final response = await http.post(
        Uri.parse("$backendBaseUrl/analyze/link"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"link": linkController.text.trim()}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        status = data["status"] ?? "Unknown";
        riskScore = data["risk_score"] ?? 0;
        reasons = data["reasons"] ?? [];

        await saveHistory(linkController.text.trim(), data);
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

  Future<void> saveHistory(String link, Map data) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from("threat_history").insert({
        "user_id": user.id,
        "type": "link",
        "content": link,
        "status": data["status"] ?? "Unknown",
        "risk_score": data["risk_score"] ?? 0,
        "reasons": data["reasons"] ?? [],
      });
    } catch (e) {
      debugPrint("Link history save error: $e");
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
      appBar: AppBar(title: const Text("Link / URL Scanner")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: linkController,
              decoration: const InputDecoration(
                labelText: "Paste link here",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: loading ? null : scanLink,
              icon: const Icon(Icons.link),
              label: const Text("Scan Link"),
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
