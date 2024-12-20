import 'dart:async';
import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  late StreamSubscription _subscription;

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

  void dispose() {
    _subscription.cancel();
  }
}