import 'package:cloud_firestore/cloud_firestore.dart';

/// Central write path for the `notifications` collection so every app
/// event (accept, cancel, complete, float deduction, verification) creates
/// notifications in the same shape the Notifications screen reads.
class NotificationService {
  const NotificationService._();

  static Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    String? actionLabel,
    String? destinationPage,
    required String notificationType,
  }) {
    return FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'title': title,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'actionLabel': actionLabel,
      'destinationPage': destinationPage,
      'notificationType': notificationType,
    });
  }
}
