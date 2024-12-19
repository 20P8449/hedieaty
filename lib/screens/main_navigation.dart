import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added to fetch current user ID
import 'package:project/screens/home_page.dart'; // Ensure HomePage is correctly imported
import 'package:project/screens/event_list_page.dart';
import 'package:project/screens/my_pledged_gifts_page.dart';
import 'package:project/screens/profile_page.dart';
import 'package:project/views/signIn.dart';
import 'package:project/views/signUp.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
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
      home: SignInPage(), // Redirect to SignInPage as the default screen
      routes: {
        '/home': (context) => MainNavigation(),
        '/signin': (context) => SignInPage(),
        '/signUp': (context) => SignUpPage(),
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  String? currentUserId;

  // Initialize the current user ID
  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
  }

  // List of pages for navigation
  late final List<Widget> _pages = [
    HomePage(), // Fixed: Ensure HomePage is defined or correctly imported
    if (currentUserId != null)
      EventListPage(
        userId: currentUserId!, // Pass userId to EventListPage
        currentUserId: currentUserId!, // Pass currentUserId to EventListPage
      )
    else
      Center(child: Text("User not authenticated")),
    ProfilePage(), // Removed userId as ProfilePage doesn't require it
    if (currentUserId != null)
      MyPledgedGiftsPage(userId: currentUserId!) // Pass userId to MyPledgedGiftsPage
    else
      Center(child: Text("User not authenticated")),
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
            width: double.minPositive,
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
          _pages[_selectedIndex],
          Positioned(
            right: 20,
            bottom: 70,
            child: GestureDetector(
              onTap: () => _showNotifications(context),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Icon(
                    Icons.notifications,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
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
