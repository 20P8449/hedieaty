import 'package:flutter/material.dart';
// Optional: Import Firebase if pulling user data from a database.

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Information Section
            ListTile(
              title: Text('User Information'),
              subtitle: Text('Edit personal information here'),
              onTap: () {
                // Navigate to Edit Personal Information page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfilePage(),
                  ),
                );
              },
            ),
            // Notification Settings Section
            ListTile(
              title: Text('Notification Settings'),
              subtitle: Text('Manage your notification preferences'),
              onTap: () {
                // Navigate to Notification Settings page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationSettingsPage(),
                  ),
                );
              },
            ),
            Divider(), // Divider for separation
            // My Events Section
            ListTile(
              title: Text('My Events'),
              subtitle: Text('View and manage your created events'),
              onTap: () {
                // Navigate to Event List Page
              },
            ),
            // My Gift Lists Section
            ListTile(
              title: Text('My Gift Lists'),
              subtitle: Text('View your associated gifts'),
              onTap: () {
                // Navigate to Gift List Page
              },
            ),
            // My Pledged Gifts Section
            ListTile(
              title: Text('My Pledged Gifts'),
              subtitle: Text('View and manage your pledged gifts'),
              onTap: () {
                // Navigate to My Pledged Gifts Page
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Dummy Edit Profile Page
class EditProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Profile')),
      body: Center(child: Text('Edit your personal information here.')),
    );
  }
}

// Notification Settings Page with Switch for Notifications
class NotificationSettingsPage extends StatefulWidget {
  @override
  _NotificationSettingsPageState createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _notificationsEnabled = true; // Default state for notifications

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notification Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Enable Notifications'),
                Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value; // Update the state
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Notification Preferences',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            // Add more notification options here if needed
          ],
        ),
      ),
    );
  }
}