import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/guardian_model.dart';

final supabase = Supabase.instance.client;

class GuardiansScreen extends StatefulWidget {
  final String userPhone;
  const GuardiansScreen({super.key, required this.userPhone});

  @override
  State<GuardiansScreen> createState() => _GuardiansScreenState();
}

class _GuardiansScreenState extends State<GuardiansScreen> {
  final List<Guardian> guardians = [];
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchGuardians();
  }

  // Fetch guardians
  Future<void> fetchGuardians() async {
    try {
      final List<dynamic> data = await supabase
          .from('guardians')
          .select()
          .eq('user_phone', widget.userPhone);

      setState(() {
        guardians.clear();
        guardians.addAll(
          data.map((g) => Guardian.fromJson(Map<String, dynamic>.from(g))),
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching guardians: $e")),
        );
      }
    }
  }

  // Add guardian
  void addGuardian() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) return;

    try {
      await supabase.from('guardians').insert({
        'user_phone': widget.userPhone,
        'guardian_name': name,
        'guardian_phone': phone,
      });

      nameController.clear();
      phoneController.clear();
      fetchGuardians(); // refresh list from DB
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error adding guardian: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Guardians"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Guardian Name",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: "Guardian Phone",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: addGuardian,
              child: const Text(
                "Add Guardian",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: guardians.isEmpty
                  ? const Center(
                child: Text(
                  "No Guardians Found",
                  style: TextStyle(color: Colors.white70),
                ),
              )
                  : ListView.builder(
                itemCount: guardians.length,
                itemBuilder: (context, index) {
                  final g = guardians[index];
                  return Card(
                    color: Colors.white12,
                    child: ListTile(
                      title: Text(
                        g.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        g.phone,
                        style: const TextStyle(color: Colors.white70),
                      ),
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
