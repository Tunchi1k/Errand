import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum NotificationType {
  deliveryAssigned,
  errandCancelled,
  deliveryCompleted,
  floatBalanceUpdated,
  accountVerified,
  runnerAssigned,
  floatsPurchased,
  welcome,
}

extension _NotificationTypeWire on NotificationType {
  static const _wireNames = {
    NotificationType.deliveryAssigned: 'delivery_assigned',
    NotificationType.errandCancelled: 'errand_cancelled',
    NotificationType.deliveryCompleted: 'delivery_completed',
    NotificationType.floatBalanceUpdated: 'float_updated',
    NotificationType.accountVerified: 'account_verified',
    NotificationType.runnerAssigned: 'runner_assigned',
    NotificationType.floatsPurchased: 'floats_purchased',
    NotificationType.welcome: 'welcome',
  };

  String get wireName => _wireNames[this]!;

  static NotificationType fromWireName(String? name) => _wireNames.entries
      .firstWhere(
        (entry) => entry.value == name,
        orElse: () => const MapEntry(NotificationType.deliveryAssigned, ''),
      )
      .key;
}

/// Maps the semantic `destinationPage` key stored on a notification to an
/// existing named route so notifications never need their own routes.
const _kNotificationRoutes = <String, String>{
  'delivery': '/myDeliveries',
  'my_requests': '/myRequests',
  'find_errands': '/findErrands',
  'earnings': '/earnings',
  'buy_floats': '/buyFloats',
  'profile': '/profile',
};

/// Client-side shape kept independent of Firestore for a future FCM adapter.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    required this.actionLabel,
    required this.destinationPage,
    required this.notificationType,
    this.userId = '',
  });

  final String id;
  final String userId;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? actionLabel;
  final String? destinationPage;
  final NotificationType notificationType;

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    userId: userId,
    title: title,
    message: message,
    timestamp: timestamp,
    isRead: isRead ?? this.isRead,
    actionLabel: actionLabel,
    destinationPage: destinationPage,
    notificationType: notificationType,
  );

  factory AppNotification.fromMap(String id, Map<String, dynamic> data) {
    final rawTimestamp = data['timestamp'];
    final timestamp =
        rawTimestamp is Timestamp
            ? rawTimestamp.toDate()
            : rawTimestamp is DateTime
            ? rawTimestamp
            : DateTime.now();
    return AppNotification(
      id: id,
      userId: data['userId']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      message: data['message']?.toString() ?? '',
      timestamp: timestamp,
      isRead: data['isRead'] == true,
      actionLabel: data['actionLabel']?.toString(),
      destinationPage: data['destinationPage']?.toString(),
      notificationType: _NotificationTypeWire.fromWireName(
        data['notificationType']?.toString(),
      ),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'title': title,
    'message': message,
    'timestamp': Timestamp.fromDate(timestamp),
    'isRead': isRead,
    'actionLabel': actionLabel,
    'destinationPage': destinationPage,
    'notificationType': notificationType.wireName,
  };
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({required this.userId, super.key});
  final String userId;
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late final Stream<List<AppNotification>> _notificationsStream;
  NotificationFilter _filter = NotificationFilter.all;

  @override
  void initState() {
    super.initState();
    _notificationsStream = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: widget.userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => AppNotification.fromMap(doc.id, doc.data()))
                  .toList(),
        );
  }

  String timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day ago';
  }

  Future<void> _openNotification(AppNotification notification) async {
    if (!notification.isRead) {
      FirebaseFirestore.instance
          .collection('notifications')
          .doc(notification.id)
          .update({'isRead': true})
          .catchError((e) => debugPrint('Error marking notification read: $e'));
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => NotificationDetailsPage(
              notification: notification.copyWith(isRead: true),
              timeAgo: timeAgo,
            ),
      ),
    );
  }

  Future<bool> _confirmDelete(AppNotification notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Delete notification?'),
            content: const Text(
              'This notification will be permanently removed.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB91C1C),
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed != true) return false;

    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notification.id)
          .delete();
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete notification.')),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      title: Text(
        'Notifications',
        style: GoogleFonts.archivoBlack(fontSize: 30),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () => Navigator.pop(context),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
    ),
    body: StreamBuilder<List<AppNotification>>(
      stream: _notificationsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(child: Text('Error: ${snapshot.error}'));
        final notifications = snapshot.data ?? [];
        final visible =
            notifications.where((notification) {
              switch (_filter) {
                case NotificationFilter.unread:
                  return !notification.isRead;
                case NotificationFilter.read:
                  return notification.isRead;
                case NotificationFilter.all:
                  return true;
              }
            }).toList();
        return Column(
          children: [
            _NotificationFilters(
              selected: _filter,
              onChanged: (value) => setState(() => _filter = value),
            ),
            if (visible.isEmpty)
              const Expanded(
                child: Center(child: Text('No notifications here')),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder:
                      (context, index) {
                        final notification = visible[index];
                        return Dismissible(
                          key: ValueKey(notification.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB91C1C),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          confirmDismiss:
                              (_) => _confirmDelete(notification),
                          child: NotificationCard(
                            notification: notification,
                            timeAgo: timeAgo,
                            onTap: () => _openNotification(notification),
                          ),
                        );
                      },
                ),
              ),
          ],
        );
      },
    ),
  );
}

enum NotificationFilter { all, unread, read }

class _NotificationFilters extends StatelessWidget {
  const _NotificationFilters({required this.selected, required this.onChanged});
  final NotificationFilter selected;
  final ValueChanged<NotificationFilter> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    ),
    child: DefaultTabController(
      length: 3,
      initialIndex: selected.index,
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF6B7280),
        labelStyle: const TextStyle(fontWeight: FontWeight.w900),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
        indicator: BoxDecoration(
          color: const Color(0xFF102A43),
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: (index) => onChanged(NotificationFilter.values[index]),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Unread'),
          Tab(text: 'Read'),
        ],
      ),
    ),
  );
}

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    required this.notification,
    required this.timeAgo,
    required this.onTap,
    super.key,
  });
  final AppNotification notification;
  final String Function(DateTime) timeAgo;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFF1F3F5),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(
              Icons.circle,
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
                  notification.isRead ? FontWeight.normal : FontWeight.w100,
              fontSize: 17,
            ),
          ),
          subtitle: Text(
            notification.message.replaceAll('\n', ' '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight:
                  notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          trailing: Text(
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
        ),
      ),
    ),
  );
}

class NotificationDetailsPage extends StatelessWidget {
  const NotificationDetailsPage({
    required this.notification,
    required this.timeAgo,
    super.key,
  });
  final AppNotification notification;
  final String Function(DateTime) timeAgo;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color.fromARGB(255, 233, 233, 233),
    appBar: AppBar(
      backgroundColor: const Color.fromARGB(255, 233, 233, 233),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Chat'),
      centerTitle: true,
      titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: const Color(0xFF111827),
        fontWeight: FontWeight.w800,
      ),
    ),
    body: Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeAgo(notification.timestamp),
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          if (notification.actionLabel != null)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF102A43),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
                onPressed: () {
                  final route =
                      _kNotificationRoutes[notification.destinationPage];
                  if (route != null) Navigator.pushNamed(context, route);
                },
                child: Text(notification.actionLabel!),
              ),
            ),
        ],
      ),
    ),
  );
}
