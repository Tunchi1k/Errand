import 'dart:async';
import 'dart:ui';
import 'package:errand/pages/FindErrands/errand_repository.dart';
import 'package:errand/pages/Homepage/homepage_drawer.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
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
  int runnerActiveErrandsCount = 0;
  double earnings = 0;
  int floatsCount = 0;
  int activeRequestsCount = 0;
  int senderActiveErrandsCount = 0;
  int completedDeliveriesCount = 0;
  double totalSpent = 0;
  String? username;
  String? role;
  bool isVerified = false;
  int _senderNavigationIndex = 0;
  Stream<List<Errand>>? _activeErrandsStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _senderErrandsStream;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _userStatsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _senderActiveErrandsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _runnerActiveErrandsSubscription;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _activeErrandsStream = _errandRepository.watchAvailableErrands();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _setSenderErrandsStream(currentUser.uid);
    } else {
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
        user,
      ) {
        if (mounted && user != null && _senderErrandsStream == null) {
          setState(() => _setSenderErrandsStream(user.uid));
        }
      });
    }
    fetchUsername();
    _listenToStats();
    _listenToSenderActiveErrands();
    _listenToRunnerActiveErrands();
    sendWelcomeNotificationIfNeeded();
  }

  void _setSenderErrandsStream(String userId) {
    _senderErrandsStream =
        FirebaseFirestore.instance.collection('errands').snapshots();
  }

  @override
  void dispose() {
    _userStatsSubscription?.cancel();
    _senderActiveErrandsSubscription?.cancel();
    _runnerActiveErrandsSubscription?.cancel();
    _authSubscription?.cancel();
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
          message:
              'Hey there! Welcome to Errand!\n\n'
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
          role = data['activeRole']?.toString() ?? data['role']?.toString();
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

  void _listenToSenderActiveErrands() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _senderActiveErrandsSubscription = FirebaseFirestore.instance
        .collection('errands')
        .where('senderId', isEqualTo: user.uid)
        .where('status', whereIn: ['Active', 'Accepted', 'In Progress'])
        .snapshots()
        .listen(
          (snapshot) {
            if (!mounted) return;
            setState(() => senderActiveErrandsCount = snapshot.size);
          },
          onError: (e) {
            debugPrint('Error listening to sender active errands: $e');
          },
        );
  }

  void _listenToRunnerActiveErrands() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _runnerActiveErrandsSubscription = FirebaseFirestore.instance
        .collection('errands')
        .where('runnerId', isEqualTo: user.uid)
        .where('status', whereIn: ['Accepted', 'In Progress'])
        .snapshots()
        .listen(
          (snapshot) {
            if (!mounted) return;
            setState(() => runnerActiveErrandsCount = snapshot.size);
          },
          onError: (error) {
            debugPrint('Error listening to runner active errands: $error');
          },
        );
  }

  Future<void> _openBuyFloats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    if (!mounted) return;
    if (userDoc.data()?['role']?.toString() != 'Runner') {
      CustomToast.show(
        context,
        'Runner Access Required\n\nFloats are only available for runner accounts. Switch to a runner account to purchase floats and start accepting errands.',
      );
      return;
    }
    if (userDoc.data()?['verified'] != true) {
      CustomToast.show(
        context,
        'Verification Required\n\nYou must verify your runner account before purchasing floats.',
      );
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
          index: 0,
        ),
        _buildWhatsNewQuickAction(
          () => Navigator.pushNamed(context, '/whatsNew'),
          index: 1,
        ),
        _buildImageQuickAction(
          'images/earnings_homepage.png',
          "",
          () => Navigator.pushNamed(context, '/earnings'),
          index: 2,
        ),
        _buildImageQuickAction(
          'images/4.png',
          "",
          () => Navigator.pushNamed(context, '/myDeliveries'),
          index: 3,
        ),
        _buildImageQuickAction(
          'images/buy_floats.png',
          "",
          _openBuyFloats,
          index: 4,
        ),
      ];
    }

    // Default to the Sender layout while role is still null/loading.
    return [
      _buildWhatsNewQuickAction(
        () => Navigator.pushNamed(context, '/whatsNew'),
        index: 0,
      ),
      // TODO: no dedicated photo asset for My Requests yet — icon tile
      // until one is designed, to match the other Quick Action tiles.
      _buildImageQuickAction(
        'images/my_requests_homepage.png',
        '',
        () => Navigator.pushNamed(context, '/myRequests'),
        index: 1,
      ),
      _buildImageQuickAction(
        'images/posterrand.png',
        "",
        () => Navigator.pushNamed(context, '/postErrand'),
        index: 2,
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
          child:
              hasPair
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
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildStatCard(
                "Active",
                "$runnerActiveErrandsCount",
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
        ),
      );
    }

    // Default to Sender stats while role is still null/loading.
    final spentHasDecimals = totalSpent % 1 != 0;
    final formattedSpent =
        'K${totalSpent.toStringAsFixed(spentHasDecimals ? 2 : 0)}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
      ),
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
                padding: const EdgeInsets.fromLTRB(19, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greetingText,
                      style: GoogleFonts.archivoBlack(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.w100,
                      ),
                    ),
                    if ((role == 'Runner'
                            ? runnerActiveErrandsCount
                            : senderActiveErrandsCount) >
                        0) ...[
                      const SizedBox(height: 14),
                      Text(
                        '${role == 'Runner' ? runnerActiveErrandsCount : senderActiveErrandsCount} '
                        '${(role == 'Runner' ? runnerActiveErrandsCount : senderActiveErrandsCount) == 1 ? 'errand' : 'errands'} '
                        'in progress',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      "Quick Actions",
                      style: GoogleFonts.archivoBlack(
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    _buildQuickActionsGrid(_quickActionTiles(context)),
                    const SizedBox(height: 30),
                    if (role == 'Runner') ...[
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
                    ],
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
                            "errand.",
                            style: GoogleFonts.archivoBlack(
                              fontSize: 32,
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

  Widget _buildSenderBottomNavigation() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 0, 30, 22),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BottomAppBar(
          color: Colors.white,
          elevation: 10,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 62,
              child: Row(
                children: [
                  Expanded(
                    child: _senderNavItem(
                      icon: Iconsax.home_2,
                      label: 'Home',
                      selected: _senderNavigationIndex == 0,
                      onTap: () => setState(() => _senderNavigationIndex = 0),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap:
                          () => Navigator.pushNamed(
                            context,
                            role == 'Runner' ? '/findErrands' : '/postErrand',
                          ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Color(0xFF7658FF),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x557658FF),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              role == 'Runner'
                                  ? Iconsax.search_normal
                                  : Iconsax.add,
                              color: Colors.white,
                              size: 27,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: _senderNavItem(
                      icon: Iconsax.profile_circle,
                      label: 'Profile',
                      selected: _senderNavigationIndex == 2,
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _senderNavItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    const activeColor = Color(0xFF003F61);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        hoverColor: const Color(0x0D003F61),
        splashColor: const Color(0x1A003F61),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE8F3F8) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 23, color: selected ? activeColor : Colors.grey),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: selected ? activeColor : Colors.grey,
                  fontSize: 0,
                  height: 0,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _greetingText {
    final hour = DateTime.now().hour;
    final greeting =
        hour < 12
            ? 'Good morning'
            : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    final currentName = username?.trim() ?? '';
    if (currentName.isEmpty || currentName == 'User') return greeting;

    final firstName = currentName.split(RegExp(r'\s+')).first;
    return '$greeting, $firstName';
  }

  Widget _buildImageQuickAction(
    String imagePath,
    String label,
    VoidCallback onTap, {
    required int index,
  }) {
    return _AnimatedQuickAction(
      index: index,
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
    VoidCallback onTap, {
    required int index,
  }) {
    return _AnimatedQuickAction(
      index: index,
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

  Widget _buildWhatsNewQuickAction(VoidCallback onTap, {required int index}) {
    return _AnimatedQuickAction(
      index: index,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: const DecorationImage(
            image: AssetImage('images/whats_new.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(25),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
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

  Widget _buildRecentActivities() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _senderErrandsStream,
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
            "Could not load recent activity",
            "Please check your connection and try again.",
            Icons.cloud_off_outlined,
          );
        }

        final activities = <_SenderActivity>[];
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        for (final document in snapshot.data?.docs ?? const []) {
          final data = document.data();
          final ownerId =
              data['senderId']?.toString() ??
              data['userId']?.toString() ??
              data['postedBy']?.toString();
          if (currentUserId != null && ownerId == currentUserId) {
            activities.addAll(_activitiesForErrand(document));
          }
        }
        activities.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

        if (activities.isEmpty) {
          return _buildActivity(
            "No recent activity",
            "Your errand activity will appear here.",
            Icons.inventory_2_outlined,
          );
        }

        return Column(
          children:
              activities.take(4).map((activity) {
                return _buildActivity(
                  activity.title,
                  activity.message,
                  activity.icon,
                  onTap: () => Navigator.pushNamed(context, '/myRequests'),
                );
              }).toList(),
        );
      },
    );
  }

  List<_SenderActivity> _activitiesForErrand(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final title = data['title']?.toString() ?? 'Untitled Errand';
    final runnerName =
        data['runnerName']?.toString() ?? data['runnerDisplayName']?.toString();
    final fallbackTime = DateTime.fromMillisecondsSinceEpoch(0);
    final postedAt = _activityTime(data['createdAt']) ?? fallbackTime;
    final acceptedAt = _activityTime(data['acceptedAt']) ?? postedAt;
    final updatedAt = _activityTime(data['updatedAt']) ?? acceptedAt;
    final status = data['status']?.toString().toLowerCase() ?? '';
    final deliveryStatus =
        data['deliveryStatus']?.toString().toLowerCase() ?? '';
    final activities = <_SenderActivity>[
      _SenderActivity(
        title: 'Errand Posted',
        message: "You posted '$title'",
        icon: Icons.assignment_outlined,
        occurredAt: postedAt,
      ),
    ];

    final hasRunner = (data['runnerId']?.toString().isNotEmpty ?? false);
    if (hasRunner) {
      activities.add(
        _SenderActivity(
          title: 'Runner Accepted',
          message:
              '${runnerName ?? 'Your runner'} accepted your errand \'$title\'',
          icon: Icons.person_outline,
          occurredAt: acceptedAt,
        ),
      );
    }

    if (hasRunner && deliveryStatus == 'headingtopickup') {
      activities.add(
        _SenderActivity(
          title: 'Runner Heading to Pickup',
          message: 'Your runner is heading to the pickup location',
          icon: Icons.directions_run_outlined,
          occurredAt: updatedAt,
        ),
      );
    }

    final collected = [
      'itemcollected',
      'delivered',
      'completed',
    ].contains(deliveryStatus);
    if (collected) {
      activities.add(
        _SenderActivity(
          title: 'Item Collected',
          message:
              runnerName == null || runnerName.isEmpty
                  ? 'Your item has been collected'
                  : 'Your item has been collected by $runnerName',
          icon: Icons.inventory_2_outlined,
          occurredAt: updatedAt,
        ),
      );
    }

    final delivered =
        status == 'completed' ||
        ['delivered', 'completed'].contains(deliveryStatus);
    if (delivered) {
      activities.add(
        _SenderActivity(
          title: 'Errand Delivered',
          message: "'$title' has been delivered",
          icon: Icons.check_circle_outline,
          occurredAt: updatedAt,
        ),
      );
      if (data['senderRating'] == null || data['senderRating'] == 0) {
        activities.add(
          _SenderActivity(
            title: 'Rating Pending',
            message: 'Rate your experience with ${runnerName ?? 'your runner'}',
            icon: Icons.star_border,
            occurredAt: updatedAt.add(const Duration(microseconds: 1)),
          ),
        );
      }
    }
    return activities;
  }

  DateTime? _activityTime(dynamic value) {
    return value is Timestamp ? value.toDate() : null;
  }

  Widget _buildActivity(
    String title,
    String status,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return Card(
      color: const Color.fromARGB(255, 122, 164, 255),
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(35),
        side: BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        onTap: onTap,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.archivoBlack(fontSize: 16, color: Colors.white),
        ),
        subtitle: Text(
          status,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, height: 1.3),
        ),
        trailing:
            onTap == null
                ? null
                : const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.white,
                ),
      ),
    );
  }
}

class _SenderActivity {
  const _SenderActivity({
    required this.title,
    required this.message,
    required this.icon,
    required this.occurredAt,
  });

  final String title;
  final String message;
  final IconData icon;
  final DateTime occurredAt;
}

class _AnimatedQuickAction extends StatefulWidget {
  const _AnimatedQuickAction({
    required this.index,
    required this.onTap,
    required this.child,
  });

  final int index;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_AnimatedQuickAction> createState() => _AnimatedQuickActionState();
}

class _AnimatedQuickActionState extends State<_AnimatedQuickAction> {
  bool _isVisible = false;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: 90 * widget.index), () {
      if (mounted) setState(() => _isVisible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLifted = _isHovered || _isPressed;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedOpacity(
          opacity: _isVisible ? 1 : 0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          child: AnimatedSlide(
            offset: _isVisible ? Offset.zero : const Offset(0, 0.12),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            child: AnimatedScale(
              scale: isLifted ? 1.1 : 1,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: widget.child,
            ),
          ),
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
