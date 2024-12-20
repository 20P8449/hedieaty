import 'package:flutter/material.dart';
import '../controllers/gift_controller.dart';
import '../models/gift_model.dart';
import '../controllers/user_controller.dart'; // Import UserController
import 'gift_details_page.dart';
import 'package:project/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; // To get the current user ID

class GiftListPage extends StatefulWidget {
  final String selectedEventId; // Event ID for filtering gifts
  final String selectedEventName;
  final String userId; // User ID to filter gifts by user
  final String currentUserId; // Current logged-in user ID

  GiftListPage({
    required this.selectedEventId,
    required this.selectedEventName,
    required this.userId,
    required this.currentUserId,
  });

  @override
  _GiftListPageState createState() => _GiftListPageState();
}

class _GiftListPageState extends State<GiftListPage> {
  final GiftController _giftController = GiftController();
  final UserController _userController = UserController(); // Instantiate UserController
  List<GiftModel> gifts = [];
  String sortCriteria = 'name'; // Default sorting criteria

  @override
  void initState() {
    super.initState();
    loadGifts();
    NotificationService().initialize(FirebaseAuth.instance.currentUser!.uid, context);
  }

  @override
  void dispose() {
    // Dispose NotificationService
    NotificationService().dispose();
    super.dispose();
  }

  // Load gifts for the specific event and user
  Future<void> loadGifts() async {
    try {
      await _giftController.syncGiftsFromFirestore(widget.userId); // Sync gifts for this user
      final loadedGifts = await _giftController.getGiftsByEventAndUser(
        eventId: widget.selectedEventId,
        userId: widget.userId,
      );
      if (mounted) {
        setState(() {
          gifts = sortGifts(loadedGifts); // Sort gifts after fetching
        });
      }
    } catch (e) {
      print('Error loading gifts: $e');
    }
  }

  // Sort gifts based on the selected criteria
  List<GiftModel> sortGifts(List<GiftModel> gifts) {
    switch (sortCriteria) {
      case 'name':
        gifts.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'category':
        gifts.sort((a, b) => a.category.compareTo(b.category));
        break;
      case 'price':
        gifts.sort((a, b) => a.price.compareTo(b.price));
        break;
    }
    return gifts;
  }

  // Add a new gift
  Future<void> addGift(GiftModel newGift) async {
    try {
      await _giftController.addGift(newGift);
      loadGifts();
    } catch (e) {
      print('Error adding gift: $e');
    }
  }

  // Delete a gift
  Future<void> deleteGift(int id) async {
    try {
      await _giftController.deleteGift(id);
      loadGifts();
    } catch (e) {
      print('Error deleting gift: $e');
    }
  }

  // Publish/Unpublish a gift
  Future<void> togglePublishGift(GiftModel gift) async {
    try {
      if (gift.published) {
        await _giftController.unpublishGift(gift);
        print('Gift unpublished: ${gift.name}');
      } else {
        await _giftController.publishGift(gift);
        print('Gift published: ${gift.name}');
      }
      loadGifts();
    } catch (e) {
      print('Error toggling publish state: $e');
    }
  }

  // Mark a gift as pledged
  Future<void> pledgeGift(GiftModel gift) async {
    try {
      // Pledge the gift
      await _giftController.pledgeGift(gift, widget.currentUserId);

      // Fetch the name of the pledging user
      final userName = await _userController.getUserNameById(widget.currentUserId);

      // Alert for Pledging a Gift with the user's real name
      await _giftController.addNotificationToFirestore(
          gift.userId, "Your gift '${gift.name}' has been pledged by $userName.");
      await _giftController.addNotificationToSQLite(
          gift.userId, "Your gift '${gift.name}' has been pledged by $userName.");
      await _giftController.triggerNotification(
          gift.userId, "Your gift '${gift.name}' has been pledged by $userName.");

      // Reload the gifts to reflect updates
      loadGifts();
      print('Gift pledged successfully: ${gift.name}');
    } catch (e) {
      print('Error pledging gift: $e');
    }
  }

