import 'dart:ui';
import 'package:errand/pages/FindErrands/errand_repository.dart';
import 'package:errand/pages/Homepage/homepage_drawer.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  String? username;
  String? role;
  bool isVerified = false;
  Stream<List<Errand>>? _activeErrandsStream;

  @override
  void initState() {
    super.initState();
    _activeErrandsStream = _errandRepository.watchAvailableErrands();
    fetchUsername();
    fetchStats();
    sendWelcomeNotificationIfNeeded();
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
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': user.uid,
          'title': 'Welcome to Errand!',
          'message': 'We’re excited to have you on board 🎉',
          'timestamp': Timestamp.fromDate(DateTime.now()),
          'isRead': false,
        });

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

  Future<void> fetchStats() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      int floats = 0;
      Map<String, dynamic> stats = {};
      if (user != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        floats = userDoc.data()?['floats'] ?? 0;
        stats = userDoc.data() ?? {};
      }

      final completed = stats['completed'] ?? 0;
      final active = stats['active'] ?? 0;
      final totalEarnings = (stats['totalEarnings'] ?? 0).toDouble();

      setState(() {
        completedCount = completed;
        activeCount = active;
        earnings = totalEarnings;
        floatsCount = floats;
      });
    } catch (e) {
      debugPrint('Error fetching stats: $e');
    }
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
      backgroundColor: const Color.fromARGB(255, 243, 243, 243),
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
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 12,
                      padding: const EdgeInsets.only(top: 20),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildImageQuickAction(
                          'images/posterrand.png',
                          "",
                          () => Navigator.pushNamed(context, '/postErrand'),
                        ),
                        _buildImageQuickAction(
                          'images/finderrand.png',
                          "",
                          () => Navigator.pushNamed(context, '/findErrands'),
                        ),
                        _buildImageQuickAction(
                          'images/earnings.png',
                          "",
                          () => Navigator.pushNamed(context, '/earnings'),
                        ),
                        _buildImageQuickAction(
                          'images/buy.png',
                          "",
                          () => Navigator.pushNamed(context, '/buyFloats'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Text(
                      "Dashboard",
                      style: GoogleFonts.archivoBlack(
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
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
                    ),
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
                            "errand.",
                            style: GoogleFonts.archivoBlack(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF111827),
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
