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
  String? _volunteerName;

  @override
  void initState() {
    super.initState();
    _loadVolunteerName();
  }

  Future<void> _loadVolunteerName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('volunteers').doc(uid).get();
      setState(() {
        _volunteerName = doc.data()?['name'] ?? 'Volunteer';
      });
    } else {
      setState(() {
        _volunteerName = 'Volunteer';
      });
    }
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
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${_volunteerName ?? 'Volunteer'}'),
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
                return ListView.builder(
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final doc = filteredEvents[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final eventDate = data['date'] is Timestamp
                        ? (data['date'] as Timestamp).toDate()
                        : DateTime.tryParse(data['date']?.toString() ?? '');
                    return Card(
                      child: ListTile(
                        title: Text(data['title'] ?? ''),
                        subtitle: Text('Date: ${eventDate != null ? eventDate.toLocal().toString().split(' ')[0] : ''}'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventDetailScreen(eventData: data),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: feedbackController,
                  decoration: const InputDecoration(
                    labelText: 'Send Feedback',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _submitFeedback,
                  child: const Text('Submit Feedback'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
