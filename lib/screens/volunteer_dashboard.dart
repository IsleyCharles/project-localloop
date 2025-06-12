import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'event_detail_screen.dart';

class VolunteerDashboardScreen extends StatefulWidget {
  const VolunteerDashboardScreen({super.key});

  @override
  VolunteerDashboardScreenState createState() => VolunteerDashboardScreenState();
}

class VolunteerDashboardScreenState extends State<VolunteerDashboardScreen> {
  String searchTerm = '';
  String filterType = 'upcoming';
  final TextEditingController feedbackController = TextEditingController();

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _submitFeedback() async {
    final feedback = feedbackController.text.trim();
    if (feedback.isEmpty) return;

    await FirebaseFirestore.instance.collection('feedback').add({
      'userId': FirebaseAuth.instance.currentUser?.uid,
      'message': feedback,
      'timestamp': Timestamp.now(),
    });

    feedbackController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Feedback submitted')),
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Notifications"),
        content: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text("No notifications");
            }
            return SizedBox(
              height: 300,
              width: 300,
              child: ListView(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(data['title'] ?? 'No Title'),
                    subtitle: Text(data['message'] ?? ''),
                  );
                }).toList(),
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome, Volunteer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: _showNotifications,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) => setState(() => searchTerm = value),
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

          // Filter Buttons
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Upcoming'),
                  selected: filterType == 'upcoming',
                  onSelected: (_) => setState(() => filterType = 'upcoming'),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('Past'),
                  selected: filterType == 'past',
                  onSelected: (_) => setState(() => filterType = 'past'),
                ),
              ],
            ),
          ),

          // Event List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('events')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No events available."));
                }

                final filteredEvents = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = data['title']?.toLowerCase() ?? '';
                  final eventDate = data['date'] is Timestamp
                      ? (data['date'] as Timestamp).toDate()
                      : DateTime.tryParse(data['date']?.toString() ?? '');
                  if (eventDate == null) return false;
                  final matchesSearch = title.contains(searchTerm.toLowerCase());
                  final isUpcoming = eventDate.isAfter(now) || _isSameDay(eventDate, now);
                  final isPast = eventDate.isBefore(now) && !_isSameDay(eventDate, now);
                  return filterType == 'upcoming' ? matchesSearch && isUpcoming : matchesSearch && isPast;
                }).toList();

                if (filteredEvents.isEmpty) {
                  return const Center(child: Text("No matching events found."));
                }

                return ListView.builder(
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final doc = filteredEvents[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final participants = data['participants'] as List<dynamic>? ?? [];
                    final eventDate = (data['date'] as Timestamp?)?.toDate();
                    final isToday = eventDate != null && _isSameDay(eventDate, DateTime.now());
                    final isFull = participants.length >= (data['maxParticipants'] ?? 9999);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: ListTile(
                        title: Row(
                          children: [
                            Expanded(child: Text(data['title'] ?? 'No Title')),
                            if (isToday)
                              _tag('Today', Colors.blue),
                            if (isFull)
                              _tag('Full', Colors.red),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['location'] ?? 'No Location'),
                            Text('👥 Participants: ${participants.length}'),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventDetailScreen(
                                eventData: {
                                  ...data,
                                  'docRef': doc.reference,
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Feedback Section
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                const Text('Share your feedback:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: feedbackController,
                  decoration: InputDecoration(
                    hintText: 'Your feedback...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _submitFeedback,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: color)),
    );
  }
}
