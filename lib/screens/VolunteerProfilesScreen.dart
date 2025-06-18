// VolunteerProfilesScreen.dart
// Displays a list of volunteer users and allows role assignment.

import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore database
import 'package:flutter/material.dart'; // Flutter UI framework

class VolunteerProfilesScreen extends StatelessWidget {
  const VolunteerProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Volunteer Profiles")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'volunteer')
            .snapshots(),
        builder: (context, snapshot) {
          // Show a loading indicator while waiting for data
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // If no data is found, display a message
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No volunteers found.'));
          }

          final volunteers = snapshot.data!.docs;

          return ListView.builder(
            itemCount: volunteers.length,
            itemBuilder: (context, index) {
              final data = volunteers[index].data() as Map<String, dynamic>;
              final docRef = volunteers[index].reference;

              String name = data['name'] ?? 'Unnamed Volunteer';
              String email = data['email'] ?? 'No Email';
              String currentRole = data['assignedRole'] ?? 'Member';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(email),
                      const SizedBox(height: 4),
                      Text("Current Role: $currentRole"),
                    ],
                  ),
                  trailing: DropdownButton<String>(
                    value: currentRole,
                    items: ['Member', 'Coordinator', 'Lead'].map((role) {
                      return DropdownMenuItem(value: role, child: Text(role));
                    }).toList(),
                    onChanged: (newRole) {
                      // When a new role is selected, show a confirmation dialog
                      if (newRole != null && newRole != currentRole) {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Change Role"),
                            content: Text("Assign $newRole role to $name?"),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancel")),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  // Update the user's role in the database
                                  await docRef.update({'assignedRole': newRole});
                                  // Show a snackbar notification
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("$name is now a $newRole"),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: const Text("Confirm"),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
