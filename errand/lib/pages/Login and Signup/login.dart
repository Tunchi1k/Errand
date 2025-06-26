import 'package:errand/pages/Homepage/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // Import NavBar
import 'package:errand/pages/Login%20and%20Signup/signup.dart';
import 'package:errand/pages/Login%20and%20Signup/forgot_password.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController mailcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  bool isLoading = false; // Loading state for button feedback

  userLogin() async {
    setState(() {
      isLoading = true; // Show loading indicator
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: mailcontroller.text.trim(),
        password: passwordcontroller.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("Login Successful!", style: TextStyle(fontSize: 18.0)),
        ),
      );

      // ✅ Navigate to NavBar after login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = "No user found for this email.";
          break;
        case 'wrong-password':
          errorMessage = "Incorrect password. Please try again.";
          break;
        case 'invalid-email':
          errorMessage = "Invalid email format.";
          break;
        case 'user-disabled':
          errorMessage = "This account has been disabled.";
          break;
        case 'too-many-requests':
          errorMessage = "Too many attempts. Please try again later.";
          break;
        case 'network-request-failed':
          errorMessage = "Network error. Check your internet connection.";
          break;
        default:
          errorMessage = "An error occurred: ${e.message}";
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(errorMessage, style: const TextStyle(fontSize: 16.0)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Unexpected error: ${e.toString()}"),
        ),
      );
    } finally {
      setState(() {
        isLoading = false; // Hide loading indicator
      });
    }
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
              padding: const EdgeInsets.only(left: 65, top: 40),
              child: SizedBox(
                width: 290,
                height: 320,
                child: Image.asset("images/erand.png"),
              ),
            ),
            const SizedBox(height: 50.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Email",
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextField(
                    controller: mailcontroller,
                    decoration: const InputDecoration(
                      hintText: "enter email",
                      suffixIcon: Icon(Icons.email, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  const Text(
                    "Password",
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextField(
                    controller: passwordcontroller,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: "enter password",
                      suffixIcon: Icon(Icons.lock, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 35.0),
            Center(
              child: ElevatedButton(
                onPressed: isLoading ? null : userLogin, // Calls the function
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 63, 97),
                  minimumSize: const Size(250, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
                child:
                    isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          "Log in",
                          style: TextStyle(
                            fontSize: 17.0,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 20.0),
            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ForgotPassword(),
                    ),
                  );
                },
                child: const Text(
                  "Forgot Password?",
                  style: TextStyle(
                    color: Color.fromARGB(255, 36, 37, 39),
                    fontSize: 18.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account?",
                  style: TextStyle(
                    color: Color.fromARGB(255, 102, 108, 109),
                    fontSize: 18.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 5.0),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignUp()),
                    );
                  },
                  child: const Text(
                    "Signup",
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontSize: 18.0,
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
