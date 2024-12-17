import 'package:flutter/material.dart';
import 'event_list_page.dart';
import 'gift_list_page.dart';
import 'my_pledged_gifts_page.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(
                  'https://via.placeholder.com/150', // Replace with user's profile image URL
                ),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'User Name', // Replace with the actual user's name
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.event, color: Colors.blue),
              title: Text('My Events'),
              subtitle: Text('View and manage your created events'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EventListPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.card_giftcard, color: Colors.blue),
              title: Text('My Gift Lists'),
              subtitle: Text('View and manage your associated gifts'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GiftListPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.favorite, color: Colors.blue),
              title: Text('My Pledged Gifts'),
              subtitle: Text('View and manage your pledged gifts'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyPledgedGiftsPage()),
                );
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.settings, color: Colors.grey),
              title: Text('Settings'),
              subtitle: Text('Manage your account settings'),
              onTap: () {
                // Navigate to settings page
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Logout'),
              onTap: () {
                // Add logout logic here
              },
            ),
          ],
        ),
      ),
    );
  }
}
