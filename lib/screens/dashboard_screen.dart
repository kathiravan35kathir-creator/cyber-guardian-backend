import 'package:flutter/material.dart';
import 'scan_screen.dart';
import 'guardians_screen.dart';
import 'sos_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String userPhone;
  const DashboardScreen({super.key, required this.userPhone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Cyber Guardian Dashboard"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Card(
              color: Colors.greenAccent,
              child: ListTile(
                title: const Text("Safety Score", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("User: $userPhone"),
                trailing: const Text("92%", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildCard(context, "Scan Message", Icons.message, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
                  }),
                  _buildCard(context, "Guardians", Icons.people, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => GuardiansScreen(userPhone: userPhone)));
                  }),
                  _buildCard(context, "SOS", Icons.warning, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => SosScreen(userPhone: userPhone)));
                  }),
                  _buildCard(context, "Threat History", Icons.history, () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.white12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 45, color: Colors.greenAccent),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
