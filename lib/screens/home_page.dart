import 'package:flutter/material.dart';
import 'event_list_page.dart';
import 'package:project/services/friend_service.dart'; // Service to fetch friends from Firestore
import 'package:firebase_auth/firebase_auth.dart'; // To get the current user ID

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> friends = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFriends();
  }

  Future<void> fetchFriends() async {
    try {
      // Get the current user ID
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      if (currentUserId == null) {
        throw Exception("User not authenticated.");
      }

      // Fetch friends from Firestore via FriendService
      final fetchedFriends =
      await FriendService.getFriendsFromFirestore(currentUserId);
      setState(() {
        friends = fetchedFriends;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching friends: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

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
                delegate: FriendSearchDelegate(),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : friends.isEmpty
          ? Center(child: Text("No friends found"))
          : ListView.builder(
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friend = friends[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(friend['name']),
              subtitle: Text(friend['mobile']),
              onTap: () {
                // Navigate to friend's event list with userId
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventListPage(
                      userId: friend['id'], // Pass userId
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class FriendSearchDelegate extends SearchDelegate {
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
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: FriendService.searchUsersByMobile(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("No results found"));
        }

        final results = snapshot.data!;
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final user = results[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(user['name']),
                subtitle: Text(user['mobile']),
                trailing: ElevatedButton(
                  onPressed: () async {
                    // Add friend functionality
                    try {
                      final currentUserId =
                          FirebaseAuth.instance.currentUser?.uid;

                      if (currentUserId == null) {
                        throw Exception("User not authenticated.");
                      }

                      await FriendService.addFriend(
                        currentUserId,
                        user['id'],
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                          Text("${user['name']} has been added as a friend"),
                        ),
                      );
                    } catch (e) {
                      print("Error adding friend: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to add friend")),
                      );
                    }
                  },
                  child: Text("Add Friend"),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Center(child: Text("Search by name or mobile number"));
  }
}
