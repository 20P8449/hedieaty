import 'package:flutter/material.dart';
import '../controllers/gift_controller.dart';
import '../controllers/event_controller.dart';
import '../controllers/user_controller.dart';
import '../models/gift_model.dart';
import 'package:project/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; // To get the current user ID

class MyPledgedGiftsPage extends StatefulWidget {
  final String userId; // User ID to filter gifts

  MyPledgedGiftsPage({required this.userId});

  @override
  _MyPledgedGiftsPageState createState() => _MyPledgedGiftsPageState();
}

class _MyPledgedGiftsPageState extends State<MyPledgedGiftsPage> {
  final GiftController _giftController = GiftController();
  final EventController _eventController = EventController();
  final UserController _userController = UserController(); // For user details
  List<GiftModel> pledgedGifts = [];
  Map<String, String> eventNames = {}; // Cache for event names
  Map<String, String> userNames = {}; // Cache for user names

  @override
  void initState() {
    super.initState();
    loadPledgedGifts();
    NotificationService().initialize(FirebaseAuth.instance.currentUser!.uid, context);
  }

  @override
  void dispose() {
    // Dispose NotificationService
    NotificationService().dispose();
    super.dispose();
  }

  // Fetch pledged gifts dynamically
  Future<void> loadPledgedGifts() async {
    try {
      final allGifts = await _giftController.getAllGifts(widget.userId); // Fetch all gifts
      final pledgedGiftsList = allGifts
          .where((gift) => gift.status == 'Pledged' || gift.status == 'Purchased')
          .toList();

      // Fetch event names and user names for each pledged gift
      for (var gift in pledgedGiftsList) {
        if (!eventNames.containsKey(gift.eventFirebaseId)) {
          final eventName = await _eventController.getEventNameById(gift.eventFirebaseId);
          if (eventName != null) {
            eventNames[gift.eventFirebaseId] = eventName;
          }
        }
        if (gift.pledgedBy.isNotEmpty && !userNames.containsKey(gift.pledgedBy)) {
          final userName = await _userController.getUserNameById(gift.pledgedBy);
          if (userName != null) {
            userNames[gift.pledgedBy] = userName;
          }
        }
      }

      setState(() {
        pledgedGifts = pledgedGiftsList;
      });
    } catch (e) {
      print('Error loading pledged gifts: $e');
      setState(() {
        pledgedGifts = [];
      });
    }
  }

  // Update a pledged gift
  Future<void> updatePledgedGift(GiftModel updatedGift) async {
    try {
      await _giftController.updateGift(updatedGift);

      // Trigger notifications for updates on gift status
      await _giftController.addNotificationToFirestore(
          updatedGift.userId,
          "The status of your pledged gift '${updatedGift.name}' has been updated to '${updatedGift.status}'.");
      await _giftController.addNotificationToSQLite(
          updatedGift.userId,
          "The status of your pledged gift '${updatedGift.name}' has been updated to '${updatedGift.status}'.");
      await _giftController.triggerNotification(
          updatedGift.userId,
          "The status of your pledged gift '${updatedGift.name}' has been updated to '${updatedGift.status}'.");

      loadPledgedGifts();
    } catch (e) {
      print('Error updating pledged gift: $e');
    }
  }

  // Get color based on gift status
  Color getStatusColor(String status) {
    switch (status) {
      case 'Pledged':
        return Colors.orange;
      case 'Purchased':
        return Colors.red;
      case 'Available':
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Pledged Gifts'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              loadPledgedGifts();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: pledgedGifts.isEmpty
          ? Center(child: Text('No pledged gifts available.'))
          : ListView.builder(
        itemCount: pledgedGifts.length,
        itemBuilder: (context, index) {
          final gift = pledgedGifts[index];
          final eventName = eventNames[gift.eventFirebaseId] ?? 'Unknown Event';
          final pledgedByName = userNames[gift.pledgedBy] ?? 'Unknown User';
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(Icons.card_giftcard, color: getStatusColor(gift.status)),
              title: Text(gift.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Description: ${gift.description}'),
                  Text('Status: ${gift.status}'),
                  Text('Event: $eventName'),
                  Text('Pledged By: $pledgedByName'), // New section
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => EditPledgedGiftDialog(
                      gift: gift,
                      onSave: (updatedGift) {
                        updatePledgedGift(updatedGift);
                      },
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class EditPledgedGiftDialog extends StatefulWidget {
  final GiftModel gift;
  final Function(GiftModel) onSave;

  EditPledgedGiftDialog({required this.gift, required this.onSave});

  @override
  _EditPledgedGiftDialogState createState() => _EditPledgedGiftDialogState();
}

class _EditPledgedGiftDialogState extends State<EditPledgedGiftDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _status = 'Pledged';

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.gift.name;
    _descriptionController.text = widget.gift.description;
    _status = widget.gift.status;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Pledged Gift'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Gift Name'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            DropdownButton<String>(
              value: _status,
              onChanged: (String? newValue) {
                setState(() {
                  _status = newValue!;
                });
              },
              items: ['Available', 'Pledged', 'Purchased']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            final updatedGift = widget.gift.copyWith(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              status: _status,
            );
            widget.onSave(updatedGift);
            Navigator.of(context).pop();
          },
          child: Text('Save'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
      ],
    );
  }
}
