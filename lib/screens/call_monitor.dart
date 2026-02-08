import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;
const String backendBaseUrl = "https://cyber-guardian-backend-u7en.onrender.com";

class CallMonitorScreen extends StatefulWidget {
  const CallMonitorScreen({super.key});

  @override
  State<CallMonitorScreen> createState() => _CallMonitorScreenState();
}

class _CallMonitorScreenState extends State<CallMonitorScreen> {
  bool monitoring = false;
  List callAlerts = [];

  void toggleMonitoring() async {
    setState(() {
      monitoring = !monitoring;
      callAlerts.add(monitoring
          ? "Started silent call monitoring..."
          : "Stopped monitoring");
    });

    if (monitoring) {
      // Example: simulate incoming call detection every 5 sec
      for (int i = 0; i < 3; i++) {
        await Future.delayed(const Duration(seconds: 5));
        String fakeCall = "Incoming call from +91-90000${i}0000";
        var result = await analyzeCall(fakeCall);
        setState(() {
          callAlerts.add(result);
        });
      }
    }
  }

  Future<String> analyzeCall(String callInfo) async {
    try {
      final response = await http.post(
        Uri.parse("$backendBaseUrl/analyze/call"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"call_info": callInfo}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Example backend returns {"status":"Safe","risk_score":10,"reasons":["No scam detected"]}
        await saveHistory(callInfo, data);
        return "${callInfo} → ${data["status"]} ⚡";
      } else {
        return "Backend error: ${response.statusCode}";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  Future<void> saveHistory(callInfo, data) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from("threat_history").insert({
        "user_id": user.id,
        "type": "call",
        "content": callInfo,
        "status": data["status"] ?? "Unknown",
        "risk_score": data["risk_score"] ?? 0,
        "reasons": data["reasons"] ?? [],
      });
    } catch (e) {
      debugPrint("Call history save error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Call Monitor")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: toggleMonitoring,
              child:
              Text(monitoring ? "Stop Monitoring" : "Start Monitoring"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: callAlerts.isEmpty
                  ? const Center(child: Text("No alerts yet"))
                  : ListView.builder(
                itemCount: callAlerts.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.call),
                      title: Text(callAlerts[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
