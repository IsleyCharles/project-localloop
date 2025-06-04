// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventDetailScreen extends StatelessWidget {
  final Map<String, dynamic> eventData;

  const EventDetailScreen({super.key, required this.eventData});

  @override
  Widget build(BuildContext context) {
    // Safely extract date
    String formattedDate = 'Unknown';
    if (eventData['date'] is Timestamp) {
      formattedDate =
          (eventData['date'] as Timestamp).toDate().toLocal().toString().split(" ")[0];
    } else if (eventData['date'] is String) {
      formattedDate = eventData['date'];
    }

    return Scaffold(
      appBar: AppBar(title: Text(eventData['title'] ?? 'Event Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(eventData['title'] ?? '',
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            Text('📍 Location: ${eventData['location'] ?? 'Not specified'}'),
            SizedBox(height: 8),
            Text('🗓️ Date: $formattedDate'),
            SizedBox(height: 8),
            Text('📝 Description:'),
            Text(eventData['description'] ?? 'No description provided.'),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () async {
                final uid = FirebaseAuth.instance.currentUser!.uid;

                // Validate that docRef exists and is a DocumentReference
                final docRef = eventData['docRef'];
                if (docRef == null || docRef is! DocumentReference) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Invalid event reference.")),
                  );
                  return;
                }

                try {
                  await docRef.update({
                    'participants': FieldValue.arrayUnion([uid]),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Successfully joined the event!")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to join: $e")),
                  );
                }
              },
              icon: Icon(Icons.check),
              label: Text("Join Event"),
            ),
          ],
        ),
      ),
    );
  }
}
