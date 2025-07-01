// manage_event_screen.dart
// This screen allows NGO admins to manage event details, update event info, upload attachments, and view participants.
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class ManageEventScreen extends StatefulWidget {
  // The Firestore document for the event being managed
  final DocumentSnapshot eventDoc;
  const ManageEventScreen({super.key, required this.eventDoc});

  @override
  State<ManageEventScreen> createState() => _ManageEventScreenState();
}

class _ManageEventScreenState extends State<ManageEventScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late String eventId;

  @override
  void initState() {
    super.initState();
    // Initialize controllers and event data from Firestore document
    final data = widget.eventDoc.data() as Map<String, dynamic>;
    _titleController = TextEditingController(text: data['title']);
    _descriptionController = TextEditingController(text: data['description']);
    _selectedDate = (data['date'] as Timestamp).toDate();
    eventId = widget.eventDoc.id;
  }

  // Save changes to event details in Firestore
  Future<void> _saveChanges() async {
    await widget.eventDoc.reference.update({
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'date': Timestamp.fromDate(_selectedDate),
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event updated')));
  }

  // Upload a file to Firebase Storage and update event attachments
  Future<void> _uploadFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      final ref = FirebaseStorage.instance.ref('event_attachments/$eventId/$fileName');

      await ref.putFile(file);
      final downloadURL = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('events').doc(eventId).update({
        'attachments': FieldValue.arrayUnion([downloadURL])
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File uploaded')));
    }
  }

  // Build a list of event participants (fetches user info by UID)
  Widget _buildParticipantList() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('events').doc(eventId).get(),
      builder: (context, eventSnapshot) {
        if (!eventSnapshot.hasData) return const CircularProgressIndicator();
        final eventData = eventSnapshot.data!.data() as Map<String, dynamic>?;
        final List<dynamic> participantUids = eventData?['participants'] ?? [];
        if (participantUids.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No participants yet.'),
          );
        }
        return FutureBuilder<List<DocumentSnapshot>>(
          future: Future.wait(
            participantUids.map((uid) =>
              FirebaseFirestore.instance.collection('users').doc(uid).get()
            ),
          ),
          builder: (context, userSnapshots) {
            if (!userSnapshots.hasData) return const CircularProgressIndicator();
            final users = userSnapshots.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text("Participants", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ...users.map((userDoc) {
                  final userData = userDoc.data() as Map<String, dynamic>?;
                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(userData?['name'] ?? userData?['email'] ?? 'Unnamed'),
                    subtitle: Text(userData?['email'] ?? ''),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Event"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Edit Event", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text("Date: "),
                Text("${_selectedDate.toLocal()}".split(' ')[0]),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                )
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save),
              label: const Text("Save Changes"),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _uploadFile,
              icon: const Icon(Icons.attach_file),
              label: const Text("Attach File"),
            ),
            _buildParticipantList(),
          ],
        ),
      ),
    );
  }
}
