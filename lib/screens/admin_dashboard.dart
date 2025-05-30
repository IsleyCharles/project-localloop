import 'package:flutter/material.dart';
import '../widgets/dashboard_layout.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      role: 'admin',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(onPressed: () {}, child: const Text('Manage Users')),
          ElevatedButton(onPressed: () {}, child: const Text('View Reports')),
        ],
      ),
    );
  }
}
