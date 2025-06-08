import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxParticipantsController = TextEditingController();

  void _showEventDialog({DocumentSnapshot? document}) {
    final isEditing = document != null;
    DateTime selectedDate = DateTime.now();

    if (isEditing) {
      _titleController.text = document!['title'];
      _locationController.text = document['location'];
      selectedDate = (document['date'] as Timestamp).toDate();
      _maxParticipantsController.text = document['maxParticipants']?.toString() ?? '50';
    } else {
      _titleController.clear();
      _locationController.clear();
      _maxParticipantsController.text = '50';
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Event' : 'Add Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: _titleController, decoration: InputDecoration(labelText: 'Title')),
                TextField(controller: _locationController, decoration: InputDecoration(labelText: 'Location')),
                TextField(
                  controller: _maxParticipantsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Max Participants'),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Text("Date: "+selectedDate.toLocal().toString().split(' ')[0]),
                    Spacer(),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2023),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: Text('Pick Date'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final title = _titleController.text.trim();
                final location = _locationController.text.trim();
                final max = int.tryParse(_maxParticipantsController.text) ?? 50;

                if (title.isEmpty || location.isEmpty) return;

                final eventData = {
                  'title': title,
                  'location': location,
                  'maxParticipants': max,
                  'date': Timestamp.fromDate(selectedDate),
                  'timestamp': Timestamp.now(),
                };

                if (isEditing) {
                  await document.reference.update(eventData);
                } else {
                  await FirebaseFirestore.instance.collection('events').add(eventData);
                }

                Navigator.pop(context);
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteEvent(DocumentReference docRef) async {
    await docRef.delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showEventDialog(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final events = snapshot.data!.docs;
          if (events.isEmpty) return Center(child: Text('No events'));

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final doc = events[index];
              final data = doc.data() as Map<String, dynamic>;

              return ListTile(
                title: Text(data['title'] ?? 'Untitled'),
                subtitle: Text(data['location'] ?? 'Unknown'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _showEventDialog(document: doc),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteEvent(doc.reference),
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
