import 'package:flutter/material.dart';

class MyPledgedGiftsPage extends StatefulWidget {
  @override
  _MyPledgedGiftsPageState createState() => _MyPledgedGiftsPageState();
}

class _MyPledgedGiftsPageState extends State<MyPledgedGiftsPage> {
  final List<Map<String, dynamic>> pledgedGifts = [
    {'name': 'Headphones', 'friend': 'John Doe', 'dueDate': '2023-12-01', 'status': 'Pending'},
    {'name': 'Smartwatch', 'friend': 'Jane Smith', 'dueDate': '2024-01-15', 'status': 'Pending'},
    {'name': 'Book', 'friend': 'Emily Johnson', 'dueDate': '2023-11-10', 'status': 'Completed'},
  ];

  void editPledgedGift(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return GiftDialog(
          onSave: (updatedGift) {
            setState(() {
              pledgedGifts[index] = updatedGift;
            });
          },
          title: 'Edit Pledged Gift',
          initialGift: pledgedGifts[index],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Pledged Gifts')),
      body: ListView.builder(
        itemCount: pledgedGifts.length,
        itemBuilder: (context, index) {
          final gift = pledgedGifts[index];
          return ListTile(
            title: Text(gift['name']),
            subtitle: Text('For: ${gift['friend']} - Due: ${gift['dueDate']}'),
            trailing: gift['status'] == 'Pending'
                ? IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => editPledgedGift(index),
            )
                : null,
          );
        },
      ),
    );
  }
}

class GiftDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final String title;
  final Map<String, dynamic>? initialGift;

  GiftDialog({required this.onSave, required this.title, this.initialGift});

  @override
  _GiftDialogState createState() => _GiftDialogState();
}

class _GiftDialogState extends State<GiftDialog> {
  final _nameController = TextEditingController();
  final _friendController = TextEditingController();
  final _dueDateController = TextEditingController();
  String _status = 'Pending';

  @override
  void initState() {
    super.initState();
    if (widget.initialGift != null) {
      _nameController.text = widget.initialGift!['name'];
      _friendController.text = widget.initialGift!['friend'];
      _dueDateController.text = widget.initialGift!['dueDate'];
      _status = widget.initialGift!['status'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
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
              'name': _nameController.text,
              'friend': _friendController.text,
              'dueDate': _dueDateController.text,
              'status': _status,
            };
            widget.onSave(updatedGift);
            Navigator.of(context).pop();
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}
