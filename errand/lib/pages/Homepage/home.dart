import 'dart:async';
import 'dart:ui';
import 'package:errand/pages/FindErrands/errand_repository.dart';
import 'package:errand/pages/Homepage/homepage_drawer.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:errand/services/notification_service.dart';
import 'package:errand/services/custom_toast.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageeState();
}

class _HomePageeState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ErrandRepository _errandRepository = const FirestoreErrandRepository();

  int completedCount = 0;
  int activeCount = 0;
  double earnings = 0;
  int floatsCount = 0;
  int activeRequestsCount = 0;
  int completedDeliveriesCount = 0;
  double totalSpent = 0;
  String? username;
  String? role;
  bool isVerified = false;
  Stream<List<Errand>>? _activeErrandsStream;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _userStatsSubscription;

  @override
  void initState() {
    super.initState();
    _activeErrandsStream = _errandRepository.watchAvailableErrands();
    fetchUsername();
    _listenToStats();
    sendWelcomeNotificationIfNeeded();
  }

  @override
  void dispose() {
    _userStatsSubscription?.cancel();
    super.dispose();
  }

  Future<void> sendWelcomeNotificationIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    try {
      final userDoc = await userDocRef.get();
      final hasReceivedWelcome = userDoc.data()?['hasReceivedWelcome'] ?? false;

      if (!hasReceivedWelcome) {
        await NotificationService.sendNotification(
          userId: user.uid,
          title: 'Welcome to Errand!',
          message: 'Hey there! Welcome to Errand!\n\n'
              'You’re officially part of a community where students help each other get things done faster, easier, and smarter.\n\n'
              'Before you jump in, let’s get your profile looking great.\n\n'
              'Add your:\n- Profile photo\n- Phone number\n- Personal details\n\n'
              'A complete profile helps other students know who they’re working with and makes it easier to build trust.\n\n'
              'Once you’re ready, you can start posting errands, accepting deliveries, earning rewards, and being part of the Errand community.\n\n'
              'Let’s set up your profile and get you started!',
          actionLabel: 'Complete Profile',
          destinationPage: 'profile',
          notificationType: 'welcome',
        );

        await userDocRef.update({'hasReceivedWelcome': true});
      }
    } catch (e) {
      debugPrint('Error sending welcome notification: $e');
    }
  }

  void fetchUsername() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot<Map<String, dynamic>> userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        final data = userDoc.data() ?? {};
        if (!mounted) return;
        setState(() {
          username =
              data['name']?.toString() ??
              user.displayName ??
              user.email ??
              "User";
          role = data['role']?.toString();
          isVerified = data['verified'] == true;
        });
      } catch (e) {
        print("Error fetching username: $e");
      }
    }
  }

  void _listenToStats() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _userStatsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
          (userDoc) {
            final stats = userDoc.data() ?? {};
            if (!mounted) return;
            setState(() {
              completedCount = stats['completed'] ?? 0;
              activeCount = stats['active'] ?? 0;
              earnings = (stats['totalEarnings'] ?? 0).toDouble();
              floatsCount = stats['floats'] ?? 0;
              // TODO: activeRequests/completedDeliveries/totalSpent aren't
              // written anywhere yet (e.g. on errand post/complete) — wire
              // those up on the sender side, this just reads what's there.
              activeRequestsCount = stats['activeRequests'] ?? 0;
              completedDeliveriesCount = stats['completedDeliveries'] ?? 0;
              totalSpent = (stats['totalSpent'] ?? 0).toDouble();
            });
          },
          onError: (e) {
            debugPrint('Error listening to stats: $e');
          },
        );
  }

  Future<void> _openBuyFloats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!mounted) return;
    if (userDoc.data()?['role']?.toString() != 'Runner') {
      CustomToast.show(context, 'Runner Access Required\n\nFloats are only available for runner accounts. Switch to a runner account to purchase floats and start accepting errands.');
      return;
    }
    Navigator.pushNamed(context, '/buyFloats');
  }

  List<Widget> _quickActionTiles(BuildContext context) {
    final isRunner = role == 'Runner';

    if (isRunner) {
      return [
        _buildImageQuickAction(
          'images/finderrand.png',
          "",
          () => Navigator.pushNamed(context, '/findErrands'),
        ),
        // TODO: no dedicated photo asset for My Deliveries yet — icon tile
        // until one is designed, to match the other Quick Action tiles.
        _buildIconQuickAction(
          Icons.local_shipping_outlined,
          'My Deliveries',
          () => Navigator.pushNamed(context, '/myDeliveries'),
        ),
        _buildImageQuickAction(
          'images/earnings.png',
          "",
          () => Navigator.pushNamed(context, '/earnings'),
        ),
        _buildImageQuickAction('images/buy.png', "", _openBuyFloats),
      ];
    }

    // Default to the Sender layout while role is still null/loading.
    return [
      _buildImageQuickAction(
        'images/posterrand.png',
        "",
        () => Navigator.pushNamed(context, '/postErrand'),
      ),
      // TODO: no dedicated photo asset for My Requests yet — icon tile
      // until one is designed, to match the other Quick Action tiles.
      _buildIconQuickAction(
        Icons.assignment_outlined,
        'My Requests',
        () => Navigator.pushNamed(context, '/myRequests'),
      ),
      _buildImageQuickAction(
        'images/earnings.png',
        "",
        () => Navigator.pushNamed(context, '/earnings'),
      ),
    ];
  }

  Widget _buildQuickActionsGrid(List<Widget> tiles) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      final hasPair = i + 1 < tiles.length;
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 20 : 12),
          child: hasPair
              ? Row(
                  children: [
                    Expanded(
                      child: AspectRatio(aspectRatio: 1, child: tiles[i]),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AspectRatio(aspectRatio: 1, child: tiles[i + 1]),
                    ),
                  ],
                )
              // Odd tile out gets a wide banner row instead of a bare gap.
              : AspectRatio(aspectRatio: 2.3, child: tiles[i]),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildDashboardStats() {
    final isRunner = role == 'Runner';

    if (isRunner) {
      return Row(
        children: [
          Expanded(
            child: _buildStatCard(
              "Completed",
              "$completedCount",
              const Color(0xFF111827),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              "Active",
              "$activeCount",
              const Color(0xFF111827),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              "Floats",
              "$floatsCount",
              const Color(0xFF111827),
            ),
          ),
        ],
      );
    }

    // Default to Sender stats while role is still null/loading.
    final spentHasDecimals = totalSpent % 1 != 0;
    final formattedSpent =
        'K${totalSpent.toStringAsFixed(spentHasDecimals ? 2 : 0)}';

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            "Active Requests",
            "$activeRequestsCount",
            const Color(0xFF111827),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            "Completed Deliveries",
            "$completedDeliveriesCount",
            const Color(0xFF111827),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            "Total Spent",
            formattedSpent,
            const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: HomepageDrawer(
        username: username,
        role: role,
        isVerified: isVerified,
      ),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (_) => true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 100),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Quick Actions",
                      style: GoogleFonts.archivoBlack(
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    _buildQuickActionsGrid(_quickActionTiles(context)),
                    const SizedBox(height: 30),
                    Text(
                      "Dashboard",
                      style: GoogleFonts.archivoBlack(
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildDashboardStats(),
                    const SizedBox(height: 30),
                    Text(
                      "Recent Activities",
                      style: GoogleFonts.archivoBlack(
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildRecentActivities(),
                  ],
                ),
              ),
            ),
          ),

          //AppBar
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                height: 100,
                color: Colors.white.withOpacity(0.6),
                child: AppBar(
                  automaticallyImplyLeading: false,
                  backgroundColor: const Color.fromARGB(0, 255, 255, 255),
                  elevation: 0,
                  toolbarHeight: 80,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "errand",
                            style: GoogleFonts.archivoBlack(
                              fontSize: 30,
                              fontWeight: FontWeight.w500,
                              color: const Color.fromARGB(255, 122, 164, 255),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          StreamBuilder<QuerySnapshot>(
                            stream:
                                FirebaseFirestore.instance
                                    .collection('notifications')
                                    .where(
                                      'userId',
                                      isEqualTo:
                                          FirebaseAuth
                                              .instance
                                              .currentUser
                                              ?.uid,
                                    )
                                    .where('isRead', isEqualTo: false)
                                    .snapshots(),
                            builder: (context, snapshot) {
                              int unreadCount = 0;
                              if (snapshot.hasData) {
                                unreadCount = snapshot.data!.docs.length;
                              }

                              return Stack(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.notifications_none,
                                      color: Colors.black,
                                      size: 33,
                                    ),
                                    onPressed:
                                        () => Navigator.pushNamed(
                                          context,
                                          '/notifications',
                                        ),
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 20,
                                          minHeight: 20,
                                        ),
                                        child: Text(
                                          unreadCount.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.menu,
                              color: Colors.black,
                              size: 25,
                            ),
                            onPressed:
                                () => _scaffoldKey.currentState?.openDrawer(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageQuickAction(
    String imagePath,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildIconQuickAction(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // TODO: this currently shows all available errands regardless of role.
  // Eventually filter to "errands I accepted" for Runners vs "errands I
  // posted" for Senders.
  Widget _buildRecentActivities() {
    return StreamBuilder<List<Errand>>(
      stream: _activeErrandsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: const [
              _ActivitySkeletonCard(),
              _ActivitySkeletonCard(),
              _ActivitySkeletonCard(),
            ],
          );
        }

        if (snapshot.hasError) {
          return _buildActivity(
            "Could not load active errands",
            "Please check your connection and try again.",
            Icons.cloud_off_outlined,
          );
        }

        final errands = (snapshot.data ?? const <Errand>[]).take(4).toList();

        if (errands.isEmpty) {
          return _buildActivity(
            "No active errands",
            "New active errands from Find Errands will show here.",
            Icons.inventory_2_outlined,
          );
        }

        return Column(
          children:
              errands.map((errand) {
                final route =
                    errand.deliveryLocation.isEmpty
                        ? errand.pickupLocation
                        : "${errand.pickupLocation} -> ${errand.deliveryLocation}";

                return _buildActivity(
                  errand.title,
                  "Active | ${errand.reward} | $route | ${errand.postedAgo}",
                  Icons.assignment_outlined,
                  onTap: () => Navigator.pushNamed(context, '/findErrands'),
                );
              }).toList(),
        );
      },
    );
  }

  Widget _buildActivity(
    String title,
    String status,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return Card(
      color: const Color.fromARGB(210, 17, 24, 39),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color.fromARGB(133, 255, 255, 255)),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color.fromARGB(221, 255, 255, 255),
          ),
        ),
        subtitle: Text(
          status,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color.fromARGB(153, 255, 255, 255)),
        ),
        trailing:
            onTap == null
                ? null
                : const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
      ),
    );
  }
}

class _ActivitySkeletonCard extends StatelessWidget {
  const _ActivitySkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const ListTile(
        leading: CircleAvatar(backgroundColor: Color(0xFFE5E7EB)),
        title: _SkeletonLine(widthFactor: 0.65),
        subtitle: _SkeletonLine(widthFactor: 0.9),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: 12,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
