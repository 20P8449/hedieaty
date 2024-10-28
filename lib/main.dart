import 'package:flutter/material.dart';
import 'package:project/EventListPage.dart';
import 'package:project/GiftListPage.dart';
import 'package:project/MyPledgedGiftsPage.dart';
import 'package:project/ProfilePage.dart';

void main() {
  runApp(HedeiatyApp());
}

class HedeiatyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hedeiaty',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  // List of pages for navigation
  final List<Widget> _pages = [
    HomePage(),
    EventListPage(),
    GiftListPage(),
    ProfilePage(),
    MyPledgedGiftsPage(),
  ];

  // Sample notifications list
  final List<String> _notifications = [
    "You have a new event invitation.",
    "Cristiano sent you a gift.",
    "Bellingham liked your event."
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Notifications'),
          content: Container(
            width: double.minPositive, // Set the width of the dialog
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_notifications[index]),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _pages[_selectedIndex], // Main content
          Positioned(
            right: 20,
            bottom: 70, // Adjust this value to position it above the nav bar
            child: GestureDetector(
              onTap: () => _showNotifications(context),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue, // Set the background color to blue
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0), // Adjust padding as needed
                  child: Icon(
                    Icons.notifications,
                    color: Colors.white, // Icon color
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Ensures labels are always visible
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Gifts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Pledged Gifts',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final List<Map<String, dynamic>> friends = [
    {
      'name': 'Cristiano',
      'profilePic': 'https://e1.pxfuel.com/desktop-wallpaper/755/738/desktop-wallpaper-cristiano-ronaldo-dos-santos-aveiro-in-a-sacoor-brothers-blue-suit-ronaldo-suit.jpg',
      'upcomingEvents': 1,
    },
    {
      'name': 'Bellingham',
      'profilePic': 'https://beninwebtv.com/wp-content/uploads/2023/10/Bellingham.webp',
      'upcomingEvents': 0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hedeiaty'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: FriendSearchDelegate(friends),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to Create Event/List Page
              },
              icon: Icon(Icons.add),
              label: Text('Create Your Own Event/List'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friend = friends[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(friend['profilePic']),
                  ),
                  title: Text(friend['name']),
                  subtitle: Text(friend['upcomingEvents'] > 0
                      ? 'Upcoming Events: ${friend['upcomingEvents']}'
                      : 'No Upcoming Events'),
                  onTap: () {
                    // Navigate to friend's gift list
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

class FriendSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> friends;

  FriendSearchDelegate(this.friends);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = friends
        .where((friend) => friend['name'].toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final friend = suggestions[index];
        return ListTile(
          title: Text(friend['name']),
          onTap: () {
            // Navigate to selected friend's gift list
          },
        );
      },
    );
  }
}

class GiftDetailsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gift Details')),
      body: Center(child: Text('Gift Details Page')),
    );
  }
}
