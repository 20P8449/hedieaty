import 'package:flutter/material.dart';
import '../controllers/user_controller.dart';
import 'event_list_page.dart';
import 'my_pledged_gifts_page.dart';
import 'package:project/views/signIn.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserController _userController = UserController();
  String userName = "Loading...";
  String profileImageUrl = 'https://via.placeholder.com/150'; // Placeholder image
  String? userId; // Store the user ID
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserProfile();
  }

  // Fetch user data
  Future<void> loadUserProfile() async {
    try {
      final firebaseId = await _userController.getCurrentUserId();
      final name = await _userController.getUserName(firebaseId);
      final imageUrl = await _userController.getUserProfileImage(firebaseId); // Assume this method fetches the profile image URL
      setState(() {
        userName = name;
        profileImageUrl = imageUrl ?? 'https://via.placeholder.com/150'; // Fallback to placeholder
        userId = firebaseId; // Set user ID
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        userName = "Error loading profile";
        isLoading = false;
      });
    }
  }

  // Logout functionality
  void logoutUser() async {
    try {
      await _userController.logout();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignInPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error logging out: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit profile page (to be implemented)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Edit Profile feature coming soon!")),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(profileImageUrl),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                userName,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.event, color: Colors.blue),
              title: Text('My Events'),
              subtitle: Text('View and manage your created events'),
              onTap: () {
                if (userId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventListPage(
                        userId: userId!,
                        currentUserId: userId!, // Pass currentUserId
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("User ID not available")),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.favorite, color: Colors.blue),
              title: Text('My Pledged Gifts'),
              subtitle: Text('View and manage your pledged gifts'),
              onTap: () {
                if (userId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyPledgedGiftsPage(userId: userId!),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("User ID not available")),
                  );
                }
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.settings, color: Colors.grey),
              title: Text('Settings'),
              subtitle: Text('Manage your account settings'),
              onTap: () {
                // Navigate to settings page (to be implemented)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Settings feature coming soon!")),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Logout'),
              onTap: () {
                logoutUser();
              },
            ),
          ],
        ),
      ),
    );
  }
}
