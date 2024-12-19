import 'package:flutter/material.dart';
import '../controllers/gift_controller.dart';
import '../models/gift_model.dart';

class GiftPledgePage extends StatefulWidget {
  final String eventId; // Event ID for pledging a gift
  final String eventName; // Event Name
  final String friendId; // Friend ID
  final String currentUserId; // Current logged-in user's ID

  GiftPledgePage({
    required this.eventId,
    required this.eventName,
    required this.friendId,
    required this.currentUserId,
  });

  @override
  _GiftPledgePageState createState() => _GiftPledgePageState();
}

class _GiftPledgePageState extends State<GiftPledgePage> {
  final _giftController = GiftController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  Future<void> pledgeGift() async {
    final gift = GiftModel(
      id: null,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      category: "Pledged",
      price: double.tryParse(_priceController.text) ?? 0.0,
      status: "Pledged",
      eventFirebaseId: widget.eventId,
      userId: widget.currentUserId,
      published: false,
    );

    try {
      await _giftController.addGift(gift);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gift pledged successfully!")),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Error pledging gift: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to pledge gift.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pledge Gift for ${widget.eventName}")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Gift Name"),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: "Description"),
            ),
            TextField(
              controller: _priceController,
              decoration: InputDecoration(labelText: "Price"),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: pledgeGift,
              child: Text("Pledge Gift"),
            ),
          ],
        ),
      ),
    );
  }
}
