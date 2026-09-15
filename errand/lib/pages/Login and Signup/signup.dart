import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:errand/pages/Login%20and%20Signup/role.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:errand/pages/Login%20and%20Signup/login.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:errand/services/custom_toast.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool _showPassword = false;

  bool isValidEmail(String email) {
    return RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email);
  }

  Future<void> registerUser() async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      showSnackBar("All fields are required!", Colors.orange);
      return;
    }

    if (!isValidEmail(email)) {
      showSnackBar("Enter a valid email address!", Colors.orange);
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      await _firestore.collection("users").doc(userCredential.user!.uid).set({
        "name": name,
        "email": email,
        "createdAt": FieldValue.serverTimestamp(),
        "role": null,
        "isVerified": false,
        "floatBalance": 0,
      });

      showSnackBar(
        "Registered Successfully!",
        const Color.fromARGB(255, 66, 183, 70),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => RoleSelectionPage(
                uid: userCredential.user!.uid,
                name: name,
                email: email,
              ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      handleFirebaseAuthError(e);
    } catch (e) {
      showSnackBar("Unexpected error: \${e.toString()}", Colors.red);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void showSnackBar(String message, Color color) {
    CustomToast.show(context, message, color: color.withValues(alpha: .8));
  }

  void handleFirebaseAuthError(FirebaseAuthException e) {
    String errorMessage;
    switch (e.code) {
      case "weak-password":
        errorMessage = "Password is too weak. Use a stronger password.";
        break;
      case "email-already-in-use":
        errorMessage = "An account with this email already exists.";
        break;
      case "invalid-email":
        errorMessage = "The email address is not valid.";
        break;
      case "operation-not-allowed":
        errorMessage = "Email/password accounts are disabled.";
        break;
      case "network-request-failed":
        errorMessage = "Please check your internet connection.";
        break;
      case "too-many-requests":
        errorMessage = "Too many attempts. Try again later.";
        break;
      default:
        errorMessage = "An error occurred: \${e.message}";
        break;
    }
    showSnackBar(errorMessage, Colors.red);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: SizedBox(
                  width: 300,
                  height: 205,
                  child: Image.asset("images/Signup.png"),
                ),
              ),
            ),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Full Name",
                    style: GoogleFonts.archivoBlack(fontSize: 15),
                  ),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: "Enter full name",
                      suffixIcon: const Icon(Iconsax.user, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text("Email", style: GoogleFonts.archivoBlack(fontSize: 15)),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      hintText: "Enter email",
                      suffixIcon: const Icon(Iconsax.sms, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Password",
                    style: GoogleFonts.archivoBlack(fontSize: 15),
                  ),
                  TextField(
                    controller: passwordController,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      hintText: "Enter password",
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword ? Iconsax.eye : Iconsax.eye_slash,
                          color: Colors.black,
                        ),
                        onPressed:
                            () =>
                                setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
            Center(
              child: GestureDetector(
                onTap: isLoading ? null : registerUser,
                child: Container(
                  height: 42,
                  width: 170,
                  decoration: BoxDecoration(
                    color:
                        isLoading
                            ? Colors.blueGrey
                            : const Color.fromARGB(255, 0, 63, 97),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white, width: 1.0),
                  ),
                  child: Center(
                    child:
                        isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              "Sign up",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Already have an account?",
                  style: TextStyle(
                    color: Color(0xFF8c8e98),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 5),
                GestureDetector(
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Login()),
                      ),
                  child: const Text(
                    "Login",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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
