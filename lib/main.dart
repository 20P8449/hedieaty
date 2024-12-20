import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added to fetch current user ID
import 'package:project/screens/home_page.dart';
import 'package:project/screens/event_list_page.dart';
import 'package:project/screens/gift_list_page.dart';
import 'package:project/screens/my_pledged_gifts_page.dart';
import 'package:project/screens/profile_page.dart';
import 'package:project/views/signIn.dart';
import 'package:project/views/signUp.dart';
import '../controllers/friend_controller.dart'; // Import FriendsController
import '../models/friend_model.dart';

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
  final FriendController _friendController = FriendController(); // Friends controller instance
  List<String> _friendsNotifications = []; // Notifications for friends
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadFriendsNotifications(); // Load friends' notifications dynamically
  }

  // Fetch notifications from friends
  Future<void> _loadFriendsNotifications() async {
    if (currentUserId == null) return; // If user is not authenticated, skip
    List<FriendModel> friends = await _friendController.getFriends(currentUserId!);
    setState(() {
      _friendsNotifications = friends
          .map((friend) => "Your friend ${friend.friendId} added new events or gifts.")
          .toList();
    });
  }

  // Custom navigation with animations
  void _navigateToPage(BuildContext context, Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }

  // List of pages for navigation
  late final List<Widget> _pages = [
    HomePage(),
    if (currentUserId != null)
      EventListPage(
        userId: currentUserId!,
        currentUserId: currentUserId!, // Pass currentUserId
      )
    else
      Center(child: Text("User not authenticated")),
    if (currentUserId != null)
      GiftListPage(
        selectedEventId: '', // Empty string as default Event ID
        selectedEventName: 'All Gifts', // Default title for the page
        userId: currentUserId!, // Pass userId to GiftListPage
        currentUserId: currentUserId!, // Pass currentUserId
      )
    else
      Center(child: Text("User not authenticated")),
    ProfilePage(),
    if (currentUserId != null)
      MyPledgedGiftsPage(userId: currentUserId!) // Pass userId to MyPledgedGiftsPage
    else
      Center(child: Text("User not authenticated")),
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
          title: Text('Friend Notifications'),
          content: Container(
            width: double.minPositive,
            child: _friendsNotifications.isEmpty
                ? Text('No notifications from friends yet.')
                : ListView.builder(
              shrinkWrap: true,
              itemCount: _friendsNotifications.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_friendsNotifications[index]),
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
