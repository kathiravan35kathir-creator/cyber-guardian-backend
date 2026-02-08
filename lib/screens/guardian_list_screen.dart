import 'package:flutter/material.dart';
import '../services/guardian_service.dart';
import '../models/guardian_model.dart';

class GuardianListScreen extends StatefulWidget {
  const GuardianListScreen({super.key});

  @override
  State<GuardianListScreen> createState() => _GuardianListScreenState();
}

class _GuardianListScreenState extends State<GuardianListScreen> {
  late Future<List<String>> guardians;

  @override
  void initState() {
    super.initState();
    guardians = GuardianService.getGuardians("9876543210");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Guardians")),
      body: FutureBuilder<List<String>>(
        future: guardians,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final data = snapshot.data!;

          if (data.isEmpty) {
            return const Center(child: Text("No guardians added"));
          }

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text("Guardian ${index + 1}"),
                subtitle: Text(data[index]),
              );
            },
          );
        },
      ),
    );
  }
}
