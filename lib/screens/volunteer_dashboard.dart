import 'package:flutter/material.dart';
import '../widgets/dashboard_layout.dart';

class VolunteerDashboard extends StatelessWidget {
  const VolunteerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      role: 'volunteer',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () {},
            child: const Text('Find Events'),
          ),
          ElevatedButton(
            onPressed: () {},
            child: const Text('My Participation'),
          ),
        ],
      ),
    );
  }
}
