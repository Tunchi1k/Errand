import 'package:errand/pages/Login%20and%20Signup/login.dart';
import 'package:errand/pages/Notifications/notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await Supabase.initialize(
    url: 'https://rfqnervrhxzackrmuoec.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJmcW5lcnZyaHh6YWNrcm11b2VjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAxODUyMzAsImV4cCI6MjA2NTc2MTIzMH0.NywMytTREcK2onPcAY53tUDS0tvulCK0eeuRKXMXbNg',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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
