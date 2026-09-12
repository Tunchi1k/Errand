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
import 'package:errand/widgets/app_loading_screen.dart';
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
      onGenerateRoute: (settings) {
        final builder = _routeBuilder(settings.name);
        if (builder == null) return null;
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => AppLoadingScreen(pageBuilder: builder),
        );
      },
    );
  }

  WidgetBuilder? _routeBuilder(String? name) {
    switch (name) {
      case '/postErrand':
        return (_) => const PostTaskPage();
      case '/findErrands':
        return (_) => const FindErrandsPage();
      case '/earnings':
        return (_) => const EarningsDashboardPage();
      case '/buyFloats':
        return (_) => const BuyFloatsPage();
      case '/myDeliveries':
        return (_) => const MyDeliveriesPage();
      case '/myRequests':
        return (_) => const MyRequestsPage();
      case '/whatsNew':
        return (_) => const WhatsNewPage();
      case '/notifications':
        return (_) =>
            NotificationScreen(userId: FirebaseAuth.instance.currentUser!.uid);
      case '/verification':
        return (_) => const RunnerVerificationPage();
      case '/profile':
        return (_) => const ProfilePage();
      case '/termsAndPolicy':
        return (_) => const TermsAndPolicyPage();
      case '/helpCenter':
        return (_) => const HelpCenterPage();
      default:
        return null;
    }
  }
}
