import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:errand/pages/Taskpage/post_task.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:errand/pages/Homepage/appbar.dart';
import 'package:errand/pages/Homepage/curved_edges.dart';
import 'package:iconsax/iconsax.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? username;
  int _currentIndex = 0;

  final List<String> imagePaths = [
    "images/grocery.jpeg",
    "images/package.jpeg",
    "images/document.jpeg",
  ];

  @override
  void initState() {
    super.initState();
    fetchUsername();
  }

  void fetchUsername() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        setState(() {
          username = userDoc['name'];
        });
      } catch (e) {
        print("Error fetching username: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            ClipPath(
              clipper: TcustomCurvedEdges(),
              child: Container(
                color: const Color.fromARGB(255, 0, 63, 97),
                padding: const EdgeInsets.all(0),
                child: Stack(
                  children: [
                    Container(
                      width: 500,
                      height: 190,
                      padding: const EdgeInsets.all(0),
                      child: Column(
                        children: [
                          CAppBar(
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Welcome back",
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 120, 119, 119),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  username ?? "User",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(
                                  Iconsax.notification,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Section Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "errands",
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w500),
                ),
              ),
            ),

            // Carousel Slider with Modern Indicators
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  CarouselSlider(
                    items:
                        imagePaths
                            .map((imagePath) => _buildImage(imagePath))
                            .toList(),
                    options: CarouselOptions(
                      height: 200,
                      autoPlay: true,
                      autoPlayInterval: Duration(seconds: 5),
                      enlargeCenterPage: true,
                      viewportFraction: 1.0,
                      aspectRatio: 16 / 9,
                      onPageChanged: (index, reason) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                    ),
                  ),

                  // Modern Indicator Bars
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:
                          imagePaths.asMap().entries.map((entry) {
                            int index = entry.key;
                            return AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              width: _currentIndex == index ? 30 : 10,
                              height: 5,
                              margin: EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color:
                                    _currentIndex == index
                                        ? Colors.blue
                                        : Colors.grey.withOpacity(0.5),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Categories",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
              ),
            ),

            SizedBox(height: 20),

            // Category Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCategoryButton(Iconsax.shop, "Grocery Shopping"),
                  _buildCategoryButton(Iconsax.document, "Document Pickup"),
                  _buildCategoryButton(Iconsax.box, "Package Delivery"),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Post Errand Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 120),
              child: SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    // Replace this with the page you want to navigate to
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PostTaskPage()),
                    );
                  },
                  child: ElevatedButton(
                    onPressed:
                        () {}, // You can leave this empty or handle the press as needed
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 0, 63, 97),
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: Text(
                      "Post Errand",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Helper function to create images with border radius
  Widget _buildImage(String imagePath) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.asset(imagePath, fit: BoxFit.cover, width: double.infinity),
    );
  }

  /// Helper function to build category buttons
  Widget _buildCategoryButton(IconData icon, String label) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 30,
              color: const Color.fromARGB(255, 0, 0, 0),
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
