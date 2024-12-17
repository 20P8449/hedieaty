import 'package:flutter/material.dart';

class MyPledgedGiftsPage extends StatefulWidget {
  @override
  _MyPledgedGiftsPageState createState() => _MyPledgedGiftsPageState();
}

class _MyPledgedGiftsPageState extends State<MyPledgedGiftsPage> {
  final List<Map<String, dynamic>> pledgedGifts = [
    {
      'name': 'Headphones',
      'friend': 'John Doe',
      'dueDate': '2023-12-01',
      'status': 'Pending'
    },
    {
      'name': 'Smartwatch',
      'friend': 'Jane Smith',
      'dueDate': '2024-01-15',
      'status': 'Pending'
    },
    {
      'name': 'Book',
      'friend': 'Emily Johnson',
      'dueDate': '2023-11-10',
      'status': 'Completed'
    },
  ];

  void editPledgedGift(int index, Map<String, dynamic> updatedGift) {
    setState(() {
      pledgedGifts[index] = updatedGift;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Pledged Gifts')),
      body: ListView.builder(
        itemCount: pledgedGifts.length,
        itemBuilder: (context, index) {
          final gift = pledgedGifts[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(Icons.card_giftcard, color: Colors.blue),
              title: Text(gift['name']),
              subtitle: Text('For: ${gift['friend']} - Due: ${gift['dueDate']}'),
              trailing: gift['status'] == 'Pending'
                  ? IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => EditGiftDialog(
                      gift: gift,
                      onSave: (updatedGift) =>
                          editPledgedGift(index, updatedGift),
                    ),
                  );
                },
              )
                  : Text(
                'Completed',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class EditGiftDialog extends StatefulWidget {
  final Map<String, dynamic> gift;
  final Function(Map<String, dynamic>) onSave;

  EditGiftDialog({required this.gift, required this.onSave});

  @override
  _EditGiftDialogState createState() => _EditGiftDialogState();
}

class _EditGiftDialogState extends State<EditGiftDialog> {
  final _nameController = TextEditingController();
  final _friendController = TextEditingController();
  final _dueDateController = TextEditingController();
  String _status = 'Pending';

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.gift['name'];
    _friendController.text = widget.gift['friend'];
    _dueDateController.text = widget.gift['dueDate'];
    _status = widget.gift['status'];
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
            controller: _friendController,
            decoration: InputDecoration(labelText: 'Friend Name'),
          ),
          TextField(
            controller: _dueDateController,
            decoration: InputDecoration(labelText: 'Due Date (YYYY-MM-DD)'),
          ),
          DropdownButton<String>(
            value: _status,
            onChanged: (String? newValue) {
              setState(() {
                _status = newValue!;
              });
            },
            items: <String>['Pending', 'Completed']
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
            final updatedGift = {
              'name': _nameController.text.trim(),
              'friend': _friendController.text.trim(),
              'dueDate': _dueDateController.text.trim(),
              'status': _status,
            };
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
