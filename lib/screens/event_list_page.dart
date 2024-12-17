import 'package:flutter/material.dart';
import '../controllers/event_controller.dart';
import '../models/event_model.dart';

class EventListPage extends StatefulWidget {
  @override
  _EventListPageState createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  final EventController _eventController = EventController();
  List<EventModel> events = [];

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  Future<void> loadEvents() async {
    final loadedEvents = await _eventController.getAllEvents();
    setState(() {
      events = loadedEvents;
    });
  }

  Future<void> addOrUpdateEvent(EventModel event) async {
    if (event.id == null) {
      await _eventController.addEvent(event);
    } else {
      await _eventController.updateEvent(event);
    }
    loadEvents();
  }

  Future<void> togglePublishedStatus(EventModel event) async {
    await _eventController.togglePublished(event);
    loadEvents();
  }

  Future<void> deleteEvent(int id) async {
    await _eventController.deleteEvent(id);
    loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event List'),
      ),
      body: events.isEmpty
          ? Center(child: Text('No events available.'))
          : ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return Card(
            child: ListTile(
              title: Text(event.name),
              subtitle: Text(
                'Date: ${event.date}\nLocation: ${event.location}\nPublished: ${event.published ? "Yes" : "No"}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: event.published,
                    onChanged: (value) => togglePublishedStatus(event),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => EventDialog(
                          title: 'Edit Event',
                          initialEvent: event,
                          onSave: (updatedEvent) => addOrUpdateEvent(updatedEvent),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => deleteEvent(event.id!),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => EventDialog(
              title: 'Add Event',
              onSave: (newEvent) => addOrUpdateEvent(newEvent),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class EventDialog extends StatefulWidget {
  final Function(EventModel) onSave;
  final String title;
  final EventModel? initialEvent;

  EventDialog({required this.onSave, required this.title, this.initialEvent});

  @override
  _EventDialogState createState() => _EventDialogState();
}

class _EventDialogState extends State<EventDialog> {
  final _nameController = TextEditingController();
  final _dateController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialEvent != null) {
      _nameController.text = widget.initialEvent!.name;
      _dateController.text = widget.initialEvent!.date;
      _locationController.text = widget.initialEvent!.location;
      _descriptionController.text = widget.initialEvent!.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: InputDecoration(labelText: 'Name')),
            TextField(controller: _dateController, decoration: InputDecoration(labelText: 'Date')),
            TextField(controller: _locationController, decoration: InputDecoration(labelText: 'Location')),
            TextField(controller: _descriptionController, decoration: InputDecoration(labelText: 'Description')),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            final event = EventModel(
              id: widget.initialEvent?.id,
              name: _nameController.text.trim(),
              date: _dateController.text.trim(),
              location: _locationController.text.trim(),
              description: _descriptionController.text.trim(),
              userId: widget.initialEvent?.userId ?? '',
              eventFirebaseId: widget.initialEvent?.eventFirebaseId ?? '',
              published: widget.initialEvent?.published ?? false,
            );
            widget.onSave(event);
            Navigator.of(context).pop();
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}
