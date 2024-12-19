import 'package:flutter/material.dart';
import '../controllers/event_controller.dart';
import '../models/event_model.dart';
import 'gift_list_page.dart';
import 'gift_pledge_page.dart';

class EventListPage extends StatefulWidget {
  final String userId; // User ID to filter events and gifts by user
  final String currentUserId; // Current logged-in user ID

  EventListPage({required this.userId, required this.currentUserId});

  @override
  _EventListPageState createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  final EventController _eventController = EventController();
  List<EventModel> events = [];
  int upcomingEventCount = 0;

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  // Load events for the user and calculate upcoming events
  Future<void> loadEvents() async {
    try {
      final allEvents = await _eventController.getEventsByUserId(widget.userId);

      // Parse dates and filter upcoming events
      final now = DateTime.now();
      final upcomingEvents = allEvents
          .where((event) {
        final eventDate = DateTime.tryParse(event.date);
        return eventDate != null && eventDate.isAfter(now);
      })
          .toList();

      setState(() {
        events = allEvents; // Show all events
        upcomingEventCount = upcomingEvents.length; // Count upcoming events
      });
    } catch (e) {
      print('Error loading events: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.userId == widget.currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text("Events"),
        actions: [
          if (upcomingEventCount > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Upcoming: $upcomingEventCount",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
        ],
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GiftListPage(
                      selectedEventId: event.eventFirebaseId,
                      selectedEventName: event.name,
                      userId: widget.userId,
                      currentUserId: widget.currentUserId,
                    ),
                  ),
                );
              },
              trailing: isOwner
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: event.published,
                    onChanged: (value) async {
                      await _eventController.togglePublished(event);
                      loadEvents();
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => EventDialog(
                          title: 'Edit Event',
                          initialEvent: event,
                          userId: widget.userId,
                          onSave: (updatedEvent) async {
                            await _eventController.updateEvent(updatedEvent);
                            loadEvents();
                          },
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () async {
                      await _eventController.deleteEvent(event.id!);
                      loadEvents();
                    },
                  ),
                ],
              )
                  : ElevatedButton(
                onPressed: () {
                  // Navigate to Gift Pledge Page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GiftPledgePage(
                        eventId: event.eventFirebaseId,
                        eventName: event.name,
                        friendId: widget.userId,
                        currentUserId: widget.currentUserId,
                      ),
                    ),
                  );
                },
                child: Text("Pledge Gift"),
              ),
            ),
          );
        },
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => EventDialog(
              title: 'Add Event',
              userId: widget.userId,
              onSave: (newEvent) async {
                await _eventController.addEvent(newEvent);
                loadEvents();
              },
            ),
          );
        },
        child: Icon(Icons.add),
      )
          : null, // Hide add button for non-owners
    );
  }
}

class EventDialog extends StatefulWidget {
  final Function(EventModel) onSave;
  final String title;
  final EventModel? initialEvent;
  final String userId;

  EventDialog({
    required this.onSave,
    required this.title,
    this.initialEvent,
    required this.userId,
  });

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
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _dateController,
              decoration: InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
            ),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(labelText: 'Location'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
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
              userId: widget.userId,
              eventFirebaseId: widget.initialEvent?.eventFirebaseId ?? '',
              published: widget.initialEvent?.published ?? false,
            );
            widget.onSave(event);
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
