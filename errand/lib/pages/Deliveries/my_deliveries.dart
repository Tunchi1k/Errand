import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:errand/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyDeliveriesPage extends StatelessWidget {
  const MyDeliveriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        appBar: AppBar(
          title: const Text('My Deliveries'),
          backgroundColor: const Color(0xFFF6F8FB),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: const Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Delivery state tabs.
              Container(
                margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF6B7280),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w900),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                  indicator: BoxDecoration(
                    color: const Color(0xFF102A43),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tabs: const [Tab(text: 'Active'), Tab(text: 'Completed')],
                ),
              ),
              Expanded(
                child:
                    user == null
                        ? const _SignedOutState()
                        : StreamBuilder<List<Delivery>>(
                          stream: FirestoreDeliveriesRepository()
                              .watchRunnerDeliveries(user.uid),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const _DeliveriesLoadingState();
                            }

                            if (snapshot.hasError) {
                              return const _CenteredState(
                                icon: Icons.cloud_off_outlined,
                                title: 'Could not load deliveries',
                                message:
                                    'Please check your connection and try again.',
                              );
                            }

                            final deliveries =
                                snapshot.data ?? const <Delivery>[];
                            final activeDeliveries =
                                deliveries
                                    .where((delivery) => !delivery.isCompleted)
                                    .toList();
                            final completedDeliveries =
                                deliveries
                                    .where((delivery) => delivery.isCompleted)
                                    .toList();

                            return TabBarView(
                              children: [
                                _ActiveDeliveryTab(
                                  activeDelivery:
                                      activeDeliveries.isEmpty
                                          ? null
                                          : activeDeliveries.first,
                                ),
                                _CompletedDeliveriesTab(
                                  completedDeliveries: completedDeliveries,
                                ),
                              ],
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum DeliveryStatus {
  headingToPickup,
  arrivedAtPickup,
  itemCollected,
  delivered,
  completed,
}

extension DeliveryStatusDetails on DeliveryStatus {
  String get label {
    return switch (this) {
      DeliveryStatus.headingToPickup => 'Heading to Pickup',
      DeliveryStatus.arrivedAtPickup => 'Arrived at Pickup',
      DeliveryStatus.itemCollected => 'Item Collected',
      DeliveryStatus.delivered => 'Delivered',
      DeliveryStatus.completed => 'Completed',
    };
  }

  String get firestoreValue {
    return switch (this) {
      DeliveryStatus.headingToPickup => 'headingToPickup',
      DeliveryStatus.arrivedAtPickup => 'arrivedAtPickup',
      DeliveryStatus.itemCollected => 'itemCollected',
      DeliveryStatus.delivered => 'delivered',
      DeliveryStatus.completed => 'completed',
    };
  }

  String? get actionLabel {
    return switch (this) {
      DeliveryStatus.headingToPickup => 'Arrived at Pickup',
      DeliveryStatus.arrivedAtPickup => 'Item Collected',
      DeliveryStatus.itemCollected => 'Delivered',
      DeliveryStatus.delivered => 'Complete Errand',
      DeliveryStatus.completed => null,
    };
  }

  DeliveryStatus get next {
    return switch (this) {
      DeliveryStatus.headingToPickup => DeliveryStatus.arrivedAtPickup,
      DeliveryStatus.arrivedAtPickup => DeliveryStatus.itemCollected,
      DeliveryStatus.itemCollected => DeliveryStatus.delivered,
      DeliveryStatus.delivered => DeliveryStatus.completed,
      DeliveryStatus.completed => DeliveryStatus.completed,
    };
  }

  static DeliveryStatus fromFirestore(dynamic value) {
    return switch (value?.toString()) {
      'arrivedAtPickup' => DeliveryStatus.arrivedAtPickup,
      'itemCollected' => DeliveryStatus.itemCollected,
      'delivered' => DeliveryStatus.delivered,
      'completed' => DeliveryStatus.completed,
      _ => DeliveryStatus.headingToPickup,
    };
  }
}

class Delivery {
  const Delivery({
    required this.id,
    required this.title,
    required this.category,
    required this.requesterName,
    required this.pickupLocation,
    required this.destination,
    required this.reward,
    required this.rewardAmount,
    required this.status,
    required this.completedDate,
  });

  final String id;
  final String title;
  final String category;
  final String requesterName;
  final String pickupLocation;
  final String destination;
  final String reward;
  final double rewardAmount;
  final DeliveryStatus status;
  final String? completedDate;

  bool get isCompleted => status == DeliveryStatus.completed;

  factory Delivery.fromFirestore(String id, Map<String, dynamic> data) {
    final price = data['price'];
    final updatedAt = data['updatedAt'];
    final createdAt = data['createdAt'];
    final statusText = data['status']?.toString();
    final deliveryStatus =
        statusText == 'Completed'
            ? DeliveryStatus.completed
            : DeliveryStatusDetails.fromFirestore(data['deliveryStatus']);
    final rewardAmount = price is num ? price.toDouble() : 0.0;

    return Delivery(
      id: id,
      title: data['title']?.toString() ?? 'Untitled Errand',
      category: data['category']?.toString() ?? 'Other',
      requesterName: data['senderName']?.toString() ?? 'Requester',
      pickupLocation: data['pickupLocation']?.toString() ?? '',
      destination:
          data['dropoffLocation']?.toString() ??
          data['deliveryLocation']?.toString() ??
          '',
      reward: _formatReward(rewardAmount),
      rewardAmount: rewardAmount,
      status: deliveryStatus,
      completedDate:
          deliveryStatus == DeliveryStatus.completed
              ? _formatCompletionDate(updatedAt ?? createdAt)
              : null,
    );
  }

  static String _formatReward(double price) {
    final hasDecimals = price % 1 != 0;
    return 'K${price.toStringAsFixed(hasDecimals ? 2 : 0)}';
  }

  static String _formatCompletionDate(dynamic timestamp) {
    if (timestamp is! Timestamp) return 'Today';

    final completedAt = timestamp.toDate();
    final now = DateTime.now();
    final isToday =
        completedAt.year == now.year &&
        completedAt.month == now.month &&
        completedAt.day == now.day;

    if (isToday) return 'Today';
    return '${completedAt.day}/${completedAt.month}/${completedAt.year}';
  }
}

class FirestoreDeliveriesRepository {
  Stream<List<Delivery>> watchRunnerDeliveries(String runnerId) {
    return FirebaseFirestore.instance
        .collection('errands')
        .where('runnerId', isEqualTo: runnerId)
        .snapshots()
        .map((snapshot) {
          final docs = [...snapshot.docs];
          docs.sort((a, b) {
            final aTime = a.data()['updatedAt'] ?? a.data()['acceptedAt'];
            final bTime = b.data()['updatedAt'] ?? b.data()['acceptedAt'];

            if (aTime is Timestamp && bTime is Timestamp) {
              return bTime.compareTo(aTime);
            }

            return 0;
          });

          return docs
              .map((doc) => Delivery.fromFirestore(doc.id, doc.data()))
              .toList();
        });
  }

  Future<void> advanceDelivery(Delivery delivery) async {
    final nextStatus = delivery.status.next;
    await FirebaseFirestore.instance
        .collection('errands')
        .doc(delivery.id)
        .update({
          'status': 'In Progress',
          'deliveryStatus': nextStatus.firestoreValue,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> completeDelivery({
    required Delivery delivery,
    required String runnerId,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final errandRef = firestore.collection('errands').doc(delivery.id);
    final userRef = firestore.collection('users').doc(runnerId);

    final remainingFloats = await firestore.runTransaction<int>((
      transaction,
    ) async {
      final userSnapshot = await transaction.get(userRef);
      final currentFloats = userSnapshot.data()?['floats'];
      final newFloats = (currentFloats is num ? currentFloats.toInt() : 0) - 1;

      transaction.update(errandRef, {
        'status': 'Completed',
        'deliveryStatus': DeliveryStatus.completed.firestoreValue,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(userRef, {
        'earnings': FieldValue.increment(delivery.rewardAmount),
        'completedErrands': FieldValue.increment(1),
        'performanceScore': 99,
        'floats': newFloats,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return newFloats;
    });

    await NotificationService.sendNotification(
      userId: runnerId,
      title: 'Delivery Completed',
      message: 'You earned ${delivery.reward} from completing your delivery.',
      actionLabel: 'View Earnings',
      destinationPage: 'earnings',
      notificationType: 'delivery_completed',
    );

    await NotificationService.sendNotification(
      userId: runnerId,
      title: 'Float Balance Updated',
      message:
          'Your delivery has been completed successfully.\n\n1 float has been deducted from your account.\n\nRemaining Balance: $remainingFloats Floats.',
      actionLabel: 'View Float Balance',
      destinationPage: 'buy_floats',
      notificationType: 'float_updated',
    );
  }
}

class _ActiveDeliveryTab extends StatelessWidget {
  const _ActiveDeliveryTab({required this.activeDelivery});

  final Delivery? activeDelivery;

  @override
  Widget build(BuildContext context) {
    if (activeDelivery == null) {
      return const EmptyDeliveryState();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        ActiveDeliveryCard(delivery: activeDelivery!),
        const SizedBox(height: 16),
        DeliveryStatusButton(delivery: activeDelivery!),
      ],
    );
  }
}

class _CompletedDeliveriesTab extends StatelessWidget {
  const _CompletedDeliveriesTab({required this.completedDeliveries});

  final List<Delivery> completedDeliveries;

  @override
  Widget build(BuildContext context) {
    if (completedDeliveries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text(
            'Completed errands will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      itemCount: completedDeliveries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder:
          (context, index) =>
              CompletedDeliveryCard(delivery: completedDeliveries[index]),
    );
  }
}

class ActiveDeliveryCard extends StatelessWidget {
  const ActiveDeliveryCard({super.key, required this.delivery});

  final Delivery delivery;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  delivery.title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _RewardPill(reward: delivery.reward),
            ],
          ),
          const SizedBox(height: 18),
          _DeliveryInfoRow(label: 'Category', value: delivery.category),
          _DeliveryInfoRow(label: 'Reward', value: delivery.reward),
          _DeliveryInfoRow(label: 'Pickup', value: delivery.pickupLocation),
          _DeliveryInfoRow(label: 'Destination', value: delivery.destination),
          _DeliveryInfoRow(label: 'Requester', value: delivery.requesterName),
          _DeliveryInfoRow(label: 'Status', value: delivery.status.label),
        ],
      ),
    );
  }
}

class DeliveryStatusButton extends StatefulWidget {
  const DeliveryStatusButton({super.key, required this.delivery});

  final Delivery delivery;

  @override
  State<DeliveryStatusButton> createState() => _DeliveryStatusButtonState();
}

class _DeliveryStatusButtonState extends State<DeliveryStatusButton> {
  bool _isSaving = false;

  Future<void> _handlePressed() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (widget.delivery.status == DeliveryStatus.delivered) {
      await _showCompleteDeliveryDialog(user.uid);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await FirestoreDeliveriesRepository().advanceDelivery(widget.delivery);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showCompleteDeliveryDialog(String runnerId) async {
    final delivery = widget.delivery;
    final shouldComplete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Complete Delivery'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reward: ${delivery.reward}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),
                const Text('Completing this delivery will:'),
                const SizedBox(height: 10),
                const _DialogBullet(text: 'Add earnings to the dashboard'),
                const _DialogBullet(text: 'Increase completed errands'),
                const _DialogBullet(text: 'Update performance statistics'),
                const _DialogBullet(text: 'Deduct one float'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF102A43),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Complete'),
              ),
            ],
          ),
    );

    if (shouldComplete != true) return;

    setState(() => _isSaving = true);
    try {
      await FirestoreDeliveriesRepository().completeDelivery(
        delivery: delivery,
        runnerId: runnerId,
      );
      if (!mounted) return;
      _showDeliverySnackBar(
        context,
        message: 'Delivery completed successfully.',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.delivery.status.actionLabel;
    if (label == null) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _isSaving ? null : _handlePressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF102A43),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(_isSaving ? 'Updating...' : label),
      ),
    );
  }
}

