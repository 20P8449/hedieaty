import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/event_controller.dart'; // Correctly importing the EventController
import '../services/friend_service.dart'; // Service to fetch friends from Firestore
import '../services/notification_service.dart'; // Ensure NotificationService exists
import '../controllers/friend_controller.dart'; // Ensure FriendController exists
import '../controllers/user_controller.dart'; // Ensure UserController exists
import '../screens/event_list_page.dart'; // Correct import of EventListPage

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> friends = [];
  bool isLoading = true;
  late EventController _eventController; // Correctly initializing EventController
  final FriendController _friendController = FriendController(); // Initialize FriendController
  final UserController _userController = UserController(); // Initialize UserController
  Map<String, int> upcomingEventsCount = {}; // Store upcoming events count for each friend

  @override
  void initState() {
    super.initState();
    _eventController = EventController(); // Initialize EventController instance
    fetchFriends();

    // Initialize NotificationService
    NotificationService().initialize(FirebaseAuth.instance.currentUser!.uid, context);
  }

  @override
  void dispose() {
    // Dispose NotificationService
    NotificationService().dispose();
    super.dispose();
  }

  Future<void> fetchFriends() async {
    try {
      // Get the current user ID
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      if (currentUserId == null) {
        throw Exception("User not authenticated.");
      }

      // Fetch friends from Firestore via FriendService
      final fetchedFriends = await FriendService.getFriendsFromFirestore(currentUserId);

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

  Future<void> addFriend(String friendUid, String friendName) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("User is not authenticated.");
      }

      // Add friend logic
      await _friendController.addFriendToFirestore(currentUser.uid, friendUid);
      await _friendController.addFriendToFirestore(friendUid, currentUser.uid);
      await _friendController.addFriendToSQLite(currentUser.uid, friendUid);
      await _userController.addNotification(
        friendUid,
        '${currentUser.displayName ?? "Someone"} added you as a friend!',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Friend $friendName added successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding friend: $e")),
      );
    }
  }

  Future<void> removeFriend(String friendId) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      if (currentUserId == null) {
        throw Exception("User not authenticated.");
      }

      await FriendService.removeFriend(currentUserId, friendId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Friend removed successfully.")),
      );
      await fetchFriends(); // Refresh the friend list
    } catch (e) {
      print("Error removing friend: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to remove friend.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hedeiaty'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              setState(() {
                isLoading = true;
              });
              await fetchFriends();
            },
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: FriendSearchDelegate(
                  onAddFriend: (friendUid, friendName) =>
                      addFriend(friendUid, friendName),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventListPage(
                      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                      currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
                    ),
                  ),
                );
              },
              icon: Icon(Icons.add),
              label: Text("Create Your Own Event/List"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ),
          Expanded(
            child: isLoading
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
                  elevation: 4,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      friend['name'],
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      "${friend['mobile']}\nUpcoming Events: $upcomingCount", // Display count
                      style: TextStyle(fontSize: 14),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => removeFriend(friend['id']),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent),
                      child: Text(
                        "Remove Friend",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    onTap: () {
                      // Navigate to friend's event list with userId
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventListPage(
                            userId: friend['id'], // Pass userId
                            currentUserId:
                            FirebaseAuth.instance.currentUser?.uid ?? '',
                          ),
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
  final Function(String friendUid, String friendName) onAddFriend;

  FriendSearchDelegate({required this.onAddFriend});

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
                  onPressed: () => onAddFriend(user['id'], user['name']),
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
