import 'package:flutter/material.dart';

class SosButton extends StatelessWidget {
  const SosButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      ),
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🚨 SOS Alert sent to Guardian!"),
          ),
        );
      },
      icon: const Icon(Icons.sos),
      label: const Text("SEND SOS"),
    );
  }
}
