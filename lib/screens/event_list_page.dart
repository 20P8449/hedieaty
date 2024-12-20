import 'package:flutter/material.dart';
import '../controllers/event_controller.dart';
import '../models/event_model.dart';
import 'gift_list_page.dart';

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
  String sortCriteria = 'name'; // Default sorting criteria

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
      final upcomingEvents = allEvents.where((event) {
        final eventDate = DateTime.tryParse(event.date);
        return eventDate != null && eventDate.isAfter(now);
      }).toList();

      setState(() {
        events = sortEvents(allEvents); // Sort events after fetching
        upcomingEventCount = upcomingEvents.length; // Count upcoming events
      });
    } catch (e) {
      print('Error loading events: $e');
    }
  }

  // Sort events based on the selected criteria
  List<EventModel> sortEvents(List<EventModel> events) {
    switch (sortCriteria) {
      case 'name':
        events.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'category':
        events.sort((a, b) => a.description.compareTo(b.description)); // Assuming category is stored in the description
        break;
      case 'status':
        final now = DateTime.now();
        events.sort((a, b) {
          final dateA = DateTime.tryParse(a.date);
          final dateB = DateTime.tryParse(b.date);

          final statusA = dateA == null
              ? 'Unknown'
              : dateA.isBefore(now)
              ? 'Past'
              : dateA.isAfter(now)
              ? 'Upcoming'
              : 'Current';

          final statusB = dateB == null
              ? 'Unknown'
              : dateB.isBefore(now)
              ? 'Past'
              : dateB.isAfter(now)
              ? 'Upcoming'
              : 'Current';

          return statusA.compareTo(statusB);
        });
        break;
    }
    return events;
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
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                sortCriteria = value; // Update the sorting criteria
                events = sortEvents(events); // Apply sorting
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'name', child: Text('Sort by Name')),
              PopupMenuItem(value: 'category', child: Text('Sort by Category')),
              PopupMenuItem(value: 'status', child: Text('Sort by Status')),
            ],
            icon: Icon(Icons.sort),
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
            elevation: 4,
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              title: Text(
                event.name,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
                    icon: Icon(Icons.edit, color: Colors.blue),
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
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await _eventController.deleteEvent(event.id!);
                      loadEvents();
                    },
                  ),
                ],
              )
                  : ElevatedButton(
                onPressed: () {
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
                child: Text("View Gifts"),
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

// EventDialog Class
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
  final _formKey = GlobalKey<FormState>();
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _dateController.text = pickedDate.toIso8601String().split('T').first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) => value == null || value.isEmpty ? 'Name is required' : null,
              ),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: InputDecoration(labelText: 'Date (Select from Calendar)'),
                    validator: (value) => value == null || value.isEmpty ? 'Date is required' : null,
                  ),
                ),
              ),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(labelText: 'Location'),
                validator: (value) => value == null || value.isEmpty ? 'Location is required' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                validator: (value) => value == null || value.isEmpty ? 'Description is required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
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
            }
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
