import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'event_detail_screen.dart';

// ignore: use_key_in_widget_constructors
class VolunteerDashboardScreen extends StatefulWidget {
  const VolunteerDashboardScreen({super.key});

  @override
  VolunteerDashboardScreenState createState() => VolunteerDashboardScreenState();
}

class VolunteerDashboardScreenState extends State<VolunteerDashboardScreen> {
  String searchTerm = '';
  String filterType = 'upcoming'; // 'upcoming' or 'past'

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, Volunteer'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              // Navigate to login screen
            },
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
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: Text('Upcoming'),
                selected: filterType == 'upcoming',
                onSelected: (_) => setState(() => filterType = 'upcoming'),
              ),
              SizedBox(width: 10),
              ChoiceChip(
                label: Text('Past'),
                selected: filterType == 'past',
                onSelected: (_) => setState(() => filterType = 'past'),
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('events')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No events available."));
                }

                final now = DateTime.now();
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
                  if (filterType == 'upcoming') {
                    return matchesSearch && isUpcoming;
                  } else {
                    return matchesSearch && isPast;
                  }
                }).toList();

                if (filteredEvents.isEmpty) {
                  return Center(child: Text("No matching events found."));
                }

                return ListView.builder(
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final doc = filteredEvents[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final participants = data['participants'] as List<dynamic>? ?? [];
                    final participantCount = participants.length;
                    final eventDate = data['date'] is Timestamp
                        ? (data['date'] as Timestamp).toDate()
                        : DateTime.tryParse(data['date']?.toString() ?? '');
                    bool isToday = eventDate != null && _isSameDay(eventDate, DateTime.now());
                    bool isFull = participantCount >= (data['maxParticipants'] ?? 9999);
                    return ListTile(
                      title: Row(
                        children: [
                          Expanded(child: Text(data['title'] ?? 'No Title')),
                          if (isToday)
                            Container(
                              margin: EdgeInsets.only(left: 6),
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('Today', style: TextStyle(fontSize: 12)),
                            ),
                          if (isFull)
                            Container(
                              margin: EdgeInsets.only(left: 6),
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('Full', style: TextStyle(fontSize: 12)),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['location'] ?? 'No Location'),
                          Text('👥 Participants: $participantCount'),
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
