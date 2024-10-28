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
            ListTile(
              title: Text('User Information'),
              subtitle: Text('Edit personal information here'),
              onTap: () {
                // Navigate to Edit Personal Information page
              },
            ),
            ListTile(
              title: Text('Notification Settings'),
              subtitle: Text('Manage your notification preferences'),
              onTap: () {
                // Navigate to Notification Settings page
              },
            ),
            Divider(), // Divider for separation
            ListTile(
              title: Text('My Events'),
              subtitle: Text('View and manage your created events'),
              onTap: () {
                // Navigate to Event List Page
              },
            ),
            ListTile(
              title: Text('My Gift Lists'),
              subtitle: Text('View your associated gifts'),
              onTap: () {
                // Navigate to Gift List Page
              },
            ),
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
