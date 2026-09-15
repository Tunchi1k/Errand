import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:errand/pages/Homepage/home.dart';
import 'package:errand/services/notification_service.dart';

class RoleSwitchPage extends StatefulWidget {
  const RoleSwitchPage({required this.currentRole, super.key});
  final String currentRole;

  @override
  State<RoleSwitchPage> createState() => _RoleSwitchPageState();
}

class _RoleSwitchPageState extends State<RoleSwitchPage> {
  bool _isSaving = false;

  String get _nextRole => widget.currentRole == 'Runner' ? 'Sender' : 'Runner';

  Future<void> _confirmSwitch() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(user.uid);

      if (widget.currentRole == 'Runner' && _nextRole == 'Sender') {
        final activeDeliveries =
            await firestore
                .collection('errands')
                .where('runnerId', isEqualTo: user.uid)
                .where('status', whereIn: ['Accepted', 'In Progress'])
                .limit(1)
                .get();
        if (activeDeliveries.docs.isNotEmpty) {
          throw const _ActiveDeliveryException();
        }
      }

      await userRef.set({
        'activeRole': _nextRole,
        'roles': {'sender': true, 'runner': true},
      }, SetOptions(merge: true));

      // Create the notification only after the role change succeeds.
      try {
        await NotificationService.sendNotification(
          userId: user.uid,
          title: 'Role switched',
          message: 'Your active role is now $_nextRole.',
          actionLabel: 'Open Home',
          destinationPage: 'home',
          notificationType: 'role_switched',
        );
      } catch (error) {
        // A notification failure should not undo a successful role switch.
        debugPrint('Role switch notification failed: $error');
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const _RoleHomeRedirect()),
        (route) => false,
      );
    } on _ActiveDeliveryException {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "You're currently completing an errand. Finish or cancel your active delivery before switching roles.",
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not switch your account role.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: Text(
          'Switch Role',
          style: GoogleFonts.archivoBlack(fontSize: 22),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: const Color(0xFFF6F8FB),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF102A43),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.swap_horiz_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Choose how you use Errand',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'You can switch roles whenever your needs change.',
                      style: TextStyle(color: Color(0xFFD9E2EC), height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _RoleCard(label: 'Current Role', value: widget.currentRole),
              const SizedBox(height: 12),
              _RoleCard(label: 'Switch To', value: _nextRole),
              const SizedBox(height: 14),
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF102A43)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _nextRole == 'Runner'
                              ? 'Switching to Runner allows you to accept and complete errands from other students. You will be able to earn floats by completing tasks.'
                              : 'Switching to Sender allows you to post errands and request help from other students.',
                          style: const TextStyle(
                            color: Color(0xFF4B5563),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF102A43),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isSaving ? null : _confirmSwitch,
                  child: Text(_isSaving ? 'Switching...' : 'Confirm Switch'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveDeliveryException implements Exception {
  const _ActiveDeliveryException();
}

class _RoleHomeRedirect extends StatelessWidget {
  const _RoleHomeRedirect();

  @override
  Widget build(BuildContext context) => const HomePage();
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE8EEF5),
        child: Icon(
          value == 'Runner'
              ? Icons.local_shipping_outlined
              : Icons.person_outline,
          color: const Color(0xFF102A43),
        ),
      ),
      title: Text(label, style: const TextStyle(color: Color(0xFF6B7280))),
      subtitle: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
    ),
  );
}
