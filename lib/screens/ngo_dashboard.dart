import 'package:flutter/material.dart';
import '../widgets/dashboard_layout.dart';

class NGODashboard extends StatelessWidget {
  const NGODashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      role: 'ngo',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () {},
            child: const Text('Post Event'),
          ),
          ElevatedButton(
            onPressed: () {},
            child: const Text('View Volunteers'),
          ),
        ],
      ),
    );
  }
}
