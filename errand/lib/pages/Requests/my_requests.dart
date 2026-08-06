import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:errand/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:errand/services/custom_toast.dart';

class MyRequestsPage extends StatefulWidget {
  const MyRequestsPage({super.key});

  @override
  State<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage>
    with SingleTickerProviderStateMixin {
  static const _surfaceGrey = Color(0xFFF1F3F5);
  TabController? _tabs;

  @override
  void initState() {
    super.initState();
    _tabs ??= TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs?.dispose();
    super.dispose();
  }

  TabController get _tabController =>
      _tabs ??= TabController(length: 2, vsync: this);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'My Requests',
          style: GoogleFonts.archivoBlack(fontSize: 30),
        ),
        centerTitle: true,
        backgroundColor: _surfaceGrey,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: const Color(0xFF111827),
          fontWeight: FontWeight.w800,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF9FAFB), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child:
              user == null
                  ? const _SignedOutState()
                  : StreamBuilder<List<RequestErrand>>(
                  stream: FirestoreRequestsRepository().watchUserRequests(
                    user.uid,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _RequestsLoadingState();
                    }

                    if (snapshot.hasError) {
                      return const _RequestsErrorState();
                    }

                    final requests = snapshot.data ?? const <RequestErrand>[];
                    final active = requests.where((r) => !r.isHistory).toList();
                    final history = requests.where((r) => r.isHistory).toList();
                    return Column(
                      children: [
                        Material(
                          color: _surfaceGrey,
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _surfaceGrey,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicatorSize: TabBarIndicatorSize.tab,
                              dividerColor: Colors.transparent,
                              labelColor: Colors.white,
                              unselectedLabelColor: const Color(0xFF6B7280),
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                              unselectedLabelStyle: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                              indicator: BoxDecoration(
                                color: const Color(0xFF102A43),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              tabs: const [
                                Tab(text: 'Active'),
                                Tab(text: 'History'),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _RequestList(
                                requests: active,
                                emptyTitle: 'No Active Requests',
                                emptySubtitle:
                                    "You haven't posted any active requests.",
                              ),
                              _RequestList(
                                requests: history,
                                emptyTitle: 'No Request History',
                                emptySubtitle:
                                    'Completed and cancelled requests will appear here.',
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _EmptyRequestState extends StatelessWidget {
  const _EmptyRequestState({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 52, color: Color(0xFF9CA3AF)),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
      ),
    ),
  );
}

class _RequestList extends StatelessWidget {
  const _RequestList({
    required this.requests,
    required this.emptyTitle,
    required this.emptySubtitle,
  });
  final List<RequestErrand> requests;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return _EmptyRequestState(title: emptyTitle, subtitle: emptySubtitle);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 24),
      itemBuilder: (_, index) {
        final request = requests[index];
        return request.isHistory
            ? _HistoryRequestCard(request: request)
            : request.isTracking
            ? _TrackingRequestCard(request: request)
            : _ActiveRequestCard(request: request);
      },
    );
  }
}

class _HistoryRequestCard extends StatelessWidget {
  const _HistoryRequestCard({required this.request});
  final RequestErrand request;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusBadge(status: request.status),
            ],
          ),
          const SizedBox(height: 12),
          _RequestLocationBlock(request: request),
          const SizedBox(height: 12),
          Text(
            'Reward: ${request.formattedPrice}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}

class RequestErrand {
  const RequestErrand({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.price,
    required this.status,
    required this.createdAt,
    this.runnerId,
    this.acceptedAt,
    this.deliveryStatus,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String pickupLocation;
  final String dropoffLocation;
  final double price;
  final String status;
  final Timestamp? createdAt;
  final String? runnerId;
  final Timestamp? acceptedAt;
  final String? deliveryStatus;

  bool get isWaiting => runnerId == null && status.toLowerCase() == 'active';
  bool get isTracking =>
      runnerId != null &&
      runnerId!.isNotEmpty &&
      status.toLowerCase() != 'completed' &&
      status.toLowerCase() != 'cancelled';
  bool get isHistory =>
      ['completed', 'cancelled'].contains(status.toLowerCase());

  factory RequestErrand.fromFirestore(String id, Map<String, dynamic> data) {
    final price = data['price'];

    return RequestErrand(
      id: id,
      title: data['title']?.toString() ?? 'Untitled Errand',
      description: data['description']?.toString() ?? '',
      category: data['category']?.toString() ?? 'Other',
      pickupLocation: data['pickupLocation']?.toString() ?? '',
      dropoffLocation:
          data['dropoffLocation']?.toString() ??
          data['deliveryLocation']?.toString() ??
          '',
      price: price is num ? price.toDouble() : 0,
      status: data['status']?.toString() ?? 'Active',
      createdAt: data['createdAt'] is Timestamp ? data['createdAt'] : null,
      runnerId: data['runnerId']?.toString(),
      acceptedAt: data['acceptedAt'] is Timestamp ? data['acceptedAt'] : null,
      deliveryStatus: data['deliveryStatus']?.toString() ?? 'headingToPickup',
    );
  }

  String get formattedPrice {
    final hasDecimals = price % 1 != 0;
    return 'K${price.toStringAsFixed(hasDecimals ? 2 : 0)}';
  }

  String get postedAgo {
    if (createdAt == null) return 'Just now';

    final difference = DateTime.now().difference(createdAt!.toDate());
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    }
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    return '${difference.inDays} days ago';
  }
}

class FirestoreRequestsRepository {
  Stream<List<RequestErrand>> watchUserRequests(String userId) {
    return FirebaseFirestore.instance
        .collection('errands')
        .where('senderId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final docs = [...snapshot.docs];
          docs.sort((a, b) {
            final aCreatedAt = a.data()['createdAt'];
            final bCreatedAt = b.data()['createdAt'];

            if (aCreatedAt is Timestamp && bCreatedAt is Timestamp) {
              return bCreatedAt.compareTo(aCreatedAt);
            }

            return 0;
          });

          return docs
              .map((doc) => RequestErrand.fromFirestore(doc.id, doc.data()))
              .toList();
        });
  }

  Future<void> updateRequest(
    String requestId,
    Map<String, dynamic> updates,
  ) async {
    final docRef = FirebaseFirestore.instance
        .collection('errands')
        .doc(requestId);
    await docRef.update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (updates['status'] == 'Cancelled') {
      final snapshot = await docRef.get();
      final runnerId = snapshot.data()?['runnerId']?.toString();
      if (runnerId != null && runnerId.isNotEmpty) {
        await NotificationService.sendNotification(
          userId: runnerId,
          title: 'Errand Cancelled',
          message: 'The sender cancelled your errand before pickup.',
          actionLabel: 'Return to Find Errands',
          destinationPage: 'find_errands',
          notificationType: 'errand_cancelled',
        );
      }
    }
  }

  Future<void> deleteRequest(String requestId) async {
    await FirebaseFirestore.instance
        .collection('errands')
        .doc(requestId)
        .delete();
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final RequestErrand request;

  @override
  Widget build(BuildContext context) {
    final repository = FirestoreRequestsRepository();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF111827).withValues(alpha: 0.06),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusBadge(
                      status:
                          request.isWaiting
                              ? 'Waiting for Runner'
                              : request.status,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      request.title,
                      style: GoogleFonts.archivoBlack(
                        color: const Color(0xFF111827),
                        fontSize: 19,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.category.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _CardIconAction(
                icon: Icons.edit_outlined,
                color: const Color(0xFF102A43),
                onTap: () => _showEditRequestSheet(context, request),
              ),
              const SizedBox(width: 8),
              _CardIconAction(
                icon: Icons.delete_outline,
                color: const Color(0xFF991B1B),
                onTap: () async {
                  final shouldCancel = await _confirmCancel(context);
                  if (!shouldCancel || !context.mounted) return;
                  await repository.updateRequest(request.id, {
                    'status': 'Cancelled',
                  });
                  if (!context.mounted) return;
                  CustomToast.show(context, 'Request cancelled successfully.');
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            request.description,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              height: 1.5,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF0F1F3), height: 1),
          const SizedBox(height: 18),
          _DetailRow(label: 'Pickup', value: request.pickupLocation),
          const SizedBox(height: 12),
          _DetailRow(label: 'Drop-off', value: request.dropoffLocation),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _PricePill(price: request.formattedPrice),
              const Spacer(),
              Text(
                'Posted ${request.postedAgo}',
                style: const TextStyle(
                  color: Color(0xFFB0B4BB),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardIconAction extends StatelessWidget {
  const _CardIconAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? 'Not set' : value,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveRequestCard extends _RequestCard {
  const _ActiveRequestCard({required super.request});
}

class _TrackingRequestCard extends StatelessWidget {
  const _TrackingRequestCard({required this.request});
  final RequestErrand request;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future:
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(request.runnerId)
                    .get(),
            builder:
                (_, snapshot) => _RunnerProfileCard(
                  data: snapshot.data?.data(),
                  acceptedAt: request.acceptedAt,
                ),
          ),
        ),
      ),
      const SizedBox(height: 24),
      _ProgressTimeline(status: request.deliveryStatus ?? 'headingToPickup'),
      const SizedBox(height: 24),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showEditRequestSheet(context, request),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Request'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF102A43),
                side: const BorderSide(color: Color(0xFF102A43)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: () async {
                final confirmed = await _confirmCancel(context);
                if (!confirmed || !context.mounted) return;
                await FirestoreRequestsRepository().updateRequest(request.id, {
                  'status': 'Cancelled',
                });
                if (!context.mounted) return;
                CustomToast.show(context, 'Request cancelled successfully.');
              },
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('Cancel Request'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF991B1B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
      if ((request.deliveryStatus ?? '').toLowerCase() == 'delivered') ...[
        const SizedBox(height: 24),
        _RatingSection(request: request),
      ],
    ],
  );
}

class _RatingSection extends StatefulWidget {
  const _RatingSection({required this.request});
  final RequestErrand request;

  @override
  State<_RatingSection> createState() => _RatingSectionState();
}

class _RatingSectionState extends State<_RatingSection> {
  final _feedbackController = TextEditingController();
  int _rating = 0;
  bool _saving = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _complete({required bool withRating}) async {
    if (withRating && _rating == 0) {
      CustomToast.show(context, 'Please select a star rating.');
      return;
    }
    setState(() => _saving = true);
    try {
      final firestore = FirebaseFirestore.instance;
      final user = FirebaseAuth.instance.currentUser;
      await firestore.collection('errands').doc(widget.request.id).update({
        'status': 'Completed',
        'completedAt': FieldValue.serverTimestamp(),
        if (withRating) 'senderRating': _rating,
        if (withRating) 'senderFeedback': _feedbackController.text.trim(),
      });

      if (withRating && widget.request.runnerId != null) {
        final runnerRef = firestore
            .collection('users')
            .doc(widget.request.runnerId);
        await firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(runnerRef);
          final data = snapshot.data() ?? {};
          final count =
              (data['ratingCount'] is num ? data['ratingCount'] as num : 0)
                  .toInt();
          final average =
              data['rating'] is num ? (data['rating'] as num).toDouble() : 0.0;
          transaction.set(runnerRef, {
            'rating': ((average * count) + _rating) / (count + 1),
            'ratingCount': count + 1,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        });
        await firestore.collection('ratings').add({
          'requestId': widget.request.id,
          'runnerId': widget.request.runnerId,
          'senderId': user?.uid,
          'rating': _rating,
          'optionalComment': _feedbackController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      if (!mounted) return;
      CustomToast.show(
        context,
        withRating
            ? 'Thank you for rating your runner.'
            : 'Delivery completed.',
      );
    } catch (_) {
      if (mounted)
        CustomToast.show(context, 'Could not complete this request.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    future:
        FirebaseFirestore.instance
            .collection('users')
            .doc(widget.request.runnerId)
            .get(),
    builder: (_, snapshot) {
      final data = snapshot.data?.data() ?? {};
      final name = data['name']?.toString() ?? 'Runner';
      final photo = data['profilePhoto']?.toString() ?? '';
      return Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
          child: Column(
            children: [
              CircleAvatar(
                radius: 58,
                backgroundImage: photo.isEmpty ? null : NetworkImage(photo),
                child:
                    photo.isEmpty ? const Icon(Icons.person, size: 48) : null,
              ),
              const SizedBox(height: 14),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'How was your experience?',
                style: TextStyle(color: Color(0xFF4B5563), fontSize: 16),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      onPressed:
                          _saving ? null : () => setState(() => _rating = i),
                      iconSize: 36,
                      icon: Icon(
                        i <= _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                    ),
                ],
              ),
              const Text(
                'Tap a star to rate',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _feedbackController,
                maxLength: 200,
                maxLines: 3,
                enabled: !_saving,
                decoration: InputDecoration(
                  hintText: 'Share your experience with this runner (optional)',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : () => _complete(withRating: true),
                  child: Text(_saving ? 'Saving...' : 'Submit Rating'),
                ),
              ),
              TextButton(
                onPressed: _saving ? null : () => _complete(withRating: false),
                child: const Text('Skip'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _RunnerProfileCard extends StatelessWidget {
  const _RunnerProfileCard({required this.data, this.acceptedAt});
  final Map<String, dynamic>? data;
  final Timestamp? acceptedAt;

  @override
  Widget build(BuildContext context) {
    final name = data?['name']?.toString() ?? 'Runner';
    final photo = data?['profilePhoto']?.toString() ?? '';
    final rating = data?['rating'] ?? data?['runnerRating'] ?? '—';
    final completed = data?['completedErrands'] ?? data?['completed'] ?? 0;
    return Row(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundImage: photo.isEmpty ? null : NetworkImage(photo),
          child: photo.isEmpty ? const Icon(Icons.person, size: 42) : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Runner',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              Text(
                'Rating: $rating',
                style: const TextStyle(color: Color(0xFF4B5563)),
              ),
              Text(
                'Completed: $completed Errands',
                style: const TextStyle(color: Color(0xFF4B5563)),
              ),
              Text(
                'Accepted: ${acceptedAt == null ? 'Just now' : _formatRelative(acceptedAt!)}',
                style: const TextStyle(color: Color(0xFF4B5563)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressTimeline extends StatelessWidget {
  const _ProgressTimeline({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Posted',
      'Accepted',
      'Heading to Pickup',
      'Item Collected',
      'Delivered',
    ];
    final normalized = status.toLowerCase().replaceAll('_', '');
    final current =
        normalized == 'delivered'
            ? 4
            : normalized == 'itemcollected'
            ? 3
            : normalized == 'accepted'
            ? 1
            : 2;
    const descriptions = [
      'Your request was created.',
      'Runner accepted your request.',
      'Runner is travelling to pickup location.',
      'Waiting for pickup confirmation.',
      'Delivery completed.',
    ];
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Progress',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 22),
            for (var i = 0; i < steps.length; i++)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor:
                            i <= current
                                ? const Color(0xFF102A43)
                                : Colors.white,
                        child:
                            i <= current
                                ? const Icon(
                                  Icons.check,
                                  size: 17,
                                  color: Colors.white,
                                )
                                : Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF9CA3AF),
                                      width: 2,
                                    ),
                                  ),
                                ),
                      ),
                      if (i < steps.length - 1)
                        Container(
                          width: 2,
                          height: 58,
                          color:
                              i < current
                                  ? const Color(0xFF102A43)
                                  : const Color(0xFFE5E7EB),
                        ),
                    ],
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            steps[i],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            descriptions[i],
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DeliverySummaryCard extends StatelessWidget {
  const _DeliverySummaryCard({required this.request});
  final RequestErrand request;
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Details',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          Text(
            request.title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _SummaryLine(label: 'Pickup', value: request.pickupLocation),
          _SummaryLine(label: 'Drop-off', value: request.dropoffLocation),
          _SummaryLine(label: 'Reward', value: request.formattedPrice),
        ],
      ),
    ),
  );
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

String _formatRelative(Timestamp timestamp) {
  final minutes = DateTime.now().difference(timestamp.toDate()).inMinutes;
  if (minutes < 1) return 'Just now';
  return '$minutes minutes ago';
}

class _RequestLocationBlock extends StatelessWidget {
  const _RequestLocationBlock({required this.request});

  final RequestErrand request;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _LocationLine(
            icon: Icons.radio_button_checked,
            label: 'Pickup',
            value: request.pickupLocation,
          ),
          const Padding(
            padding: EdgeInsets.only(left: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 14,
                child: VerticalDivider(
                  color: Color(0xFFD1D5DB),
                  thickness: 1.2,
                ),
              ),
            ),
          ),
          _LocationLine(
            icon: Icons.location_on_outlined,
            label: 'Drop-off',
            value: request.dropoffLocation,
          ),
        ],
      ),
    );
  }
}

class _LocationLine extends StatelessWidget {
  const _LocationLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF102A43), size: 20),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w800,
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? 'Not set' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status.toLowerCase()) {
      'completed' => const Color(0xFF047857),
      'cancelled' => const Color(0xFF991B1B),
      _ => const Color(0xFF102A43),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  const _PricePill({required this.price});

  final String price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        price,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EditRequestSheet extends StatefulWidget {
  const _EditRequestSheet({required this.request});

  final RequestErrand request;

  @override
  State<_EditRequestSheet> createState() => _EditRequestSheetState();
}

class _EditRequestSheetState extends State<_EditRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _pickupController;
  late final TextEditingController _dropoffController;
  late final TextEditingController _priceController;
  late String _category;
  late String _status;
  bool _isSaving = false;

  static const _categories = [
    'Delivery',
    'Groceries',
    'Documents',
    'Laundry',
    'Other',
  ];

  static const _statuses = ['Active', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.request.title);
    _descriptionController = TextEditingController(
      text: widget.request.description,
    );
    _pickupController = TextEditingController(
      text: widget.request.pickupLocation,
    );
    _dropoffController = TextEditingController(
      text: widget.request.dropoffLocation,
    );
    _priceController = TextEditingController(
      text: widget.request.price == 0 ? '' : widget.request.price.toString(),
    );
    _category =
        _categories.contains(widget.request.category)
            ? widget.request.category
            : 'Other';
    _status =
        _statuses.contains(widget.request.status)
            ? widget.request.status
            : 'Active';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final messenger = ScaffoldMessenger.of(context);
      await FirestoreRequestsRepository().updateRequest(widget.request.id, {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _category,
        'pickupLocation': _pickupController.text.trim(),
        'dropoffLocation': _dropoffController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'status': _status,
      });

      if (!mounted) return;
      Navigator.pop(context);
      _showRequestSnackBarWithMessenger(messenger, message: 'Request updated');
    } catch (error) {
      if (!mounted) return;
      _showRequestSnackBar(
        context,
        message: 'Could not update request',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update Request',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              _EditField(
                controller: _titleController,
                label: 'Title',
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Enter a title'
                            : null,
              ),
              const SizedBox(height: 12),
              _EditField(
                controller: _descriptionController,
                label: 'Description',
                validator:
                    (value) =>
                        value == null || value.trim().length < 10
                            ? 'Add at least 10 characters'
                            : null,
              ),
              const SizedBox(height: 12),
              _EditDropdown(
                label: 'Category',
                value: _category,
                items: _categories,
                onChanged: (value) => setState(() => _category = value),
              ),
              const SizedBox(height: 12),
              _EditField(
                controller: _pickupController,
                label: 'Pickup location',
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Enter pickup location'
                            : null,
              ),
              const SizedBox(height: 12),
              _EditField(
                controller: _dropoffController,
                label: 'Drop-off location',
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Enter drop-off location'
                            : null,
              ),
              const SizedBox(height: 12),
              _EditField(
                controller: _priceController,
                label: 'Runner pay',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final price = double.tryParse(value?.trim() ?? '');
                  if (price == null) return 'Enter a valid amount';
                  if (price <= 0) return 'Amount must be greater than zero';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _EditDropdown(
                label: 'Status',
                value: _status,
                items: _statuses,
                onChanged: (value) => setState(() => _status = value),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF102A43),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.controller,
    required this.label,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: _inputDecoration(label),
    );
  }
}

class _EditDropdown extends StatelessWidget {
  const _EditDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items:
          items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      decoration: _inputDecoration(label),
    );
  }
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF102A43), width: 1.3),
    ),
  );
}

