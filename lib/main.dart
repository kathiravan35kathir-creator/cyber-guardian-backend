import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: "https://eblqqowngjfxirmfjcsl.supabase.co",
    anonKey:
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVibHFxb3duZ2pmeGlybWZqY3NsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAzMDc5NDUsImV4cCI6MjA4NTg4Mzk0NX0.1OobHjr1uiyWz6q9gQW6mlINKIJERwKr-1H60mIkc7U",
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

const String backendBaseUrl =
    "https://cyber-guardian-backend-u7en.onrender.com";

// ================= APP =================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> getStartScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString("app_pin");

    if (supabase.auth.currentUser == null) {
      return const EmailOtpLoginScreen();
    }

    if (pin == null) {
      return const SetPinScreen();
    } else {
      return const PinLoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Cyber Guardian",
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: FutureBuilder(
        future: getStartScreen(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data!;
        },
      ),
    );
  }
}

// ================= SET PIN SCREEN =================

class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  final pinController = TextEditingController();
  final confirmPinController = TextEditingController();

  String msg = "";

  Future<void> savePin() async {
    final pin = pinController.text.trim();
    final confirmPin = confirmPinController.text.trim();

    if (pin.length != 4) {
      setState(() {
        msg = "PIN must be 4 digits!";
      });
      return;
    }

    if (pin != confirmPin) {
      setState(() {
        msg = "PIN not matching!";
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("app_pin", pin);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Set Security PIN")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Set a 4-digit PIN for app lock",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: pinController,
              decoration: const InputDecoration(
                labelText: "Enter PIN",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmPinController,
              decoration: const InputDecoration(
                labelText: "Confirm PIN",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: savePin,
              child: const Text("Save PIN"),
            ),
            const SizedBox(height: 15),
            Text(
              msg,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= PIN LOGIN SCREEN =================

class PinLoginScreen extends StatefulWidget {
  const PinLoginScreen({super.key});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  final pinController = TextEditingController();
  String msg = "";

  Future<void> verifyPin() async {
    final enteredPin = pinController.text.trim();

    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString("app_pin");

    if (enteredPin == savedPin) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      setState(() {
        msg = "Wrong PIN ❌ Try again";
      });
    }
  }

  Future<void> logout() async {
    await supabase.auth.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("app_pin");

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EmailOtpLoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Enter Security PIN"),
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Welcome back: ${user?.email ?? ""}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: pinController,
              decoration: const InputDecoration(
                labelText: "Enter PIN",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: verifyPin,
              child: const Text("Unlock"),
            ),
            const SizedBox(height: 10),
            Text(
              msg,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= HOME SCREEN (BOTTOM NAV) =================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  final pages = const [
    DashboardScreen(),
    GuardiansScreen(),
    MessageScannerScreen(),
    ThreatHistoryScreen(),
    CallMonitorScreen(),
    VoiceScannerScreen(),
    LinkScannerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.shield), label: "Guardians"),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: "Scan"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(icon: Icon(Icons.call), label: "Calls"),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: "Voice"),
          BottomNavigationBarItem(icon: Icon(Icons.link), label: "Links"),
        ],
      ),
    );
  }
}

// ---------------- EMAIL OTP LOGIN SCREEN ----------------

class EmailOtpLoginScreen extends StatefulWidget {
  const EmailOtpLoginScreen({super.key});

  @override
  State<EmailOtpLoginScreen> createState() => _EmailOtpLoginScreenState();
}

class _EmailOtpLoginScreenState extends State<EmailOtpLoginScreen> {
  final emailController = TextEditingController();
  final otpController = TextEditingController();

  bool otpSent = false;
  String msg = "";

  Future<void> sendOtp() async {
    try {
      final email = emailController.text.trim();

      if (!email.contains("@")) {
        setState(() {
          msg = "Enter valid email!";
        });
        return;
      }

      await supabase.auth.signInWithOtp(email: email);

      setState(() {
        otpSent = true;
        msg = "OTP sent to your email!";
      });
    } catch (e) {
      setState(() {
        msg = "OTP send failed: $e";
      });
    }
  }

  Future<void> verifyOtp() async {
    try {
      final email = emailController.text.trim();
      final otp = otpController.text.trim();

      await supabase.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );

      final prefs = await SharedPreferences.getInstance();
      final pin = prefs.getString("app_pin");

      if (mounted) {
        if (pin == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SetPinScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PinLoginScreen()),
          );
        }
      }
    } catch (e) {
      setState(() {
        msg = "OTP verify failed: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Email OTP Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: sendOtp,
              child: const Text("Send OTP"),
            ),
            const SizedBox(height: 20),
            if (otpSent) ...[
              TextField(
                controller: otpController,
                decoration: const InputDecoration(
                  labelText: "Enter OTP",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: verifyOtp,
                child: const Text("Verify OTP"),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              msg,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= DASHBOARD SCREEN =================

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int totalScans = 0;
  int dangerCount = 0;
  int cautionCount = 0;
  int safeCount = 0;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  Future<void> loadStats() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from("threat_history")
          .select()
          .eq("user_id", user.id);

      totalScans = data.length;

      dangerCount =
          data.where((e) => (e["status"] ?? "").toString() == "Danger").length;
      cautionCount =
          data.where((e) => (e["status"] ?? "").toString() == "Caution").length;
      safeCount =
          data.where((e) => (e["status"] ?? "").toString() == "Safe").length;
    } catch (e) {
      debugPrint("Dashboard load error: $e");
    }

    setState(() {
      loading = false;
    });
  }

  int calculateSafetyScore() {
    if (totalScans == 0) return 100;

    int score = 100 - (dangerCount * 20) - (cautionCount * 10);
    if (score < 0) score = 0;
    return score;
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cyber Guardian Dashboard"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              "Welcome: ${user?.email ?? "Unknown"}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: const Icon(Icons.security),
                title: const Text("Cyber Safety Score"),
                subtitle: Text("${calculateSafetyScore()} / 100"),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.history),
                title: const Text("Total Scans"),
                subtitle: Text("$totalScans"),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text("Safe Scans"),
                subtitle: Text("$safeCount"),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.warning, color: Colors.orange),
                title: const Text("Caution Scans"),
                subtitle: Text("$cautionCount"),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.dangerous, color: Colors.red),
                title: const Text("Danger Scans"),
                subtitle: Text("$dangerCount"),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: loadStats,
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh Dashboard"),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- GUARDIANS SCREEN ----------------

class GuardiansScreen extends StatefulWidget {
  const GuardiansScreen({super.key});

  @override
  State<GuardiansScreen> createState() => _GuardiansScreenState();
}

class _GuardiansScreenState extends State<GuardiansScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  String msg = "";
  List guardians = [];

  @override
  void initState() {
    super.initState();
    loadGuardians();
  }

  Future<void> loadGuardians() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from("guardians")
          .select()
          .eq("user_id", user.id)
          .order("created_at", ascending: false);

      setState(() {
        guardians = data;
      });
    } catch (e) {
      setState(() {
        msg = "Load error: $e";
      });
    }
  }

  Future<void> addGuardian() async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      await supabase.from("guardians").insert({
        "user_id": currentUser.id,
        "guardian_name": nameController.text.trim(),
        "guardian_phone": phoneController.text.trim(),
        "relation": "Friend",
        "user_phone": currentUser.email ?? "unknown"
      });

      setState(() {
        msg = "Guardian Added!";
        nameController.clear();
        phoneController.clear();
      });

      loadGuardians();
    } catch (e) {
      setState(() {
        msg = "Insert error: $e";
      });
    }
  }

  Future<void> logout() async {
    await supabase.auth.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("app_pin");

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EmailOtpLoginScreen()),
      );
    }
  }

  Future<void> resetPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("app_pin");

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SetPinScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Guardians"),
        actions: [
          IconButton(
            onPressed: resetPin,
            icon: const Icon(Icons.lock_reset),
          ),
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Logged in: ${user?.email ?? "Unknown"}"),
            const SizedBox(height: 10),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Guardian Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: "Guardian Phone",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: addGuardian,
              child: const Text("Add Guardian"),
            ),
            const SizedBox(height: 10),
            Text(msg),
            const Divider(),
            Expanded(
              child: guardians.isEmpty
                  ? const Center(child: Text("No Guardians Found"))
                  : ListView.builder(
                itemCount: guardians.length,
                itemBuilder: (context, index) {
                  final g = guardians[index];
                  return Card(
                    child: ListTile(
                      title: Text(g["guardian_name"] ?? ""),
                      subtitle: Text(g["guardian_phone"] ?? ""),
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

// ================= MESSAGE SCANNER SCREEN =================

class MessageScannerScreen extends StatefulWidget {
  const MessageScannerScreen({super.key});

  @override
  State<MessageScannerScreen> createState() => _MessageScannerScreenState();
}

class _MessageScannerScreenState extends State<MessageScannerScreen> {
  final messageController = TextEditingController();

  bool loading = false;
  String status = "";
  int riskScore = 0;
  List reasons = [];

  Future<void> saveHistory(
      String type, String content, String status, int riskScore, List reasons) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from("threat_history").insert({
        "user_id": user.id,
        "type": type,
        "content": content,
        "status": status,
        "risk_score": riskScore,
        "reasons": reasons,
      });
    } catch (e) {
      debugPrint("Save history error: $e");
    }
  }

  Future<void> scanMessage() async {
    setState(() {
      loading = true;
      status = "";
      riskScore = 0;
      reasons = [];
    });

    try {
      final url = Uri.parse("$backendBaseUrl/analyze/message");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": messageController.text.trim()}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        String st = data["status"] ?? "Unknown";
        int rs = data["risk_score"] ?? 0;
        List r = data["reasons"] ?? [];

        setState(() {
          status = st;
          riskScore = rs;
          reasons = r;
        });

        await saveHistory("message", messageController.text.trim(), st, rs, r);
      } else {
        setState(() {
          status = "Error";
          reasons = ["Backend error: ${response.statusCode}"];
        });
      }
    } catch (e) {
      setState(() {
        status = "Error";
        reasons = ["$e"];
      });
    }

    setState(() {
      loading = false;
    });
  }

  Color getStatusColor(String status) {
    if (status.toLowerCase() == "danger") return Colors.red;
    if (status.toLowerCase() == "caution") return Colors.orange;
    return Colors.green;
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
              controller: messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Paste message here",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: loading ? null : scanMessage,
              icon: const Icon(Icons.search),
              label: const Text("Scan Message"),
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
              Text(
                "Risk Score: $riskScore",
                style: const TextStyle(fontSize: 16),
              ),
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

// ================= THREAT HISTORY SCREEN =================

class ThreatHistoryScreen extends StatefulWidget {
  const ThreatHistoryScreen({super.key});

  @override
  State<ThreatHistoryScreen> createState() => _ThreatHistoryScreenState();
}

class _ThreatHistoryScreenState extends State<ThreatHistoryScreen> {
  List history = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      // Try fetching history from backend first
      try {
        final resp = await http.get(Uri.parse("$backendBaseUrl/threat-history"));
        if (resp.statusCode == 200) {
          final decoded = jsonDecode(resp.body);
          // backend returns { "history": [ ... ] }
          final hs = decoded["history"] ?? [];
          setState(() {
            history = hs;
          });
          setState(() {
            loading = false;
          });
          return;
        }
      } catch (e) {
        debugPrint("Backend history fetch failed, falling back to Supabase: $e");
      }

      // Fallback: fetch directly from Supabase
      final data = await supabase
          .from("threat_history")
          .select()
          .eq("user_id", user.id)
          .order("created_at", ascending: false);

      setState(() {
        history = data;
      });
    } catch (e) {
      debugPrint("History load error: $e");
    }

    setState(() {
      loading = false;
    });
  }

  Color getStatusColor(String status) {
    if (status.toLowerCase() == "danger") return Colors.red;
    if (status.toLowerCase() == "caution") return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Threat History"),
        actions: [
          IconButton(
            onPressed: loadHistory,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : history.isEmpty
          ? const Center(child: Text("No History Found"))
          : ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) {
          final h = history[index];
          return Card(
            child: ListTile(
              leading: Icon(Icons.report,
                  color: getStatusColor(h["status"] ?? "")),
              title: Text(h["content"] ?? ""),
              subtitle: Text(
                  "Type: ${h["type"]} | Status: ${h["status"]} | Risk: ${h["risk_score"]}"),
            ),
          );
        },
      ),
    );
  }
}

// ================= CALL MONITOR SCREEN =================

class CallMonitorScreen extends StatefulWidget {
  const CallMonitorScreen({super.key});

  @override
  State<CallMonitorScreen> createState() => _CallMonitorScreenState();
}

class _CallMonitorScreenState extends State<CallMonitorScreen> {
  final callController = TextEditingController();
  bool loading = false;
  String status = "";
  int riskScore = 0;
  List reasons = [];

  Future<void> scanCall() async {
    setState(() {
      loading = true;
      status = "";
      riskScore = 0;
      reasons = [];
    });

    try {
      final response = await http.post(
        Uri.parse("$backendBaseUrl/analyze/call"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"call_info": callController.text.trim()}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          status = data["status"] ?? "Unknown";
          riskScore = data["risk_score"] ?? 0;
          reasons = data["reasons"] ?? [];
        });

        await supabase.from("threat_history").insert({
          "user_id": supabase.auth.currentUser!.id,
          "type": "call",
          "content": callController.text.trim(),
          "status": status,
          "risk_score": riskScore,
          "reasons": reasons,
        });
      } else {
        setState(() {
          status = "Error";
          reasons = ["Backend error: ${response.statusCode}"];
        });
      }
    } catch (e) {
      setState(() {
        status = "Error";
        reasons = ["$e"];
      });
    }

    setState(() {
      loading = false;
    });
  }

  Color getStatusColor(String status) {
    if (status.toLowerCase() == "danger") return Colors.red;
    if (status.toLowerCase() == "caution") return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Incoming Call Risk Scanner")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: callController,
              decoration: const InputDecoration(
                labelText: "Enter caller number / info",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: loading ? null : scanCall,
              icon: const Icon(Icons.call),
              label: const Text("Scan Call"),
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
              Text("Risk Score: $riskScore"),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
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
              )
            ]
          ],
        ),
      ),
    );
  }
}

