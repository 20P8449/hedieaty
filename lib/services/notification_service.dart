import 'dart:async';
import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  late StreamSubscription _subscription;

  /// Initialize notifications listener for a specific user
  void initialize(String userId, BuildContext context) {
    _subscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final notification = doc.data();
        _showNotification(context, notification['message']);

        // Mark the notification as read
        FirebaseFirestore.instance
            .collection('notifications')
            .doc(doc.id)
            .update({'isRead': true});
      }
    });
  }

  /// Show a notification using Flushbar
  void _showNotification(BuildContext context, String message) {
    Flushbar(
      message: message,
      backgroundColor: Colors.amber,
      icon: const Icon(Icons.notifications, color: Colors.black),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(10),
      flushbarPosition: FlushbarPosition.TOP, // Display at the top
    ).show(context);
  }

  /// Send a notification to a specific user
  Future<void> sendNotification(String userId, String message) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'message': message,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(), // Optional timestamp
      });
    } catch (e) {
      print('Error sending notification: $e');
      throw Exception('Failed to send notification');
    }
  }

  /// Dispose of the notifications listener
  void dispose() {
    _subscription.cancel();
  }
}