Future<bool> _confirmDelete(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Delete request?'),
          content: const Text(
            'This request will be permanently removed from your errands.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF991B1B),
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
  );

  return result == true;
}

Future<bool> _confirmCancel(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Cancel Request'),
          content: const Text(
            'Are you sure you want to cancel this request? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep Request'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cancel Request'),
            ),
          ],
        ),
  );
  return result == true;
}

Future<void> _confirmDelivery(
  BuildContext context,
  RequestErrand request,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Confirm Delivery'),
          content: const Text(
            'Have you received your item successfully? Confirming delivery will complete this request.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Not Yet'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm Delivery'),
            ),
          ],
        ),
  );
  if (confirmed != true || !context.mounted) return;
  await FirestoreRequestsRepository().updateRequest(request.id, {
    'status': 'Completed',
  });
  if (!context.mounted) return;
  await _showRatingDialog(context, request);
}

Future<void> _showRatingDialog(
  BuildContext context,
  RequestErrand request,
) async {
  var selected = 0;
  final feedback = TextEditingController();
  await showDialog<void>(
    context: context,
    builder:
        (dialogContext) => StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: const Text('Rate Your Runner'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 1; i <= 5; i++)
                          IconButton(
                            onPressed: () => setState(() => selected = i),
                            icon: Icon(
                              i <= selected ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                            ),
                          ),
                      ],
                    ),
                    TextField(
                      controller: feedback,
                      maxLength: 200,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText:
                            'Share your experience with this runner (optional).',
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Skip'),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      if (context.mounted)
                        CustomToast.show(
                          context,
                          'Thank you for your feedback.',
                        );
                    },
                    child: const Text('Submit Rating'),
                  ),
                ],
              ),
        ),
  );
  feedback.dispose();
}

