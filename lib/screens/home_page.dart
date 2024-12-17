import 'package:flutter/material.dart';
import 'event_list_page.dart';

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
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(friend['profilePic']),
                    ),
                    title: Text(friend['name']),
                    subtitle: Text(friend['upcomingEvents'] > 0
                        ? 'Upcoming Events: ${friend['upcomingEvents']}'
                        : 'No Upcoming Events'),
                    onTap: () {
                      // Navigate to friend's event list
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EventListPage(), // Replace with friend's event list
                        ),
                      );
                    },
                  ),
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
            // Navigate to selected friend's event list
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventListPage(),
              ),
            );
          },
        );
      },
    );
  }
}
