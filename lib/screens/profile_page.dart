import 'package:flutter/material.dart';
import '../controllers/user_controller.dart';
import 'event_list_page.dart';
import 'my_pledged_gifts_page.dart';
import 'package:project/views/signIn.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final UserController _userController = UserController();
  String userName = "Loading...";
  String profileImageUrl = 'https://via.placeholder.com/150';
  String? userId;
  bool isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
    loadUserProfile();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> loadUserProfile() async {
    try {
      final firebaseId = await _userController.getCurrentUserId();
      final name = await _userController.getUserName(firebaseId);
      final imageUrl =
      await _userController.getUserProfileImage(firebaseId);
      setState(() {
        userName = name;
        profileImageUrl =
            imageUrl ?? 'https://via.placeholder.com/150';
        userId = firebaseId;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        userName = "Error loading profile";
        isLoading = false;
      });
    }
  }

  void logoutUser() async {
    try {
      await _userController.logout();
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              SignInPage(),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(
                CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(position: offsetAnimation, child: child);
          },
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error logging out: $e")),
      );
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
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
              showSnackBar("Edit Profile feature coming soon!");
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : FadeTransition(
        opacity: _animationController,
        child: Padding(
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.event, color: Colors.blue),
                title: Text('My Events'),
                subtitle:
                Text('View and manage your created events'),
                onTap: () {
                  if (userId != null) {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation,
                            secondaryAnimation) =>
                            EventListPage(
                              userId: userId!,
                              currentUserId: userId!,
                            ),
                        transitionsBuilder: (context, animation,
                            secondaryAnimation, child) {
                          const begin = Offset(1.0, 0.0);
                          const end = Offset.zero;
                          const curve = Curves.easeInOut;

                          var tween = Tween(begin: begin, end: end)
                              .chain(CurveTween(curve: curve));
                          var offsetAnimation =
                          animation.drive(tween);

                          return SlideTransition(
                              position: offsetAnimation, child: child);
                        },
                      ),
                    );
                  } else {
                    showSnackBar("User ID not available");
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.favorite, color: Colors.blue),
                title: Text('My Pledged Gifts'),
                subtitle:
                Text('View and manage your pledged gifts'),
                onTap: () {
                  if (userId != null) {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation,
                            secondaryAnimation) =>
                            MyPledgedGiftsPage(userId: userId!),
                        transitionsBuilder: (context, animation,
                            secondaryAnimation, child) {
                          const begin = Offset(1.0, 0.0);
                          const end = Offset.zero;
                          const curve = Curves.easeInOut;

                          var tween = Tween(begin: begin, end: end)
                              .chain(CurveTween(curve: curve));
                          var offsetAnimation =
                          animation.drive(tween);

                          return SlideTransition(
                              position: offsetAnimation, child: child);
                        },
                      ),
                    );
                  } else {
                    showSnackBar("User ID not available");
                  }
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.settings, color: Colors.grey),
                title: Text('Settings'),
                subtitle:
                Text('Manage your account settings'),
                onTap: () {
                  showSnackBar("Settings feature coming soon!");
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
      ),
    );
  }
}