class CompletedDeliveryCard extends StatelessWidget {
  const CompletedDeliveryCard({super.key, required this.delivery});

  final Delivery delivery;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  delivery.title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const _CompletedBadge(),
            ],
          ),
          const SizedBox(height: 14),
          _CompactLocationLine(
            icon: Icons.radio_button_checked,
            value: delivery.pickupLocation,
          ),
          const SizedBox(height: 8),
          _CompactLocationLine(
            icon: Icons.location_on_outlined,
            value: delivery.destination,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  delivery.completedDate ?? 'Today',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'Reward: ${delivery.reward}',
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EmptyDeliveryState extends StatelessWidget {
  const EmptyDeliveryState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                color: Color(0xFF9CA3AF),
                size: 44,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Active Delivery',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "You don't have an active errand. Visit Find Errands to accept your next delivery.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280), height: 1.4),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, '/findErrands'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF102A43),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Find Errands'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryInfoRow extends StatelessWidget {
  const _DeliveryInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not set' : value,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardPill extends StatelessWidget {
  const _RewardPill({required this.reward});

  final String reward;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        reward,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CompletedBadge extends StatelessWidget {
  const _CompletedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Completed',
        style: TextStyle(
          color: Color(0xFF047857),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CompactLocationLine extends StatelessWidget {
  const _CompactLocationLine({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF102A43), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value.isEmpty ? 'Not set' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _DialogBullet extends StatelessWidget {
  const _DialogBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('- ', style: TextStyle(fontWeight: FontWeight.w800)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _SignedOutState extends StatelessWidget {
  const _SignedOutState();

  @override
  Widget build(BuildContext context) {
    return const _CenteredState(
      icon: Icons.lock_outline,
      title: 'Sign in required',
      message: 'Please sign in to view your deliveries.',
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF9CA3AF), size: 58),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveriesLoadingState extends StatelessWidget {
  const _DeliveriesLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, __) => const _DeliverySkeletonCard(),
    );
  }
}

class _DeliverySkeletonCard extends StatelessWidget {
  const _DeliverySkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 216,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

void _showDeliverySnackBar(BuildContext context, {required String message}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF102A43),
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
      ),
    );
}
