import 'package:flutter/material.dart';

class VolunteerDashboard extends StatelessWidget {
  const VolunteerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Volunteer Dashboard')),
      body: const Center(
        child: Text('Welcome, Volunteer! You can discover events and track your hours here.'),
      ),
    );
  }
}
