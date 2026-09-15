import 'package:errand/pages/Deliveries/my_deliveries.dart';
import 'package:errand/pages/Earnings/earnings_dashboard.dart';
import 'package:errand/pages/FindErrands/find_errands.dart';
import 'package:errand/pages/Floats/buy_floats.dart';
import 'package:errand/pages/Help/help_center.dart';
import 'package:errand/pages/Legal/terms_and_policy.dart';
import 'package:errand/pages/Login%20and%20Signup/login.dart';
import 'package:errand/pages/Login%20and%20Signup/verification.dart';
import 'package:errand/pages/Notifications/notifications.dart';
import 'package:errand/pages/Requests/my_requests.dart';
import 'package:errand/pages/Taskpage/post_task.dart';
import 'package:errand/pages/WhatsNew/whats_new.dart';
import 'package:errand/pages/profile/profile.dart';
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
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.2,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const Login(),
      routes: {
        '/postErrand': (context) => const PostTaskPage(),
        '/findErrands': (context) => const FindErrandsPage(),
        '/earnings': (context) => const EarningsDashboardPage(),
        '/buyFloats': (context) => const BuyFloatsPage(),
        '/myDeliveries': (context) => const MyDeliveriesPage(),
        '/myRequests': (context) => const MyRequestsPage(),
        '/whatsNew': (context) => const WhatsNewPage(),
        '/notifications': (context) => NotificationScreen(
          userId: FirebaseAuth.instance.currentUser!.uid,
        ),
        '/verification': (context) => const RunnerVerificationPage(),
        '/profile': (context) => const ProfilePage(),
        '/termsAndPolicy': (context) => const TermsAndPolicyPage(),
        '/helpCenter': (context) => const HelpCenterPage(),
      },
    );
  }
}
