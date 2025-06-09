// ignore_for_file: sort_child_properties_last

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:localloop/auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String? _userRole;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  void _loadUserRole() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      setState(() {
        _userRole = doc.data()?['role'];
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showCreateEventDialog() {
    _showEventDialog();
  }

  void _showEventDialog({DocumentSnapshot? eventDoc}) {
    final isEdit = eventDoc != null;
    final titleController = TextEditingController(text: isEdit ? eventDoc['title'] : '');
    final dateController = TextEditingController(
      text: isEdit ? (eventDoc['date'] is Timestamp ? eventDoc['date'].toDate().toString().split(' ')[0] : eventDoc['date'].toString().split(' ')[0]) : '',
    );
    final locationController = TextEditingController(text: isEdit ? eventDoc['location'] : '');
    final maxParticipantsController = TextEditingController(
      text: isEdit && (eventDoc.data() != null && (eventDoc.data() as Map<String, dynamic>).containsKey('maxParticipants')) ? eventDoc['maxParticipants'].toString() : '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Event' : 'Create Event'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Event Title'),
              ),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dateController.text.isNotEmpty ? DateTime.tryParse(dateController.text) ?? DateTime.now() : DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      dateController.text = picked.toString().split(' ')[0];
                    });
                  }
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: dateController,
                    decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                  ),
                ),
              ),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              TextField(
                controller: maxParticipantsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max Participants'),
              ),
              if (isEdit)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Current participants: ${(eventDoc['participants'] as List<dynamic>?)?.length ?? 0}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final date = DateTime.tryParse(dateController.text.trim());
              final location = locationController.text.trim();
              final maxParticipants = int.tryParse(maxParticipantsController.text.trim());
              if (title.isEmpty || date == null || location.isEmpty || maxParticipants == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields correctly')),
                );
                return;
              }
              if (isEdit) {
                await eventDoc.reference.update({
                  'title': title,
                  'date': Timestamp.fromDate(date),
                  'location': location,
                  'maxParticipants': maxParticipants,
                });
              } else {
                final uid = _auth.currentUser?.uid;
                await FirebaseFirestore.instance.collection('events').add({
                  'title': title,
                  'date': Timestamp.fromDate(date),
                  'location': location,
                  'participants': <String>[],
                  'maxParticipants': maxParticipants,
                  'timestamp': Timestamp.now(),
                  'createdBy': uid,
                  'ngoId': uid,
                });
              }
              Navigator.pop(context);
            },
            child: Text(isEdit ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEvent(DocumentReference eventRef) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await eventRef.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event deleted')));
      }
    }
  }

  Future<void> _sendNotificationToParticipants(
    DocumentReference eventRef,
    List<dynamic> participants,
  ) async {
    final TextEditingController messageController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Notification'),
        content: TextField(
          controller: messageController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Enter notification message'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Send')),
        ],
      ),
    );
    if (result == true && messageController.text.trim().isNotEmpty) {
      final message = messageController.text.trim();
      for (var uid in participants) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'toUser': uid,
          'eventRef': eventRef,
          'message': message,
          'timestamp': Timestamp.now(),
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification sent')));
      }
    }
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
              final date = (data['date'] is Timestamp) ? (data['date'] as Timestamp).toDate() : DateTime.tryParse(data['date'].toString()) ?? DateTime.now();
              final location = data['location'] ?? 'Unknown';
              final participants = (data['participants'] as List<dynamic>?) ?? [];
              final maxParticipants = data['maxParticipants'] ?? 0;
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ExpansionTile(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      if (participants.length >= maxParticipants && maxParticipants > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Full', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                    ],
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
                            '👥 Participants (${participants.length}${maxParticipants > 0 ? '/$maxParticipants' : ''})',
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
                              ElevatedButton.icon(
                                onPressed: () => _showEventDialog(eventDoc: doc),
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
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
      floatingActionButton: (_userRole == 'ngo' || _userRole == 'admin')
          ? FloatingActionButton(
              onPressed: _showCreateEventDialog,
              child: const Icon(Icons.add),
              tooltip: 'Create Event',
            )
          : null,
    );
  }
}