// ================= VOICE SCANNER SCREEN =================

class VoiceScannerScreen extends StatefulWidget {
  const VoiceScannerScreen({super.key});

  @override
  State<VoiceScannerScreen> createState() => _VoiceScannerScreenState();
}

class _VoiceScannerScreenState extends State<VoiceScannerScreen> {
  final voiceController = TextEditingController();
  bool loading = false;
  String status = "";
  int riskScore = 0;
  List reasons = [];

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

        setState(() {
          status = data["status"] ?? "Unknown";
          riskScore = data["risk_score"] ?? 0;
          reasons = data["reasons"] ?? [];
        });

        await supabase.from("threat_history").insert({
          "user_id": supabase.auth.currentUser!.id,
          "type": "voice",
          "content": voiceController.text.trim(),
          "status": status,
          "risk_score": riskScore,
          "reasons": reasons,
        });
      } else {
        setState(() {
          status = "Error";
          reasons = ["Backend error: ${response.statusCode}"];
        });
      }
    } catch (e) {
      setState(() {
        status = "Error";
        reasons = ["$e"];
      });
    }

    setState(() {
      loading = false;
    });
  }

  Color getStatusColor(String status) {
    if (status.toLowerCase() == "danger") return Colors.red;
    if (status.toLowerCase() == "caution") return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Voice Scam Detector")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: voiceController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Paste call transcript here",
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
              Text("Risk Score: $riskScore"),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
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
              )
            ]
          ],
        ),
      ),
    );
  }
}

// ================= LINK SCANNER SCREEN =================

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

        setState(() {
          status = data["status"] ?? "Unknown";
          riskScore = data["risk_score"] ?? 0;
          reasons = data["reasons"] ?? [];
        });

        await supabase.from("threat_history").insert({
          "user_id": supabase.auth.currentUser!.id,
          "type": "link",
          "content": linkController.text.trim(),
          "status": status,
          "risk_score": riskScore,
          "reasons": reasons,
        });
      } else {
        setState(() {
          status = "Error";
          reasons = ["Backend error: ${response.statusCode}"];
        });
      }
    } catch (e) {
      setState(() {
        status = "Error";
        reasons = ["$e"];
      });
    }

    setState(() {
      loading = false;
    });
  }

  Color getStatusColor(String status) {
    if (status.toLowerCase() == "danger") return Colors.red;
    if (status.toLowerCase() == "caution") return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Link / URL Scam Scanner")),
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
              Text("Risk Score: $riskScore"),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
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
              )
            ]
          ],
        ),
      ),
    );
  }
}
