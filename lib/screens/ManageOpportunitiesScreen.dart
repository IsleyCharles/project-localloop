import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageOpportunitiesScreen extends StatefulWidget {
  const ManageOpportunitiesScreen({super.key});

  @override
  State<ManageOpportunitiesScreen> createState() => _ManageOpportunitiesScreenState();
}

class _ManageOpportunitiesScreenState extends State<ManageOpportunitiesScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  DateTime? _selectedDate;

  Future<void> _createOpportunity() async {
    if (_titleController.text.isEmpty || _locationController.text.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill all fields')));
      return;
    }

    await FirebaseFirestore.instance.collection('opportunities').add({
      'title': _titleController.text.trim(),
      'location': _locationController.text.trim(),
      'date': Timestamp.fromDate(_selectedDate!),
      'createdAt': Timestamp.now(),
    });

    _titleController.clear();
    _locationController.clear();
    _selectedDate = null;
    Navigator.pop(context);
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Opportunity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            TextButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(_selectedDate == null ? 'Select Date' : _selectedDate!.toLocal().toString().split(' ')[0]),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: _createOpportunity, child: const Text('Create')),
        ],
      ),
    );
  }

  Future<void> _deleteOpportunity(DocumentReference ref) async {
    await ref.delete();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opportunity deleted')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Opportunities')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('opportunities')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No opportunities available'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final ref = docs[index].reference;

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(data['title'] ?? ''),
                  subtitle: Text('📍 ${data['location'] ?? ''}\n🗓️ ${
                    (data['date'] as Timestamp).toDate().toLocal().toString().split(' ')[0]
                  }'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteOpportunity(ref),
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
