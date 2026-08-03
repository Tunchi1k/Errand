import 'package:errand/pages/Login%20and%20Signup/login.dart';
import 'package:errand/pages/profile/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class HomepageDrawer extends StatelessWidget {
  const HomepageDrawer({
    super.key,
    required this.username,
    required this.role,
    required this.isVerified,
  });

  final String? username;
  final String? role;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF8FAFC),
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
          children: [
            _DrawerHeader(
              username: username,
              role: role,
              isVerified: isVerified,
            ),
            const SizedBox(height: 14),
            _DrawerItem(
              icon: Iconsax.home4,
              label: 'Home',
              onTap: () => Navigator.pop(context),
            ),
            _DrawerItem(
              icon: Icons.assignment_outlined,
              label: 'My Requests',
              onTap: () => Navigator.pushNamed(context, '/myRequests'),
            ),
            _DrawerItem(
              icon: Icons.local_shipping_outlined,
              label: 'My Deliveries',
              onTap: () => Navigator.pushNamed(context, '/myDeliveries'),
            ),
            _DrawerItem(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Wallet',
              onTap: () => Navigator.pushNamed(context, '/earnings'),
            ),
            _DrawerItem(
              icon: Iconsax.user,
              label: 'Profile',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
            ),
            const _DrawerDivider(),
            _DrawerItem(
              icon: Icons.help_outline_outlined,
              label: 'Help Center',
              onTap: () {},
            ),
            _DrawerItem(
              icon: Icons.policy_outlined,
              label: 'Terms & Policy',
              onTap: () {},
            ),
            _DrawerItem(
              icon: Iconsax.logout_14,
              label: 'Logout',
              isDestructive: true,
              onTap: () => _confirmLogout(context),
            ),
            if (role == "Runner" && !isVerified)
              _DrawerItem(
                icon: Icons.verified_outlined,
                label: 'Apply For Verification',
                onTap: () {},
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Confirm Log out"),
            content: const Text("Are you sure you want to logout?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("No"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Yes"),
              ),
            ],
          ),
    );

    if (shouldLogout != true) return;

    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.username,
    required this.role,
    required this.isVerified,
  });

  final String? username;
  final String? role;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final displayName =
        username?.trim().isNotEmpty == true ? username! : 'User';
    final initial = displayName.characters.first.toUpperCase();
    final showVerification = role == 'Runner';

    return Container(
      height: 178,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: GoogleFonts.archivoBlack(
                color: Colors.white,
                fontSize: 22,
              ),
            ),
          ),
          const Spacer(),
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.archivoBlack(color: Colors.white, fontSize: 20),
          ),
          if (showVerification) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isVerified ? Icons.verified_rounded : Icons.info_outline,
                    color:
                        isVerified
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFFFCA5A5),
                    size: 16,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    isVerified ? 'Verified' : 'Not Verified',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color =
        isDestructive ? const Color(0xFF991B1B) : const Color(0xFF111827);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color:
                        isDestructive
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: color, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.archivo(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDestructive ? color : const Color(0xFF9CA3AF),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerDivider extends StatelessWidget {
  const _DrawerDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Divider(height: 1, color: Color(0xFFE5E7EB)),
    );
  }
}
