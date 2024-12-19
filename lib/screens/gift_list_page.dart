import 'package:flutter/material.dart';
import '../controllers/gift_controller.dart';
import '../models/gift_model.dart';
import 'gift_details_page.dart';

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
  List<GiftModel> gifts = [];

  @override
  void initState() {
    super.initState();
    loadGifts();
  }

  // Load gifts for the specific event and user
  Future<void> loadGifts() async {
    try {
      await _giftController.syncGiftsFromFirestore(widget.userId); // Sync gifts for this user
      final loadedGifts = await _giftController.getGiftsByEventAndUser(
        widget.selectedEventId,
        widget.userId,
      );
      if (mounted) {
        setState(() {
          gifts = loadedGifts;
        });
      }
    } catch (e) {
      print('Error loading gifts: $e');
    }
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

  // Update the gift in the database
  Future<void> updateGift(GiftModel gift) async {
    try {
      await _giftController.updateGift(gift);
      loadGifts();
    } catch (e) {
      print('Error updating gift: $e');
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

  // Publish a gift to Firestore
  Future<void> publishGift(GiftModel gift) async {
    try {
      await _giftController.publishGift(gift);
      loadGifts();
    } catch (e) {
      print('Error publishing gift: $e');
    }
  }

  // Unpublish a gift from Firestore
  Future<void> unpublishGift(GiftModel gift) async {
    try {
      await _giftController.unpublishGift(gift);
      loadGifts();
    } catch (e) {
      print('Error unpublishing gift: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.userId == widget.currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text('Gifts for ${widget.selectedEventName}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: gifts.isEmpty
                ? Center(child: Text('No gifts available for this event.'))
                : ListView.builder(
              itemCount: gifts.length,
              itemBuilder: (context, index) {
                final gift = gifts[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(
                      Icons.card_giftcard,
                      color: gift.published ? Colors.green : Colors.blue,
                    ),
                    title: Text(gift.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Category: ${gift.category}'),
                        Text('Status: ${gift.status}'),
                      ],
                    ),
                    onTap: isOwner
                        ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GiftDetailsPage(
                            gift: {
                              'id': gift.id,
                              'name': gift.name,
                              'description': gift.description,
                              'category': gift.category,
                              'price': gift.price,
                              'status': gift.status,
                            },
                            onSave: (updatedGiftData) async {
                              final updatedGift = gift.copyWith(
                                name: updatedGiftData['name'],
                                description: updatedGiftData['description'],
                                category: updatedGiftData['category'],
                                price: updatedGiftData['price'],
                                status: updatedGiftData['status'],
                              );
                              await updateGift(updatedGift);
                            },
                          ),
                        ),
                      );
                    }
                        : null,
                    trailing: isOwner
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.cloud_upload),
                          color: gift.published ? Colors.grey : Colors.blue,
                          onPressed: () {
                            if (!gift.published) publishGift(gift);
                          },
                          tooltip: 'Publish',
                        ),
                        IconButton(
                          icon: Icon(Icons.cloud_off),
                          color: gift.published ? Colors.red : Colors.grey,
                          onPressed: () {
                            if (gift.published) unpublishGift(gift);
                          },
                          tooltip: 'Unpublish',
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            deleteGift(gift.id!);
                          },
                          tooltip: 'Delete',
                        ),
                      ],
                    )
                        : null,
                  ),
                );
              },
            ),
          ),
          if (isOwner)
            ElevatedButton(
              onPressed: () async {
                try {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GiftDetailsPage(
                        gift: {
                          'name': '',
                          'description': '',
                          'category': '',
                          'price': 0.0,
                          'status': 'Available',
                        },
                        onSave: (newGiftData) async {
                          final newGift = GiftModel(
                            id: null,
                            name: newGiftData['name'],
                            description: newGiftData['description'],
                            category: newGiftData['category'],
                            price: newGiftData['price'],
                            status: newGiftData['status'],
                            published: false,
                            eventFirebaseId: widget.selectedEventId,
                            userId: widget.userId,
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
              child: Text('Add New Gift'),
            ),
        ],
      ),
    );
  }
}
