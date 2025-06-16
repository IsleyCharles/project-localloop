import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(const MaterialApp(home: NgoDashboardMain()));
}

class NgoDashboardMain extends StatefulWidget {
  const NgoDashboardMain({super.key});

  @override
  State<NgoDashboardMain> createState() => _NgoDashboardMainState();
}

class _NgoDashboardMainState extends State<NgoDashboardMain> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    VolunteerOpportunitiesScreen(),
    AttendanceTrackingScreen(),
    EventReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.group_add), label: "Opportunities"),
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: "Attendance"),
          BottomNavigationBarItem(icon: Icon(Icons.report), label: "Reports"),
        ],
      ),
    );
  }
}

// Volunteer Opportunities (Simple placeholder)
class VolunteerOpportunitiesScreen extends StatelessWidget {
  const VolunteerOpportunitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Volunteer Opportunities")),
      body: const Center(child: Text("Opportunity creation and listing goes here.")),
    );
  }
}

// Attendance Screen (from your latest version)
class AttendanceTrackingScreen extends StatelessWidget {
  const AttendanceTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Attendance & Hours")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('events').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final events = snapshot.data!.docs;

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final data = event.data() as Map<String, dynamic>;

              return ListTile(
                title: Text(data['title'] ?? 'Untitled Event'),
                subtitle: const Text("Tap to view attendance"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AttendanceDetailScreen(eventId: event.id)),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class AttendanceDetailScreen extends StatelessWidget {
  final String eventId;

  const AttendanceDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final attendeesRef = FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .collection('attendance');

    return Scaffold(
      appBar: AppBar(title: const Text("Attendance Details")),
      body: StreamBuilder<QuerySnapshot>(
        stream: attendeesRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();

          final attendees = snapshot.data!.docs;

          return ListView.builder(
            itemCount: attendees.length,
            itemBuilder: (context, index) {
              final attendee = attendees[index];
              final data = attendee.data() as Map<String, dynamic>;
              final hours = data['hours'] ?? 0;

              return ListTile(
                title: Text(data['name'] ?? ''),
                subtitle: Text('Hours: $hours'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final controller = TextEditingController(text: hours.toString());
                    final result = await showDialog<String>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Update Hours"),
                        content: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "Hours Served"),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                          TextButton(
                            onPressed: () => Navigator.pop(context, controller.text),
                            child: const Text("Save"),
                          ),
                        ],
                      ),
                    );

                    if (result != null) {
                      final parsed = int.tryParse(result);
                      if (parsed != null) {
                        await attendee.reference.update({'hours': parsed});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("${data['name']}'s hours updated to $parsed")),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invalid input. Please enter a number.')),
                        );
                      }
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Event Reports Screen (enhanced version)
class EventReportsScreen extends StatelessWidget {
  const EventReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post Event Reports")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('events').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final events = snapshot.data!.docs;

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final data = events[index].data() as Map<String, dynamic>;
              final eventId = events[index].id;

              return ListTile(
                title: Text(data['title'] ?? 'Untitled Event'),
                subtitle: const Text("Tap to add/view reports"),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportDetailScreen(eventId: eventId, eventTitle: data['title'] ?? 'Event'),
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

class ReportDetailScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const ReportDetailScreen({super.key, required this.eventId, required this.eventTitle});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final TextEditingController reportController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final reportRef = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .collection('reports');

    return Scaffold(
      appBar: AppBar(title: Text("${widget.eventTitle} Reports")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: reportController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Write your report...",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = reportController.text.trim();
              if (text.isNotEmpty) {
                await reportRef.add({
                  'content': text,
                  'timestamp': Timestamp.now(),
                  'author': 'NGO Admin',
                });
                reportController.clear();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report submitted successfully')),
                );
              }
            },
            child: const Text("Submit Report"),
          ),
          const Divider(height: 30),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Previous Reports", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: reportRef.orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final reports = snapshot.data!.docs;

                if (reports.isEmpty) {
                  return const Center(child: Text("No reports submitted yet."));
                }

                return ListView.builder(
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final data = reports[index].data() as Map<String, dynamic>;
                    final content = data['content'] ?? '';
                    final author = data['author'] ?? 'Unknown';
                    final timestamp = (data['timestamp'] as Timestamp).toDate();

                    return ListTile(
                      title: Text(content.length > 100 ? '${content.substring(0, 100)}...' : content),
                      subtitle: Text("By $author on ${timestamp.toLocal()}"),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
