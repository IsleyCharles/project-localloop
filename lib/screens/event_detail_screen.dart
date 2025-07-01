// event_detail_screen.dart
// This screen displays detailed information about a specific event, allows users to join, and submit feedback.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventDetailScreen extends StatefulWidget {
  // Event data passed from the previous screen
  final Map<String, dynamic> eventData;

  const EventDetailScreen({super.key, required this.eventData});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool hasJoined = false;
  bool isLoading = true;
  final TextEditingController _feedbackController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _checkIfJoined();
  }

  // Check if the current user has joined the event (fetches fresh data from Firestore)
  void _checkIfJoined() async {
    final uid = user?.uid;
    final docRef = widget.eventData['docRef'] as DocumentReference?;

    if (uid == null || docRef == null) return;

    final freshSnapshot = await docRef.get();
    final freshData = freshSnapshot.data() as Map<String, dynamic>?;

    final participants = List<String>.from(freshData?['participants'] ?? []);
    setState(() {
      hasJoined = participants.contains(uid);
      isLoading = false;
    });
  }

  // Submit feedback for the event
  Future<void> _submitFeedback() async {
    final docRef = widget.eventData['docRef'] as DocumentReference?;
    final uid = user?.uid;

    if (docRef == null || uid == null) return;

    final feedback = _feedbackController.text.trim();
    if (feedback.isEmpty) return;

    await docRef.collection('feedback').add({
      'uid': uid,
      'feedback': feedback,
      'timestamp': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Feedback submitted!")),
    );

    _feedbackController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.eventData;
    final formattedDate = event['date'] is Timestamp
        ? (event['date'] as Timestamp).toDate().toString().split(' ')[0]
        : event['date'].toString();

    return Scaffold(
      appBar: AppBar(title: Text(event['title'] ?? 'Event Details')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event['title'] ?? '', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('📍 Location: ${event['location'] ?? 'Not specified'}'),
                  const SizedBox(height: 8),
                  Text('🗓️ Date: $formattedDate'),
                  const SizedBox(height: 8),
                  Text('📝 Description:'),
                  Text(event['description'] ?? 'No description provided.'),
                  const Spacer(),

                  if (!hasJoined)
                    ElevatedButton.icon(
                      onPressed: () async {
                        final uid = user?.uid;
                        final docRef = event['docRef'] as DocumentReference?;
                        if (uid != null && docRef != null) {
                          await docRef.update({
                            'participants': FieldValue.arrayUnion([uid]),
                          });
                          _checkIfJoined(); // Call without await, since it returns void
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Successfully joined the event!")),
                          );
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text("Join Event"),
                    ),

                  if (hasJoined) ...[
                    const SizedBox(height: 20),
                    const Text("Leave Feedback", style: TextStyle(fontWeight: FontWeight.bold)),
                    TextField(
                      controller: _feedbackController,
                      decoration: const InputDecoration(hintText: "Type your feedback here..."),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _submitFeedback,
                      icon: const Icon(Icons.feedback),
                      label: const Text("Submit Feedback"),
                    ),
                  ]
                ],
              ),
            ),
    );
  }
}
