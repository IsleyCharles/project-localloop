// AttendanceTrackingScreen.dart
// This screen allows NGOs to track attendance and hours for each event, and provides access to event attachments.
// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AttendanceTrackingScreen extends StatefulWidget {
  const AttendanceTrackingScreen({super.key});

  @override
  State<AttendanceTrackingScreen> createState() => _AttendanceTrackingScreenState();
}

class _AttendanceTrackingScreenState extends State<AttendanceTrackingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    // Scaffold with a list of events and attendance actions
    return Scaffold(
      appBar: AppBar(title: const Text("Attendance & Hours Tracking")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('events').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final events = snapshot.data!.docs;

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final eventData = event.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(10),
                child: ExpansionTile(
                  title: Text(eventData['title'] ?? 'No Title'),
                  subtitle: Text('Date: ${(eventData['date'] as Timestamp).toDate()}'),
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _openAttendanceDialog(event.id),
                      icon: const Icon(Icons.how_to_reg),
                      label: const Text("Mark Attendance"),
                    ),
                    if (eventData['attachments'] != null && eventData['attachments'] is List)
                      ...List<Widget>.from(
                        (eventData['attachments'] as List)
                            .map(
                              (url) => ListTile(
                                leading: const Icon(Icons.attach_file),
                                title: Text(url.toString().split('/').last),
                                trailing: IconButton(
                                  icon: const Icon(Icons.open_in_new),
                                  onPressed: () => launchUrl(Uri.parse(url)),
                                ),
                              ),
                            ),
                      ),
                  ], // End of ExpansionTile children
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Opens a dialog to mark attendance for the selected event
  void _openAttendanceDialog(String eventId) async {
    final volunteersSnap = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'volunteer')
        .get();

    final attendanceSnap = await _firestore
        .collection('events')
        .doc(eventId)
        .collection('attendance')
        .get();

    final attendedIds = attendanceSnap.docs.map((e) => e.id).toSet();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Mark Attendance'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: volunteersSnap.docs.length,
              itemBuilder: (context, index) {
                final doc = volunteersSnap.docs[index];
                final data = doc.data();
                final attended = attendedIds.contains(doc.id);

                return CheckboxListTile(
                  title: Text(data['name'] ?? 'Unnamed'),
                  subtitle: Text(data['email'] ?? ''),
                  value: attended,
                  onChanged: (val) async {
                    if (val == true) {
                      await _firestore
                          .collection('events')
                          .doc(eventId)
                          .collection('attendance')
                          .doc(doc.id)
                          .set({
                        'name': data['name'],
                        'email': data['email'],
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                      // Optional: add 1 hour to user's totalHours
                      final userRef = _firestore.collection('users').doc(doc.id);
                      final userSnap = await userRef.get();
                      final hours = (userSnap.data()?['totalHours'] ?? 0) + 1;
                      await userRef.update({'totalHours': hours});
                    } else {
                      await _firestore
                          .collection('events')
                          .doc(eventId)
                          .collection('attendance')
                          .doc(doc.id)
                          .delete();
                    }

                    setState(() {});
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
          ],
        );
      },
    );
  }
}
