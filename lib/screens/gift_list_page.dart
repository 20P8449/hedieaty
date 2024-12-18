import 'package:flutter/material.dart';
import '../controllers/gift_controller.dart';
import '../models/gift_model.dart';
import 'gift_details_page.dart';

class GiftListPage extends StatefulWidget {
  final String selectedEventId; // Event ID for filtering gifts
  final String selectedEventName;

  GiftListPage({required this.selectedEventId, required this.selectedEventName});

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

  // Load gifts for the specific event
  Future<void> loadGifts() async {
    final loadedGifts = await _giftController.getAllGifts();
    setState(() {
      gifts = loadedGifts
          .where((gift) => gift.eventFirebaseId == widget.selectedEventId)
          .toList();
    });
  }

  // Update the gift in the database
  Future<void> updateGift(GiftModel gift) async {
    await _giftController.updateGift(gift);
    loadGifts();
  }

  // Delete a gift
  Future<void> deleteGift(int id) async {
    await _giftController.deleteGift(id);
    loadGifts();
  }

  // Publish a gift to Firestore
  Future<void> publishGift(GiftModel gift) async {
    await _giftController.publishGift(gift);
    loadGifts();
  }

  // Unpublish a gift from Firestore
  Future<void> unpublishGift(GiftModel gift) async {
    await _giftController.unpublishGift(gift);
    loadGifts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gifts for ${widget.selectedEventName}'),
      ),
      body: gifts.isEmpty
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
              onTap: () {
                // Navigate to GiftDetailsPage
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
                      onSave: (updatedGiftData) {
                        final updatedGift = gift.copyWith(
                          name: updatedGiftData['name'],
                          description: updatedGiftData['description'],
                          category: updatedGiftData['category'],
                          price: updatedGiftData['price'],
                          status: updatedGiftData['status'],
                        );
                        updateGift(updatedGift);
                      },
                    ),
                  ),
                );
              },
              trailing: Row(
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
              ),
            ),
          );
        },
      ),
    );
  }
}
