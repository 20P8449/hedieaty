import 'package:flutter/material.dart';
import '../controllers/event_controller.dart'; // Correctly importing the EventController
import '../services/friend_service.dart'; // Service to fetch friends from Firestore
import '../screens/event_list_page.dart'; // Correct import of EventListPage
import 'package:firebase_auth/firebase_auth.dart'; // To get the current user ID

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> friends = [];
  bool isLoading = true;
  late EventController _eventController; // Correctly initializing EventController
  Map<String, int> upcomingEventsCount = {}; // Store upcoming events count for each friend

  @override
  void initState() {
    super.initState();
    _eventController = EventController(); // Initialize EventController instance
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

      Map<String, int> tempUpcomingEventsCount = {};

      // Fetch upcoming events count for each friend
      for (var friend in fetchedFriends) {
        final friendId = friend['id'];

        // Fetch upcoming events asynchronously
        final events = await _eventController.getUpcomingEventsByUserId(friendId);
        tempUpcomingEventsCount[friendId] = events.length; // Store count
      }

      setState(() {
        friends = fetchedFriends;
        upcomingEventsCount = tempUpcomingEventsCount; // Update state with counts
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
          final upcomingCount =
              upcomingEventsCount[friend['id']] ?? 0; // Get count
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(friend['name']),
              subtitle: Text(
                "${friend['mobile']}\nUpcoming Events: $upcomingCount", // Display count
                style: TextStyle(fontSize: 14),
              ),
              onTap: () {
                // Navigate to friend's event list with userId
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventListPage(
                      userId: friend['id'], // Pass userId
                      currentUserId:
                      FirebaseAuth.instance.currentUser?.uid ??
                          '',
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
                          content: Text("${user['name']} has been added as a friend"),
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
