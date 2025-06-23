import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

// Model for notifications
class AppNotification {
  final String userId;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  AppNotification({
    required this.userId,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
  });

  factory AppNotification.fromMap(Map<String, dynamic> data) {
    return AppNotification(
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead:
          data['isRead'] is bool
              ? data['isRead']
              : data['isRead'].toString().toLowerCase() == 'true',
    );
  }
}

class NotificationScreen extends StatefulWidget {
  final String userId;

  const NotificationScreen({required this.userId, Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late Future<List<AppNotification>> notificationsFuture;

  @override
  void initState() {
    super.initState();
    notificationsFuture = fetchNotifications(widget.userId);
  }

  Future<List<AppNotification>> fetchNotifications(String userId) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .get();

    return snapshot.docs
        .map((doc) => AppNotification.fromMap(doc.data()))
        .toList();
  }

  String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Notifications",
          style: GoogleFonts.archivoBlack(fontSize: 30),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context); // Go back to previous screen (home)
          },
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 1,
      ),
      body: FutureBuilder<List<AppNotification>>(
        future: notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
              ),
            );
          }

          final notifications = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Dismissible(
                key: ValueKey(notification.timestamp.toString()), // Unique key
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) async {
                  final snapshot =
                      await FirebaseFirestore.instance
                          .collection('notifications')
                          .where('userId', isEqualTo: widget.userId)
                          .where(
                            'timestamp',
                            isEqualTo: Timestamp.fromDate(
                              notification.timestamp,
                            ),
                          )
                          .get();

                  for (var doc in snapshot.docs) {
                    await doc.reference.delete();
                  }

                  setState(() {
                    notifications.removeAt(index);
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Notification deleted')),
                  );
                },
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 5,
                  ),
                  leading: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Icon(
                      notification.isRead ? Icons.circle : Icons.circle,
                      color:
                          notification.isRead
                              ? Colors.grey
                              : const Color.fromARGB(255, 0, 200, 255),
                      size: 15,
                    ),
                  ),
                  title: Text(
                    notification.title,
                    style: GoogleFonts.archivoBlack(
                      fontWeight:
                          notification.isRead
                              ? FontWeight.normal
                              : FontWeight.w100,
                      fontSize: 17,
                    ),
                  ),
                  subtitle: Text(
                    notification.message,
                    style: TextStyle(
                      fontWeight:
                          notification.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                    ),
                  ),
                  trailing: Column(
                    children: [
                      Text(
                        timeAgo(notification.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              notification.isRead
                                  ? Colors.grey
                                  : const Color.fromARGB(255, 0, 200, 255),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  onTap: () async {
                    final snapshot =
                        await FirebaseFirestore.instance
                            .collection('notifications')
                            .where('userId', isEqualTo: widget.userId)
                            .where(
                              'timestamp',
                              isEqualTo: Timestamp.fromDate(
                                notification.timestamp,
                              ),
                            )
                            .get();

                    for (var doc in snapshot.docs) {
                      await doc.reference.update({'isRead': true});
                    }

                    setState(() {
                      notifications[index] = AppNotification(
                        userId: notification.userId,
                        title: notification.title,
                        message: notification.message,
                        timestamp: notification.timestamp,
                        isRead: true,
                      );
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Marked as read: ${notification.title}'),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
