import 'package:flutter/material.dart';

class FriendsPledgedGiftsPage extends StatelessWidget {
  final List<Map<String, dynamic>> pledgedGifts = [
    {'name': 'Headphones', 'friend': 'John Doe', 'status': 'Pledged'},
    {'name': 'Book', 'friend': 'Jane Doe', 'status': 'Pledged'},
    {'name': 'Smartwatch', 'friend': 'Emily Smith', 'status': 'Pledged'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Friends’ Pledged Gifts')),
      body: ListView.builder(
        itemCount: pledgedGifts.length,
        itemBuilder: (context, index) {
          final gift = pledgedGifts[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(Icons.card_giftcard, color: Colors.blue),
              title: Text(gift['name']),
              subtitle: Text('Friend: ${gift['friend']}'),
              trailing: Text(
                gift['status'],
                style: TextStyle(
                  color: gift['status'] == 'Pledged' ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
