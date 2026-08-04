import 'package:errand/pages/Deliveries/my_deliveries.dart';
import 'package:errand/pages/Homepage/home.dart';
import 'package:errand/pages/Earnings/earnings_dashboard.dart';
import 'package:errand/pages/FindErrands/find_errands.dart';
import 'package:errand/pages/Floats/buy_floats.dart';
import 'package:errand/pages/Login%20and%20Signup/verification.dart';
import 'package:errand/pages/Notifications/notifications.dart';
import 'package:errand/pages/Requests/my_requests.dart';
import 'package:errand/pages/Taskpage/post_task.dart';
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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomePage(),
      routes: {
        '/postErrand': (context) => const PostTaskPage(),
        '/findErrands': (context) => const FindErrandsPage(),
        '/earnings': (context) => const EarningsDashboardPage(),
        '/buyFloats': (context) => const BuyFloatsPage(),
        '/myDeliveries': (context) => const MyDeliveriesPage(),
        '/myRequests': (context) => const MyRequestsPage(),
        '/notifications':
            (context) => NotificationScreen(
              userId: FirebaseAuth.instance.currentUser!.uid,
            ),
        '/verification': (context) => const RunnerVerificationPage(),
      },
    );
  }
}
