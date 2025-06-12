// ignore_for_file: sort_child_properties_last, unnecessary_to_list_in_spreads

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:localloop/auth/login_screen.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

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

      // Load dashboard stats

      setState(() {
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

  Future<int> _getUserCount() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    return snapshot.docs.length;
  }

  Future<int> _getEventCount() async {
    final snapshot = await FirebaseFirestore.instance.collection('events').get();
    return snapshot.docs.length;
  }

  Future<int> _getTotalParticipantsCount() async {
    final snapshot = await FirebaseFirestore.instance.collection('events').get();
    int totalParticipants = 0;
    for (var doc in snapshot.docs) {
      final participants = doc['participants'] as List<dynamic>? ?? [];
      totalParticipants += participants.length;
    }
    return totalParticipants;
  }

  Future<int> _getRegisteredUserCount() async {
    // Alias for _getUserCount for PopupMenuButton
    return _getUserCount();
  }

  void _showParticipantList(List<dynamic> participants) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Participant List'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: participants.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(participants[index]),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _exportEventsToPDF(List<QueryDocumentSnapshot> docs) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd');
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('Event Report', style: pw.TextStyle(fontSize: 24)),
          pw.SizedBox(height: 20),
          ...docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Title:  ${data['title']}'),
                pw.Text('Date:  ${dateFormat.format((data['date'] as Timestamp).toDate())}'),
                pw.Text('Location:  ${data['location']}'),
                pw.Text('Max Participants:  ${data['maxParticipants']}'),
                pw.Text('Current Participants: ${(data['participants'] as List?)?.length ?? 0}'),
                pw.Divider(),
              ],
            );
          }).toList(),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  void _showAnalyticsSummary(List<QueryDocumentSnapshot> docs) {
    int totalEvents = docs.length;
    int totalParticipants = 0;
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final participants = data['participants'] as List?;
      totalParticipants += participants?.length ?? 0;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Analytics Summary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total Events: $totalEvents'),
            Text('Total Participants: $totalParticipants'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showFeedbackList(DocumentReference eventRef) async {
    final snapshot = await eventRef.collection('feedback').orderBy('timestamp', descending: true).get();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Event Feedback'),
        content: SizedBox(
          width: double.maxFinite,
          child: snapshot.docs.isEmpty
              ? const Text("No feedback yet.")
              : ListView(
                  shrinkWrap: true,
                  children: snapshot.docs.map((doc) {
                    final data = doc.data();
                    final timestamp = (data['timestamp'] as Timestamp).toDate();
                    return ListTile(
                      leading: const Icon(Icons.comment),
                      title: Text(data['feedback'] ?? ''),
                      subtitle: Text(DateFormat.yMMMd().add_jm().format(timestamp)),
                    );
                  }).toList(),
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
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
          PopupMenuButton<String>(
            onSelected: (value) async {
              final docs = await FirebaseFirestore.instance.collection('events').get();
              switch (value) {
                case 'users':
                  final count = await _getRegisteredUserCount();
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Total Users Registered'),
                      content: Text('$count users have registered.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                      ],
                    ),
                  );
                  break;
                case 'export':
                  _exportEventsToPDF(docs.docs);
                  break;
                case 'analytics':
                  _showAnalyticsSummary(docs.docs);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'users', child: Text('Show User Count')),
              const PopupMenuItem(value: 'export', child: Text('Export Events to PDF')),
              const PopupMenuItem(value: 'analytics', child: Text('View Analytics')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          FutureBuilder<List<int>>(
            future: Future.wait([
              _getUserCount(),
              _getEventCount(),
              _getTotalParticipantsCount(),
            ]),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: LinearProgressIndicator(),
                );
              }
              final counts = snapshot.data!;
              return Card(
                margin: const EdgeInsets.all(16),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Text('Users', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${counts[0]}'),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Events', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${counts[1]}'),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Participants', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${counts[2]}'),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                                    ElevatedButton.icon(
                                      onPressed: () => _showParticipantList(participants),
                                      icon: const Icon(Icons.people),
                                      label: const Text('Participants'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.feedback),
                                      tooltip: "View Feedback",
                                      onPressed: () => _showFeedbackList(doc.reference),
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
          ),
        ],
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
