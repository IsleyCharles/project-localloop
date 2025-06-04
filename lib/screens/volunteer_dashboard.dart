import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'event_detail_screen.dart';

// ignore: use_key_in_widget_constructors
class VolunteerDashboardScreen extends StatefulWidget {
  const VolunteerDashboardScreen({super.key});

  @override
  VolunteerDashboardScreenState createState() => VolunteerDashboardScreenState();
}

class VolunteerDashboardScreenState extends State<VolunteerDashboardScreen> {
  String searchTerm = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, Volunteer'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              // Navigate to login screen
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) => setState(() => searchTerm = value),
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('events')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No events available."));
                }

                final filteredEvents = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = data['title']?.toLowerCase() ?? '';
                  return title.contains(searchTerm.toLowerCase());
                }).toList();

                if (filteredEvents.isEmpty) {
                  return Center(child: Text("No matching events found."));
                }

                return ListView.builder(
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final doc = filteredEvents[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['title'] ?? 'No Title'),
                      subtitle: Text(data['location'] ?? 'No Location'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EventDetailScreen(
                              eventData: {
                                ...data,
                                'docRef': doc.reference,
                              },
                            ),
                          )
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
 