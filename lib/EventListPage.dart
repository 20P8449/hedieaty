import 'package:flutter/material.dart';

class EventListPage extends StatefulWidget {
  @override
  _EventListPageState createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  List<Map<String, dynamic>> events = [
    {'name': 'Birthday Party', 'category': 'Personal', 'status': 'Upcoming'},
    {'name': 'Wedding', 'category': 'Friends', 'status': 'Past'},
    {'name': 'Office Meeting', 'category': 'Work', 'status': 'Current'},
  ];

  String? sortOption; // For sorting

  void addEvent(Map<String, dynamic> newEvent) {
    setState(() {
      events.add(newEvent);
    });
  }

  void editEvent(int index, Map<String, dynamic> updatedEvent) {
    setState(() {
      events[index] = updatedEvent;
    });
  }

  void deleteEvent(int index) {
    setState(() {
      events.removeAt(index);
    });
  }

  void sortEvents() {
    setState(() {
      if (sortOption == 'Name') {
        events.sort((a, b) => a['name'].compareTo(b['name']));
      } else if (sortOption == 'Category') {
        events.sort((a, b) => a['category'].compareTo(b['category']));
      } else if (sortOption == 'Status') {
        events.sort((a, b) => a['status'].compareTo(b['status']));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event List'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // Navigate to Add Event page
              showDialog(
                context: context,
                builder: (context) => EventDialog(
                  onSave: (event) => addEvent(event),
                  title: 'Add Event',
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
                sortEvents();
              });
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return ListTile(
            title: Text(event['name']),
            subtitle: Text('Category: ${event['category']} - Status: ${event['status']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => EventDialog(
                        onSave: (updatedEvent) => editEvent(index, updatedEvent),
                        title: 'Edit Event',
                        initialEvent: event,
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => deleteEvent(index),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class EventDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final String title;
  final Map<String, dynamic>? initialEvent;

  EventDialog({required this.onSave, required this.title, this.initialEvent});

  @override
  _EventDialogState createState() => _EventDialogState();
}

class _EventDialogState extends State<EventDialog> {
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  String _status = 'Upcoming';

  @override
  void initState() {
    super.initState();
    if (widget.initialEvent != null) {
      _nameController.text = widget.initialEvent!['name'];
      _categoryController.text = widget.initialEvent!['category'];
      _status = widget.initialEvent!['status'];
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
            decoration: InputDecoration(labelText: 'Event Name'),
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
            items: <String>['Upcoming', 'Current', 'Past']
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
            final newEvent = {
              'name': _nameController.text,
              'category': _categoryController.text,
              'status': _status,
            };
            widget.onSave(newEvent);
            Navigator.of(context).pop();
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}
