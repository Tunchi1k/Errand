import 'package:flutter/material.dart';

class MyDeliveriesPage extends StatefulWidget {
  const MyDeliveriesPage({super.key});

  @override
  State<MyDeliveriesPage> createState() => _MyDeliveriesPageState();
}

class _MyDeliveriesPageState extends State<MyDeliveriesPage> {
  Delivery? _activeDelivery = Delivery(
    id: 'delivery-1',
    title: 'Food Pickup',
    category: 'Food Pickup',
    requesterName: 'John Doe',
    pickupLocation: 'Campus Mall',
    destination: 'School of Engineering',
    reward: 'K25',
    status: DeliveryStatus.headingToPickup,
    completedDate: null,
  );

  final List<Delivery> _completedDeliveries = [
    Delivery(
      id: 'delivery-2',
      title: 'Print Assignment',
      category: 'Printing',
      requesterName: 'Sarah Banda',
      pickupLocation: 'Print Hub',
      destination: 'Main Library',
      reward: 'K18',
      status: DeliveryStatus.completed,
      completedDate: 'Today',
    ),
  ];

  double _totalEarnings = 1250;
  int _completedErrands = 45;
  double _performanceScore = 98;
  int _floatBalance = 10;

  void _advanceDeliveryStatus() {
    final delivery = _activeDelivery;
    if (delivery == null) return;

    if (delivery.status == DeliveryStatus.delivered) {
      _showCompleteDeliveryDialog(delivery);
      return;
    }

    setState(() {
      _activeDelivery = delivery.copyWith(status: delivery.status.next);
    });
  }

  Future<void> _showCompleteDeliveryDialog(Delivery delivery) async {
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

    setState(() {
      _totalEarnings += delivery.rewardAmount;
      _completedErrands += 1;
      _performanceScore = 99;
      if (_floatBalance > 0) _floatBalance -= 1;

      _completedDeliveries.insert(
        0,
        delivery.copyWith(
          status: DeliveryStatus.completed,
          completedDate: 'Today',
        ),
      );
      _activeDelivery = null;
    });

    if (!mounted) return;
    _showDeliverySnackBar(context, message: 'Delivery completed successfully.');
  }

  @override
  Widget build(BuildContext context) {
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
              // Navigation tabs for current and completed delivery work.
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
                child: TabBarView(
                  children: [
                    _ActiveDeliveryTab(
                      activeDelivery: _activeDelivery,
                      totalEarnings: _totalEarnings,
                      completedErrands: _completedErrands,
                      performanceScore: _performanceScore,
                      floatBalance: _floatBalance,
                      onAdvanceStatus: _advanceDeliveryStatus,
                    ),
                    _CompletedDeliveriesTab(
                      completedDeliveries: _completedDeliveries,
                    ),
                  ],
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
  final DeliveryStatus status;
  final String? completedDate;

  double get rewardAmount {
    return double.tryParse(reward.replaceAll('K', '').trim()) ?? 0;
  }

  Delivery copyWith({
    String? id,
    String? title,
    String? category,
    String? requesterName,
    String? pickupLocation,
    String? destination,
    String? reward,
    DeliveryStatus? status,
    String? completedDate,
  }) {
    return Delivery(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      requesterName: requesterName ?? this.requesterName,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destination: destination ?? this.destination,
      reward: reward ?? this.reward,
      status: status ?? this.status,
      completedDate: completedDate ?? this.completedDate,
    );
  }
}

class _ActiveDeliveryTab extends StatelessWidget {
  const _ActiveDeliveryTab({
    required this.activeDelivery,
    required this.totalEarnings,
    required this.completedErrands,
    required this.performanceScore,
    required this.floatBalance,
    required this.onAdvanceStatus,
  });

  final Delivery? activeDelivery;
  final double totalEarnings;
  final int completedErrands;
  final double performanceScore;
  final int floatBalance;
  final VoidCallback onAdvanceStatus;

  @override
  Widget build(BuildContext context) {
    if (activeDelivery == null) {
      return const EmptyDeliveryState();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        _MockStatsStrip(
          totalEarnings: totalEarnings,
          completedErrands: completedErrands,
          performanceScore: performanceScore,
          floatBalance: floatBalance,
        ),
        const SizedBox(height: 14),
        ActiveDeliveryCard(delivery: activeDelivery!),
        const SizedBox(height: 16),
        DeliveryStatusButton(
          status: activeDelivery!.status,
          onPressed: onAdvanceStatus,
        ),
      ],
    );
  }
}

class _MockStatsStrip extends StatelessWidget {
  const _MockStatsStrip({
    required this.totalEarnings,
    required this.completedErrands,
    required this.performanceScore,
    required this.floatBalance,
  });

  final double totalEarnings;
  final int completedErrands;
  final double performanceScore;
  final int floatBalance;

  @override
  Widget build(BuildContext context) {
    final hasDecimals = totalEarnings % 1 != 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MiniMetric(
              label: 'Earnings',
              value: 'K${totalEarnings.toStringAsFixed(hasDecimals ? 2 : 0)}',
            ),
          ),
          Expanded(
            child: _MiniMetric(
              label: 'Completed',
              value: completedErrands.toString(),
            ),
          ),
          Expanded(
            child: _MiniMetric(
              label: 'Performance',
              value: '${performanceScore.toStringAsFixed(0)}%',
            ),
          ),
          Expanded(
            child: _MiniMetric(label: 'Floats', value: floatBalance.toString()),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
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

class DeliveryStatusButton extends StatelessWidget {
  const DeliveryStatusButton({
    super.key,
    required this.status,
    required this.onPressed,
  });

  final DeliveryStatus status;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = status.actionLabel;
    if (label == null) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF102A43),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(label),
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
              value,
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
            value,
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