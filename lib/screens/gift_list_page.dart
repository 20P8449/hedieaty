import 'package:flutter/material.dart';
import '../controllers/gift_controller.dart';
import '../controllers/event_controller.dart';
import '../models/gift_model.dart';
import '../models/event_model.dart';

class GiftListPage extends StatefulWidget {
  @override
  _GiftListPageState createState() => _GiftListPageState();
}

class _GiftListPageState extends State<GiftListPage> {
  final GiftController _giftController = GiftController();
  final EventController _eventController = EventController();

  List<GiftModel> gifts = [];
  List<EventModel> events = [];
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

  // Load events for association
  Future<void> loadEvents() async {
    final loadedEvents = await _eventController.getAllEvents();
    setState(() {
      events = loadedEvents;
    });
  }

  // Add or Update a gift
  Future<void> addOrUpdateGift(GiftModel gift) async {
    if (gift.id == null) {
      await _giftController.addGift(gift);
    } else {
      await _giftController.updateGift(gift);
    }
    loadGifts();
  }

  // Delete a gift
  Future<void> deleteGift(int id) async {
    await _giftController.deleteGift(id);
    loadGifts();
  }

  // Publish a gift to Firestore
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

  // Unpublish a gift from Firestore
  Future<void> unpublishGift(GiftModel gift) async {
    await _giftController.unpublishGift(gift);
    loadGifts();
  }

  // Sort gifts locally
  void sortGifts() {
    setState(() {
      if (sortOption == 'Name') {
        gifts.sort((a, b) => a.name.compareTo(b.name));
      } else if (sortOption == 'Category') {
        gifts.sort((a, b) => a.category.compareTo(b.category));
      } else if (sortOption == 'Status') {
        gifts.sort((a, b) => a.status.compareTo(b.status));
      }
    });
  }

  // Show Gift Dialog
  void showGiftDialog({GiftModel? initialGift}) {
    showDialog(
      context: context,
      builder: (context) => GiftDialog(
        title: initialGift == null ? 'Add Gift' : 'Edit Gift',
        initialGift: initialGift,
        events: events,
        onSave: (updatedGift) => addOrUpdateGift(updatedGift),
      ),
    );
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
              showGiftDialog();
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
                sortGifts();
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
                  if (gift.eventFirebaseId.isNotEmpty)
                    Text('Associated Event: ${gift.eventFirebaseId}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      showGiftDialog(initialGift: gift);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.cloud_upload),
                    color: gift.published ? Colors.grey : Colors.blue,
                    onPressed: () {
                      if (!gift.published) {
                        publishGift(gift);
                      }
                    },
                    tooltip: 'Publish',
                  ),
                  IconButton(
                    icon: Icon(Icons.cloud_off),
                    color: gift.published ? Colors.red : Colors.grey,
                    onPressed: () {
                      if (gift.published) {
                        unpublishGift(gift);
                      }
                    },
                    tooltip: 'Unpublish',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      deleteGift(gift.id!);
                    },
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

class GiftDialog extends StatefulWidget {
  final String title;
  final GiftModel? initialGift;
  final Function(GiftModel) onSave;
  final List<EventModel> events;

  GiftDialog({
    required this.title,
    this.initialGift,
    required this.onSave,
    required this.events,
  });

  @override
  _GiftDialogState createState() => _GiftDialogState();
}

class _GiftDialogState extends State<GiftDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  String _status = 'Available';
  String _selectedEventId = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialGift != null) {
      _nameController.text = widget.initialGift!.name;
      _descriptionController.text = widget.initialGift!.description;
      _categoryController.text = widget.initialGift!.category;
      _priceController.text = widget.initialGift!.price.toString();
      _status = widget.initialGift!.status;
      _selectedEventId = widget.initialGift!.eventFirebaseId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Gift Name'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: _categoryController,
              decoration: InputDecoration(labelText: 'Category'),
            ),
            TextField(
              controller: _priceController,
              decoration: InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            DropdownButton<String>(
              value: _status,
              items: ['Available', 'Pledged']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _status = value!;
                });
              },
            ),
            DropdownButton<String>(
              value: _selectedEventId.isNotEmpty ? _selectedEventId : null,
              hint: Text("Select Event"),
              isExpanded: true,
              onChanged: (value) {
                setState(() {
                  _selectedEventId = value!;
                });
              },
              items: widget.events
                  .map((event) => DropdownMenuItem(
                value: event.eventFirebaseId,
                child: Text(event.name),
              ))
                  .toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onSave(
              GiftModel(
                id: widget.initialGift?.id,
                name: _nameController.text.trim(),
                description: _descriptionController.text.trim(),
                category: _categoryController.text.trim(),
                price: double.tryParse(_priceController.text.trim()) ?? 0.0,
                status: _status,
                eventFirebaseId: _selectedEventId,
                giftFirebaseId: widget.initialGift?.giftFirebaseId ?? '',
                published: widget.initialGift?.published ?? false,
              ),
            );
            Navigator.of(context).pop();
          },
          child: Text('Save'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
      ],
    );
  }
}
