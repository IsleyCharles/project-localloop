import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:localloop/screens/ManageOpportunitiesScreen.dart';
import 'package:localloop/screens/VolunteerProfilesScreen.dart';
import 'package:localloop/screens/manage_event_screen.dart';

class NgoDashboardScreen extends StatefulWidget {
  const NgoDashboardScreen({super.key});

  @override
  State<NgoDashboardScreen> createState() => _NgoDashboardScreenState();
}

class _NgoDashboardScreenState extends State<NgoDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      // Add your logout logic here, e.g. FirebaseAuth.instance.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NGO Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle('1. Volunteer Opportunities'),
          _buildVolunteerOpportunities(),
          _buildSectionTitle('2. Volunteer Profiles & Roles'),
          _buildVolunteerProfiles(),
          _buildVolunteerProfilesButton(),
          _buildSectionTitle('3. Attendance & Hours Tracking'),
          _buildAttendanceTracker(),
          _buildSectionTitle('4. Post Event Reports & Updates'),
          _buildEventReports(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget _buildVolunteerOpportunities() {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ManageOpportunitiesScreen(),
          ),
        );
      },
      icon: const Icon(Icons.add),
      label: const Text('Create Opportunity'),
    );
  }

  Widget _buildVolunteerProfiles() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('volunteers').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final volunteers = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: volunteers.length,
          itemBuilder: (context, index) {
            final data = volunteers[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text(data['name'] ?? 'No Name'),
                subtitle: Text('${data['email'] ?? ''}\nRole: ${data['role'] ?? 'Unassigned'}\nHours: ${data['totalHours'] ?? 0}'),
                isThreeLine: true,
                trailing: DropdownButton<String>(
                  value: data['role'] ?? 'Unassigned',
                  items: ['Unassigned', 'Organizer', 'Helper', 'Photographer']
                      .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                      .toList(),
                  onChanged: (newRole) {
                    _firestore.collection('volunteers').doc(volunteers[index].id).update({'role': newRole});
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVolunteerProfilesButton() {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VolunteerProfilesScreen(),
          ),
        );
      },
      icon: const Icon(Icons.people),
      label: const Text('View Volunteer Profiles'),
    );
  }

  Widget _buildAttendanceTracker() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('events').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final events = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return ListTile(
              title: Text(event['title'] ?? ''),
              subtitle: Text('Date: ${(event['date'] as Timestamp).toDate()}'),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ManageEventScreen(eventDoc: event),
                    ),
                  );
                },
                child: const Text('Manage Event'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEventReports() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            _showReportDialog();
          },
          icon: const Icon(Icons.post_add),
          label: const Text('Post Report'),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('eventReports').orderBy('timestamp', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            final reports = snapshot.data!.docs;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final data = reports[index].data() as Map<String, dynamic>;
                return Card(
                  child: ListTile(
                    title: Text(data['title'] ?? ''),
                    subtitle: Text(data['summary'] ?? ''),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _showReportDialog() {
    final titleController = TextEditingController();
    final summaryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Post Event Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: summaryController, decoration: const InputDecoration(labelText: 'Summary')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final summary = summaryController.text.trim();
              if (title.isNotEmpty && summary.isNotEmpty) {
                await _firestore.collection('eventReports').add({
                  'title': title,
                  'summary': summary,
                  'timestamp': Timestamp.now(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }
}
