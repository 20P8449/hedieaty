import 'package:flutter/material.dart';
import '../controllers/user_controller.dart';
import 'event_list_page.dart';
import 'my_pledged_gifts_page.dart';
import 'package:project/views/signIn.dart';
import 'package:firebase_auth/firebase_auth.dart'; // To get the current user ID
import 'package:project/services/notification_service.dart';



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
  String userEmail = "Loading...";
  String userPhone = "Loading...";
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

    NotificationService().initialize(FirebaseAuth.instance.currentUser!.uid, context);
  }

  @override
  void dispose() {
    _animationController.dispose();
    NotificationService().dispose();
    super.dispose();
  }

  Future<void> loadUserProfile() async {
    try {
      final firebaseId = await _userController.getCurrentUserId();
      final name = await _userController.getUserName(firebaseId);
      final imageUrl = await _userController.getUserProfileImage(firebaseId);
      final email = await _userController.getUserEmail(firebaseId);
      final phone = await _userController.getUserPhone(firebaseId);
      setState(() {
        userName = name;
        profileImageUrl = imageUrl ?? 'https://via.placeholder.com/150';
        userId = firebaseId;
        userEmail = email ?? "Unknown";
        userPhone = phone ?? "Unknown";
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
          pageBuilder: (context, animation, secondaryAnimation) => SignInPage(),
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

  void showEditProfileDialog() {
    final TextEditingController emailController =
    TextEditingController(text: userEmail);
    final TextEditingController phoneController =
    TextEditingController(text: userPhone);
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController nameController =
    TextEditingController(text: userName);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Text(
            "Edit Profile",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Username",
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: "Phone",
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  await _userController.updateUserProfile(
                    userId!,
                    email: emailController.text.trim(),
                    phone: phoneController.text.trim(),
                    password: passwordController.text.trim(),
                    username: nameController.text.trim(),
                  );
                  setState(() {
                    userEmail = emailController.text.trim();
                    userPhone = phoneController.text.trim();
                    userName = nameController.text.trim();
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Profile updated successfully!")),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error updating profile: $e")),
                  );
                }
              },
              child: Text("Save"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isLoading = true;
              });
              loadUserProfile();
            },
          ),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              if (userId != null) {
                showEditProfileDialog();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("User ID not available")),
                );
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : FadeTransition(
        opacity: _animationController,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(profileImageUrl),
              ),
              SizedBox(height: 20),
              Text(
                userName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(Icons.email, color: Colors.blue),
                  title: Text('Email'),
                  subtitle: Text(userEmail),
                ),
              ),
              Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(Icons.phone, color: Colors.green),
                  title: Text('Phone'),
                  subtitle: Text(userPhone),
                ),
              ),
              Divider(),
              Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(Icons.event, color: Colors.purple),
                  title: Text('My Events'),
                  onTap: () {
                    if (userId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventListPage(
                            userId: userId!,
                            currentUserId: userId!,
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
              ),
              Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(Icons.favorite, color: Colors.red),
                  title: Text('My Pledged Gifts'),
                  onTap: () {
                    if (userId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MyPledgedGiftsPage(userId: userId!),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("User ID not available")),
                      );
                    }
                  },
                ),
              ),
              Divider(),
              Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Logout'),
                  onTap: logoutUser,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}