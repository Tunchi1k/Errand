import 'dart:ui';
import 'package:errand/pages/Login%20and%20Signup/login.dart';
import 'package:errand/pages/profile/profile.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageeState();
}

class _HomePageeState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int completedCount = 0;
  int activeCount = 0;
  double earnings = 0;
  int floatsCount = 0;
  String? username;
  String? role;
  bool isVerified = false;

  @override
  void initState() {
    super.initState();
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
      final errandsSnapshot =
          await FirebaseFirestore.instance.collection('errands').get();

      int completed = 0;
      int active = 0;
      double totalEarnings = 0.0;

      for (var doc in errandsSnapshot.docs) {
        final data = doc.data();
        final status = data['status'];
        final price = (data['price'] ?? 0).toDouble();

        if (status == 'Completed') {
          completed++;
          totalEarnings += price;
        } else if (status == 'Active') {
          active++;
        }
      }

      final user = FirebaseAuth.instance.currentUser;
      int floats = 0;
      if (user != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        floats = userDoc.data()?['floats'] ?? 0;
      }

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
      drawer: _buildDrawer(),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (_) => true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 90),
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
                          () => Navigator.pushNamed(context, '/history'),
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
                            Colors.teal,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            "Active",
                            "$activeCount",
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            "Floats",
                            "$floatsCount",
                            Colors.indigo,
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
                    const SizedBox(height: 10),
                    _buildActivity(
                      "Delivery to Dorm 4",
                      "Pending",
                      Icons.local_shipping,
                    ),
                    _buildActivity(
                      "Pick-up Laundry",
                      "Completed",
                      Icons.local_laundry_service,
                    ),
                    _buildActivity(
                      "Buy groceries",
                      "In Progress",
                      Icons.shopping_cart,
                    ),
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
                            "Welcome Back",
                            style: GoogleFonts.archivoBlack(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            username ?? "User",
                            style: GoogleFonts.archivoBlack(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
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

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 15, 59, 85),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(radius: 30, backgroundColor: Colors.white),
                  const SizedBox(height: 15),
                  Text(
                    username ?? "User",
                    style: GoogleFonts.archivoBlack(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isVerified ? "Verified" : "Not Verified",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8), // spacing between text and icon
                      Icon(
                        Icons.circle,
                        color: isVerified ? Colors.green : Colors.red,
                        size: 12, // you can adjust size as needed
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Iconsax.home4),
              title: Text('Home', style: GoogleFonts.archivo(fontSize: 16)),
              onTap: () => Navigator.pop(context),
            ),
            if (role == "Sender")
              ListTile(
                leading: const Icon(Icons.assignment),
                title: Text(
                  'My Requests',
                  style: GoogleFonts.archivo(fontSize: 18),
                ),
                onTap: () {},
              ),
            if (role == "Runner")
              ListTile(
                leading: const Icon(Icons.local_shipping_outlined),
                title: Text(
                  'My Deliveries',
                  style: GoogleFonts.archivo(fontSize: 16),
                ),
                onTap: () {},
              ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: Text('Wallet', style: GoogleFonts.archivo(fontSize: 16)),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Iconsax.user),
              title: Text('Profile', style: GoogleFonts.archivo(fontSize: 16)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.help_outline_outlined),
              title: Text(
                'Help Center',
                style: GoogleFonts.archivo(fontSize: 16),
              ),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.policy_outlined),
              title: Text(
                'Terms & Policy',
                style: GoogleFonts.archivo(fontSize: 16),
              ),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Iconsax.logout_14),
              title: Text('Logout', style: GoogleFonts.archivo(fontSize: 16)),
              onTap: () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text("Confirm Log out"),
                        content: const Text("Are you sure you want to logout?"),
                        actions: [
                          TextButton(
                            onPressed:
                                () => Navigator.pop(context, false), // stay
                            child: const Text("No"),
                          ),
                          TextButton(
                            onPressed:
                                () => Navigator.pop(context, true), // proceed
                            child: const Text("Yes"),
                          ),
                        ],
                      ),
                );

                if (shouldLogout == true) {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Login()),
                    );
                  }
                }
              },
            ),
            if (role == "Runner" && !isVerified)
              ListTile(
                leading: const Icon(
                  Icons.verified_outlined,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
                title: Text(
                  "Apply For Verification",
                  style: GoogleFonts.archivo(fontSize: 16),
                ),
                onTap: () {},
              ),
          ],
        ),
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

  Widget _buildActivity(String title, String status, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.black54),
        title: Text(title),
        subtitle: Text(status),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
