import 'package:flutter/material.dart';
import '../controllers/gift_controller.dart';
import '../controllers/event_controller.dart';
import '../models/gift_model.dart';
import '../models/event_model.dart';
import 'gift_details_page.dart';

class GiftListPage extends StatefulWidget {
  @override
  _GiftListPageState createState() => _GiftListPageState();
}

class _GiftListPageState extends State<GiftListPage> {
  final GiftController _giftController = GiftController();
  final EventController _eventController = EventController();

  List<GiftModel> gifts = [];
  List<EventModel> events = [];
  Map<String, String> eventMap = {}; // Map to hold eventFirebaseId -> event name
  String? sortOption;

  @override
  void initState() {
    super.initState();
    loadGifts();
    loadEvents();
  }

  // Load gifts from SQLite
  Future<void> loadGifts() async {
    final loadedGifts = await _giftController.getAllGifts();
    setState(() {
      gifts = loadedGifts;
    });
  }

  // Load events and create a map of eventFirebaseId to event name
  Future<void> loadEvents() async {
    final loadedEvents = await _eventController.getAllEvents();
    setState(() {
      events = loadedEvents;
      eventMap = {for (var e in loadedEvents) e.eventFirebaseId: e.name};
    });
  }

  Future<void> updateGift(GiftModel gift) async {
    await _giftController.updateGift(gift);
    loadGifts();
  }

  Future<void> deleteGift(int id) async {
    await _giftController.deleteGift(id);
    loadGifts();
  }

  Future<void> publishGift(GiftModel gift) async {
    if (gift.eventFirebaseId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please associate a gift with an event.")),
      );
      return;
    }
    await _giftController.publishGift(gift);
    loadGifts();
  }

  Future<void> unpublishGift(GiftModel gift) async {
    await _giftController.unpublishGift(gift);
    loadGifts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gift List'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // Show add gift dialog here (if applicable)
            },
          ),
          DropdownButton<String>(
            value: sortOption,
            hint: Text("Sort By"),
            items: <String>['Name', 'Category', 'Status'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                sortOption = value;
                // Sorting logic can be added here
              });
            },
          ),
        ],
      ),
      body: gifts.isEmpty
          ? Center(child: Text('No gifts available.'))
          : ListView.builder(
        itemCount: gifts.length,
        itemBuilder: (context, index) {
          final gift = gifts[index];
          final associatedEventName =
              eventMap[gift.eventFirebaseId] ?? 'Unknown Event';

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
                  Text('Event: $associatedEventName'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
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
                              setState(() {
                                final updatedGift = gift.copyWith(
                                  name: updatedGiftData['name'],
                                  description: updatedGiftData['description'],
                                  category: updatedGiftData['category'],
                                  price: updatedGiftData['price'],
                                  status: updatedGiftData['status'],
                                );
                                _giftController.updateGift(updatedGift);
                                loadGifts();
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
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
