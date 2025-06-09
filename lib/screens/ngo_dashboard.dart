// ignore_for_file: prefer_interpolation_to_compose_strings, curly_braces_in_flow_control_structures

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NgoDashboardScreen extends StatefulWidget {
  const NgoDashboardScreen({super.key});

  @override
  State<NgoDashboardScreen> createState() => _NgoDashboardScreenState();
}

class _NgoDashboardScreenState extends State<NgoDashboardScreen> {
  final _auth = FirebaseAuth.instance;
  String? _ngoUid;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      _ngoUid = user.uid;
      debugPrint("NGO UID: $_ngoUid");
    } else {
      debugPrint("No user is logged in");
    }
  }

  void _deleteEvent(DocumentReference eventRef) async {
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event deleted')));
    }
  }

  void _postEventReport(DocumentReference eventRef) {
    final reportController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Post Event Report'),
        content: TextField(
          controller: reportController,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Enter report or update...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (reportController.text.trim().isNotEmpty) {
                await eventRef.update({
                  'report': reportController.text.trim(),
                  'reportTimestamp': Timestamp.now(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report posted')));
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  void _editEvent(DocumentReference eventRef, Map<String, dynamic> eventData) {
    final titleController = TextEditingController(text: eventData['title']);
    final locationController = TextEditingController(text: eventData['location']);
    DateTime selectedDate = (eventData['date'] as Timestamp?)?.toDate() ?? DateTime.now();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location')),
              const SizedBox(height: 12),
              Text('Date: ${DateFormat.yMMMd().format(selectedDate)}'),
              TextButton(
                child: const Text('Change Date'),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await eventRef.update({
                  'title': titleController.text.trim(),
                  'location': locationController.text.trim(),
                  'date': Timestamp.fromDate(selectedDate),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event updated')));
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateEventDialog() {
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    final maxParticipantsController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location')),
                TextField(
                  controller: maxParticipantsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Max Participants'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(selectedDate == null
                          ? 'No date chosen'
                          : 'Date: ${DateFormat.yMMMd().format(selectedDate!)}'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                      child: const Text('Select Date'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final location = locationController.text.trim();
                final maxParticipants = int.tryParse(maxParticipantsController.text.trim());

                if (title.isEmpty || location.isEmpty || selectedDate == null || maxParticipants == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All fields are required.')),
                  );
                  return;
                }

                await FirebaseFirestore.instance.collection('events').add({
                  'title': title,
                  'location': location,
                  'date': Timestamp.fromDate(selectedDate!),
                  'ngoId': _ngoUid,
                  'createdBy': _ngoUid,
                  'participants': <String>[],
                  'attendance': <String, bool>{},
                  'report': '',
                  'maxParticipants': maxParticipants,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event created.')));
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_ngoUid == null) {
      return const Scaffold(
        body: Center(child: Text('User not authenticated')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('NGO Dashboard'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .where('ngoId', isEqualTo: _ngoUid)
            .orderBy('date')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No events yet.'));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title']?.toString() ?? 'Untitled';
              final location = data['location']?.toString() ?? 'Unknown';
              final Timestamp? dateTs = data['date'] as Timestamp?;
              final DateTime date = dateTs?.toDate() ?? DateTime.now();
              final List<dynamic> participants = data['participants'] as List<dynamic>? ?? [];
              final String report = data['report']?.toString() ?? '';

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(title),
                  subtitle: Text(
                    'Location: $location\nDate: ${DateFormat.yMMMd().format(date)}\nParticipants: ${participants.length}' +
                        (report.isNotEmpty ? '\nReport: $report' : ''),
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editEvent(doc.reference, data);
                      } else if (value == 'delete') {
                        _deleteEvent(doc.reference);
                      } else if (value == 'report') {
                        _postEventReport(doc.reference);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      const PopupMenuItem(value: 'report', child: Text('Post Report')),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateEventDialog,
        child: const Icon(Icons.add),
        tooltip: 'Create Event',
      ),
    );
  }
}
