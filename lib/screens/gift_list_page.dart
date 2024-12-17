import 'package:flutter/material.dart';
import 'gift_details_page.dart';

class GiftListPage extends StatefulWidget {
  @override
  _GiftListPageState createState() => _GiftListPageState();
}

class _GiftListPageState extends State<GiftListPage> {
  // Sample gifts data
  List<Map<String, dynamic>> gifts = [
    {'name': 'Smartwatch', 'category': 'Electronics', 'status': 'Available'},
    {'name': 'Book', 'category': 'Books', 'status': 'Pledged'},
    {'name': 'Headphones', 'category': 'Accessories', 'status': 'Available'},
  ];

  String? sortOption; // For sorting

  void addGift(Map<String, dynamic> newGift) {
    setState(() {
      gifts.add(newGift);
    });
  }

  void editGift(int index, Map<String, dynamic> updatedGift) {
    setState(() {
      gifts[index] = updatedGift;
    });
  }

  void deleteGift(int index) {
    setState(() {
      gifts.removeAt(index);
    });
  }

  void sortGifts() {
    setState(() {
      if (sortOption == 'Name') {
        gifts.sort((a, b) => a['name'].compareTo(b['name']));
      } else if (sortOption == 'Category') {
        gifts.sort((a, b) => a['category'].compareTo(b['category']));
      } else if (sortOption == 'Status') {
        gifts.sort((a, b) => a['status'].compareTo(b['status']));
      }
    });
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
              // Show dialog to add a new gift
              showDialog(
                context: context,
                builder: (context) => GiftDialog(
                  onSave: (gift) => addGift(gift),
                  title: 'Add Gift',
                ),
              );
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
      body: ListView.builder(
        itemCount: gifts.length,
        itemBuilder: (context, index) {
          final gift = gifts[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(Icons.card_giftcard, color: Colors.blue),
              title: Text(gift['name']),
              subtitle: Text('Category: ${gift['category']}'),
              tileColor:
              gift['status'] == 'Pledged' ? Colors.green[100] : Colors.white,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      // Navigate to gift details for editing
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GiftDetailsPage(
                            gift: gift,
                            onSave: (updatedGift) => editGift(index, updatedGift),
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      deleteGift(index);
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
  final Function(Map<String, dynamic>) onSave;
  final String title;
  final Map<String, dynamic>? initialGift;

  GiftDialog({required this.onSave, required this.title, this.initialGift});

  @override
  _GiftDialogState createState() => _GiftDialogState();
}

class _GiftDialogState extends State<GiftDialog> {
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  String _status = 'Available';

  @override
  void initState() {
    super.initState();
    if (widget.initialGift != null) {
      _nameController.text = widget.initialGift!['name'];
      _categoryController.text = widget.initialGift!['category'];
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
            controller: _categoryController,
            decoration: InputDecoration(labelText: 'Category'),
          ),
          DropdownButton<String>(
            value: _status,
            onChanged: (String? newValue) {
              setState(() {
                _status = newValue!;
              });
            },
            items: <String>['Available', 'Pledged']
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
            final newGift = {
              'name': _nameController.text.trim(),
              'category': _categoryController.text.trim(),
              'status': _status,
            };
            widget.onSave(newGift);
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
