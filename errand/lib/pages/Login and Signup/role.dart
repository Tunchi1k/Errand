import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:errand/pages/Homepage/homee.dart';
import 'package:errand/pages/Login%20and%20Signup/verification.dart';
import 'package:flutter/material.dart';
import 'signup.dart';

class RoleSelectionPage extends StatefulWidget {
  final String uid;
  final String name;
  final String email;

  const RoleSelectionPage({
    super.key,
    required this.uid,
    required this.name,
    required this.email,
  });

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  bool isRunnerLoading = false;
  bool isSenderLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SignUp()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 65, top: 0.2),
              child: SizedBox(
                width: 290,
                height: 300,
                child: Image.asset("images/role.png"),
              ),
            ),
            const SizedBox(height: 10.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                children: [
                  _buildRoleCard(
                    title: "Runner",
                    description:
                        "Earn money by completing errands posted by others.",
                    backgroundColor: const Color.fromARGB(255, 0, 63, 97),
                    textColor: const Color.fromARGB(255, 255, 255, 255),
                    isLoading: isRunnerLoading,
                    onTap: () async {
                      setState(() => isRunnerLoading = true);
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.uid)
                          .set({
                            'name': widget.name,
                            'email': widget.email,
                            'role': 'Runner',
                            'uid': widget.uid,
                          }, SetOptions(merge: true));
                      await Future.delayed(const Duration(milliseconds: 500));
                      setState(() => isRunnerLoading = false);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RunnerVerificationPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  _buildRoleCard(
                    title: "Sender",
                    description:
                        "Post errands you need done and pay runners to complete them for you",
                    backgroundColor: const Color.fromARGB(255, 0, 195, 255),
                    textColor: const Color.fromARGB(255, 255, 255, 255),
                    isLoading: isSenderLoading,
                    onTap: () async {
                      setState(() => isSenderLoading = true);
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.uid)
                          .set({
                            'name': widget.name,
                            'email': widget.email,
                            'role': 'Sender',
                            'uid': widget.uid,
                          }, SetOptions(merge: true));
                      await Future.delayed(const Duration(milliseconds: 500));
                      setState(() => isSenderLoading = false);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => HomePagee()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String description,
    required Color backgroundColor,
    required Color textColor,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform:
            isLoading ? Matrix4.translationValues(0, 2, 0) : Matrix4.identity(),
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 4,
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: textColor.withOpacity(0.8)),
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