  // Update a gift
  Future<void> updateGift(GiftModel gift) async {
    try {
      await _giftController.updateGift(gift);

      // Alert for Gift Status Changes
      await _giftController.addNotificationToFirestore(
          gift.userId,
          "The status of your gift '${gift.name}' has been updated to '${gift.status}'.");
      await _giftController.addNotificationToSQLite(
          gift.userId,
          "The status of your gift '${gift.name}' has been updated to '${gift.status}'.");
      await _giftController.triggerNotification(
          gift.userId,
          "The status of your gift '${gift.name}' has been updated to '${gift.status}'.");

      loadGifts();
    } catch (e) {
      print('Error updating gift: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.userId == widget.currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text('Gifts for ${widget.selectedEventName}'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              loadGifts(); // Reload the gift list
            },
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                sortCriteria = value; // Update the sorting criteria
                gifts = sortGifts(gifts); // Apply sorting
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'name', child: Text('Sort by Name')),
              PopupMenuItem(value: 'category', child: Text('Sort by Category')),
              PopupMenuItem(value: 'price', child: Text('Sort by Price')),
            ],
            icon: Icon(Icons.sort),
          ),
        ],
      ),
      body: gifts.isEmpty
          ? Center(child: Text('No gifts available for this event.'))
          : ListView.builder(
        itemCount: gifts.length,
        itemBuilder: (context, index) {
          final gift = gifts[index];
          final isPledged = gift.status == 'Pledged';
          final photoLink = gift.photoLink; // Assuming `photoLink` is a part of GiftModel

          return Card(
            elevation: 4,
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading: photoLink != null && photoLink.isNotEmpty
                  ? Image.network(
                photoLink,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.broken_image,
                  color: Colors.red,
                ),
              )
                  : Icon(
                Icons.card_giftcard,
                color: isPledged ? Colors.orange : Colors.blue,
              ),
              title: Text(
                gift.name,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Category: ${gift.category}\nPrice: ${gift.price.toStringAsFixed(2)}\nPublished: ${gift.published ? "Yes" : "No"}',
              ),
              trailing: isOwner
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GiftDetailsPage(
                            gift: gift.toMap(),
                            onSave: (updatedGiftData) async {
                              final updatedGift = gift.copyWith(
                                name: updatedGiftData['name'],
                                description: updatedGiftData['description'],
                                category: updatedGiftData['category'],
                                price: updatedGiftData['price'],
                                photoLink: updatedGiftData['photoLink'],
                              );
                              await updateGift(updatedGift);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  Switch(
                    value: gift.published,
                    onChanged: (_) => togglePublishGift(gift),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteGift(gift.id!),
                  ),
                ],
              )
                  : ElevatedButton(
                onPressed: isPledged
                    ? null // Disable button if already pledged
                    : () => pledgeGift(gift),
                child: Text(isPledged ? "Pledged" : "Pledge"),
              ),
            ),
          );
        },
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton(
        onPressed: () async {
          try {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GiftDetailsPage(
                  gift: {
                    'id': null, // ID will be generated dynamically
                    'name': '',
                    'description': '',
                    'category': '',
                    'price': 0.0,
                    'status': 'Available', // Default status set to "Available"
                    'photoLink': '', // Default empty photo link
                  },
                  onSave: (newGiftData) async {
                    final newGift = GiftModel(
                      id: newGiftData['id'], // Use generated ID
                      name: newGiftData['name'],
                      description: newGiftData['description'],
                      category: newGiftData['category'],
                      price: newGiftData['price'],
                      status: 'Available', // Status always set to "Available"
                      published: false,
                      eventFirebaseId: widget.selectedEventId,
                      userId: widget.userId,
                      photoLink: newGiftData['photoLink'], // Save photo link
                    );
                    await addGift(newGift);
                  },
                ),
              ),
            );
          } catch (e) {
            print('Error navigating to add gift: $e');
          }
        },
        child: Icon(Icons.add),
      )
          : null, // Hide add button for non-owners
    );
  }
}
