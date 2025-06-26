import 'package:errand/pages/Login%20and%20Signup/login.dart';

import 'package:errand/pages/Notifications/notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'errand',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const Login(),
      routes: {
        '/notifications':
            (context) => NotificationScreen(
              userId: FirebaseAuth.instance.currentUser!.uid,
            ),
      },
    );
  }
}
