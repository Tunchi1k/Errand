import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:errand/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'role': _nextRole,
        if (_nextRole == 'Runner') 'isVerified': false,
      });
      await NotificationService.sendNotification(
        userId: user.uid,
        title: 'Role Switch Successful',
        message: 'Your account role has been changed from ${widget.currentRole} to $_nextRole.',
        actionLabel: 'View Profile',
        destinationPage: 'profile',
        notificationType: 'role_switched',
      );
      if (!mounted) return;
      Navigator.pop(context, true);
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
          style: GoogleFonts.archivoBlack(fontSize: 30),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF6F8FB),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: const Color(0xFF102A43), borderRadius: BorderRadius.circular(24)),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 34),
              SizedBox(height: 14),
              Text('Choose how you use Errand', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              SizedBox(height: 6),
              Text('You can switch roles whenever your needs change.', style: TextStyle(color: Color(0xFFD9E2EC), height: 1.4)),
            ]),
          ),
          const SizedBox(height: 22),
          _RoleCard(label: 'Current Role', value: widget.currentRole),
          const SizedBox(height: 12),
          _RoleCard(label: 'Switch To', value: _nextRole),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.info_outline, color: Color(0xFF102A43)),
                const SizedBox(width: 12),
                Expanded(child: Text(
                _nextRole == 'Runner'
                    ? 'Switching to Runner allows you to accept and complete errands from other students. You will be able to earn floats by completing tasks.'
                    : 'Switching to Sender allows you to post errands and request help from other students.',
                style: const TextStyle(color: Color(0xFF4B5563), height: 1.5),
                )),
              ]),
            ),
          ),
          const Spacer(),
          SizedBox(width: double.infinity, child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF102A43),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _isSaving ? null : _confirmSwitch,
            child: Text(_isSaving ? 'Switching...' : 'Confirm Switch'),
          )),
          SizedBox(width: double.infinity, child: TextButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          )),
        ]),
      ),
    );
  }
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE8EEF5),
        child: Icon(value == 'Runner' ? Icons.local_shipping_outlined : Icons.person_outline, color: const Color(0xFF102A43)),
      ),
      title: Text(label, style: const TextStyle(color: Color(0xFF6B7280))),
      subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
    ),
  );
}
