import 'package:local_auth/local_auth.dart';

class PinLoginScreen extends StatefulWidget {
  const PinLoginScreen({super.key});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  final pinController = TextEditingController();
  String msg = "";

  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    biometricLogin();
  }

  Future<void> biometricLogin() async {
    try {
      bool canCheck = await auth.canCheckBiometrics;
      bool supported = await auth.isDeviceSupported();

      if (!canCheck || !supported) return;

      bool authenticated = await auth.authenticate(
        localizedReason: "Use fingerprint to unlock Cyber Guardian",
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint("Biometric error: $e");
    }
  }

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
        title: const Text("Unlock Cyber Guardian"),
        actions: [
          IconButton(
            onPressed: biometricLogin,
            icon: const Icon(Icons.fingerprint),
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
              child: const Text("Unlock with PIN"),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: biometricLogin,
              icon: const Icon(Icons.fingerprint),
              label: const Text("Unlock with Fingerprint"),
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