void _showEditRequestSheet(BuildContext context, RequestErrand request) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _EditRequestSheet(request: request),
  );
}

void _showRequestSnackBar(
  BuildContext context, {
  required String message,
  bool isError = false,
}) {
  _showRequestSnackBarWithMessenger(
    ScaffoldMessenger.of(context),
    message: message,
    isError: isError,
  );
}

void _showRequestSnackBarWithMessenger(
  ScaffoldMessengerState messenger, {
  required String message,
  bool isError = false,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isError ? const Color(0xFF991B1B) : const Color(0xFF102A43),
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
      ),
    );
}

class _SignedOutState extends StatelessWidget {
  const _SignedOutState();

  @override
  Widget build(BuildContext context) {
    return const _CenteredState(
      icon: Icons.lock_outline,
      title: 'Sign in required',
      message: 'Please sign in to view your requests.',
    );
  }
}

class _EmptyRequestsState extends StatelessWidget {
  const _EmptyRequestsState();

  @override
  Widget build(BuildContext context) {
    return const _CenteredState(
      icon: Icons.assignment_outlined,
      title: 'No requests yet',
      message: 'Your posted errands will appear here.',
    );
  }
}

class _RequestsErrorState extends StatelessWidget {
  const _RequestsErrorState();

  @override
  Widget build(BuildContext context) {
    return const _CenteredState(
      icon: Icons.cloud_off_outlined,
      title: 'Could not load requests',
      message: 'Please check your connection and try again.',
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

class _RequestsLoadingState extends StatelessWidget {
  const _RequestsLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, __) => const _RequestSkeletonCard(),
    );
  }
}

class _RequestSkeletonCard extends StatelessWidget {
  const _RequestSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
