import 'package:flutter/material.dart';

class GiftDetailsPage extends StatefulWidget {
  final Map<String, dynamic> gift;
  final Function(Map<String, dynamic>) onSave;

  GiftDetailsPage({required this.gift, required this.onSave});

  @override
  _GiftDetailsPageState createState() => _GiftDetailsPageState();
}

class _GiftDetailsPageState extends State<GiftDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  String status = 'Available';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.gift['name']);
    _categoryController = TextEditingController(text: widget.gift['category']);
    status = widget.gift['status'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gift Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Gift Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a gift name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(labelText: 'Category'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a category';
                  }
                  return null;
                },
              ),
              DropdownButton<String>(
                value: status,
                onChanged: (String? newValue) {
                  setState(() {
                    status = newValue!;
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
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final updatedGift = {
                      'name': _nameController.text,
                      'category': _categoryController.text,
                      'status': status,
                    };
                    widget.onSave(updatedGift);
                    Navigator.of(context).pop();
                  }
                },
                child: Text('Save Gift'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}