import 'package:flutter/material.dart';
import '../controllers/gift_controller.dart';
import '../models/gift_model.dart';

class MyPledgedGiftsPage extends StatefulWidget {
  final String userId; // User ID to filter gifts

  MyPledgedGiftsPage({required this.userId});

  @override
  _MyPledgedGiftsPageState createState() => _MyPledgedGiftsPageState();
}

class _MyPledgedGiftsPageState extends State<MyPledgedGiftsPage> {
  final GiftController _giftController = GiftController();
  List<GiftModel> pledgedGifts = [];

  @override
  void initState() {
    super.initState();
    loadPledgedGifts();
  }

  // Fetch pledged gifts dynamically
  Future<void> loadPledgedGifts() async {
    try {
      final allGifts = await _giftController.getAllGifts(widget.userId); // Pass userId
      setState(() {
        pledgedGifts =
            allGifts.where((gift) => gift.status == 'Pledged').toList();
      });
    } catch (e) {
      print('Error loading pledged gifts: $e');
    }
  }

  // Update a pledged gift
  Future<void> updatePledgedGift(GiftModel updatedGift) async {
    await _giftController.updateGift(updatedGift);
    loadPledgedGifts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Pledged Gifts')),
      body: pledgedGifts.isEmpty
          ? Center(child: Text('No pledged gifts available.'))
          : ListView.builder(
        itemCount: pledgedGifts.length,
        itemBuilder: (context, index) {
          final gift = pledgedGifts[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(Icons.card_giftcard, color: Colors.blue),
              title: Text(gift.name),
              subtitle: Text(
                'Due Date: ${gift.description}', // Assume description holds the due date
              ),
              trailing: IconButton(
                icon: Icon(Icons.edit),
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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Gift Name'),
          ),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(labelText: 'Due Date'),
          ),
          DropdownButton<String>(
            value: _status,
            onChanged: (String? newValue) {
              setState(() {
                _status = newValue!;
              });
            },
            items: ['Pledged', 'Available']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
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
