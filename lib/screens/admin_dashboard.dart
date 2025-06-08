import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  void _deleteEvent(DocumentReference eventRef) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Event'),
        content: Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      await eventRef.delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Event deleted')));
    }
  }

  void _sendNotificationToParticipants(
    DocumentReference eventRef,
    List<dynamic> participants,
  ) async {
    final TextEditingController messageController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send Notification'),
        content: TextField(
          controller: messageController,
          maxLines: 3,
          decoration: InputDecoration(hintText: 'Enter notification message'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Send')),
        ],
      ),
    );

    if (result == true && messageController.text.trim().isNotEmpty) {
      final message = messageController.text.trim();

      for (var uid in participants) {
        await FirebaseFirestore.instance
            .collection('notifications')
            .add({
              'toUser': uid,
              'eventRef': eventRef,
              'message': message,
              'timestamp': Timestamp.now(),
            });
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Notification sent')));
    }
  }

  void _logout() {
    FirebaseAuth.instance.signOut();
    // Navigate to login screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No events found'));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] ?? 'No Title';
              final date = (data['date'] as Timestamp).toDate();
              final location = data['location'] ?? 'Unknown';
              final participants = (data['participants'] as List<dynamic>?) ?? [];

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ExpansionTile(
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    '📍 $location | 📅 ${date.toLocal().toString().split(' ')[0]}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '👥 Participants (${participants.length})',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          participants.isEmpty
                              ? const Text('No participants yet')
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: participants.map((p) => Text('• $p')).toList(),
                                ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _deleteEvent(doc.reference),
                                icon: const Icon(Icons.delete),
                                label: const Text('Delete'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _sendNotificationToParticipants(doc.reference, participants),
                                icon: const Icon(Icons.notifications),
                                label: const Text('Notify'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
