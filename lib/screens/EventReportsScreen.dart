import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
                  MaterialPageRoute(builder: (_) => ReportDetailScreen(eventId: eventId, eventTitle: data['title'] ?? 'Event')),
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

  const ReportDetailScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

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
                  'author': 'NGO Admin', // You can fetch actual name from auth if needed
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
                      title: Text(
                        content.length > 100 ? '${content.substring(0, 100)}...' : content,
                      ),
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
