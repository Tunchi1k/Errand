import 'package:errand/pages/Homepage/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // Import NavBar
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:errand/pages/Login%20and%20Signup/signup.dart';
import 'package:errand/pages/Login%20and%20Signup/forgot_password.dart';
import 'package:errand/services/custom_toast.dart';
import 'package:errand/utils/responsive.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController mailcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  bool isLoading = false; // Loading state for button feedback
  bool _showPassword = false;

  userLogin() async {
    setState(() {
      isLoading = true; // Show loading indicator
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: mailcontroller.text.trim(),
        password: passwordcontroller.text,
      );

      CustomToast.show(context, 'Login successful!');

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
          errorMessage = "${e.message}";
          break;
      }

      CustomToast.show(context, errorMessage);
    } catch (e) {
      CustomToast.show(context, 'Unexpected error: ${e.toString()}');
    } finally {
      setState(() {
        isLoading = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.horizontalPadding(context);
    final logoWidth = Responsive.width(context, 250).clamp(140.0, 250.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.contentMaxWidth(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.paddingOf(context).top + 48),
                Center(
                  child: Image.asset(
                    'images/logo.png',
                    width: logoWidth,
                    height: 140,
                    fit: BoxFit.contain,
                  ),
                ),
             
                const SizedBox(height: 85.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Email",
                        style: GoogleFonts.archivoBlack(fontSize: 15),
                      ),
                      TextField(
                        controller: mailcontroller,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                          hintText: "Enter email",
                          suffixIcon: const Icon(
                            Iconsax.sms,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14.0),
                      Text(
                        "Password",
                        style: GoogleFonts.archivoBlack(fontSize: 15),
                      ),
                      TextField(
                        controller: passwordcontroller,
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                          hintText: "Enter password",
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword ? Iconsax.eye : Iconsax.eye_slash,
                              color: Colors.black,
                            ),
                            onPressed:
                                () => setState(
                                  () => _showPassword = !_showPassword,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60.0),
                Center(
                  child: ElevatedButton(
                    onPressed:
                        isLoading ? null : userLogin, // Calls the function
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 0, 63, 97),
                      minimumSize: const Size(170, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    child:
                        isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              "Log in",
                              style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 255, 255, 255),
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 14.0),
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
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?",
                      style: TextStyle(
                        color: Color.fromARGB(255, 102, 108, 109),
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 5.0),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUp(),
                          ),
                        );
                      },
                      child: const Text(
                        "Signup",
                        style: TextStyle(
                          color: Color.fromARGB(255, 0, 0, 0),
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
