import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class WhatsNewPage extends StatefulWidget {
  const WhatsNewPage({super.key});
  @override
  State<WhatsNewPage> createState() => _WhatsNewPageState();
}

class _WhatsNewPageState extends State<WhatsNewPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _appear(double start, Widget child) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, .08),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8FAFC),
    appBar: AppBar(
      title: Text("What's New", style: GoogleFonts.archivoBlack(fontSize: 30)),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () => Navigator.pop(context),
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        _appear(0, _header()),
        const SizedBox(height: 22),
        _appear(.08, _featured(context)),
        const SizedBox(height: 28),
        _heading('New for You'),
        const SizedBox(height: 12),
        _appear(.22, _newForYou(context)),
        const SizedBox(height: 28),
        _heading('Coming Soon'),
        const SizedBox(height: 12),
        _appear(.42, _comingSoon()),
        const SizedBox(height: 18),
        _heading('Did You Know?'),
        const SizedBox(height: 12),
        _appear(.62, _tips()),
      ],
    ),
  );

  Widget _header() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Discover the latest improvements and what's coming to Errand.",
        style: TextStyle(color: Color(0xFF4B5563), fontSize: 16, height: 1.4),
      ),
      const SizedBox(height: 8),
      const Text(
        'v1.0.0 · September 2026',
        style: TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );

  Widget _featured(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(26),
    child: Material(
      color: const Color(0xFF102A43),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/myRequests'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 165,
              width: double.infinity,
              child: Image.asset('images/whats_new.png', fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _status('NEW'),
                  const SizedBox(height: 10),
                  Text(
                    'Track Your Errand',
                    style: GoogleFonts.archivoBlack(
                      color: Colors.white,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Stay updated from the moment your errand is accepted until it's completed.",
                    style: TextStyle(color: Color(0xFFD9E2EC), height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'See it in action  →',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _newForYou(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: _appear(.28, _feature(
          context,
          Iconsax.notification,
          'Notifications',
          'Stay updated when your errand changes status.',
          'Explore',
          '/notifications',
        )),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _appear(.36, _feature(
          context,
          Iconsax.receipt_item,
          'My Requests',
          "Follow the errands you've posted.",
          'View',
          '/myRequests',
        )),
      ),
    ],
  );

  Widget _feature(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    String action,
    String route,
  ) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        constraints: const BoxConstraints(minHeight: 185),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF7658FF), size: 25),
          const SizedBox(height: 34),
            Text(title, style: GoogleFonts.archivoBlack(fontSize: 16)),
            const SizedBox(height: 6),
            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF6B7280), height: 1.3),
            ),
            const SizedBox(height: 12),
            Text(
              '$action  →',
              style: const TextStyle(
                color: Color(0xFF102A43),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _comingSoon() {
    const data = [
      (
        'Live Location Tracking',
        'See where your runner is while your errand is being completed.',
        Iconsax.location,
      ),
      (
        'Smarter Errand Matching',
        'Get your errand matched with the right runner faster.',
        Iconsax.magicpen,
      ),
      (
        'More Payment Options',
        'More convenient ways to pay for your errands.',
        Iconsax.wallet_3,
      ),
    ];
    return Column(
      children:
          data
              .map(
                (item) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD7E8F7)),
                  ),
                  child: Row(
                    children: [
                      Icon(item.$3, color: const Color(0xFF2563EB), size: 25),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$1,
                              style: GoogleFonts.archivoBlack(fontSize: 16),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item.$2,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _status(
                              'COMING SOON',
                              color: const Color(0xFF2563EB),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _tips() {
    const tips = [
      'You can post an errand and continue with your day while a runner handles it.',
      'You can track the progress of active requests from My Requests.',
      'Complete your profile to help other students recognize you.',
    ];
    return Column(
      children:
          tips
              .map(
                (tip) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Iconsax.lamp_charge,
                        color: Color(0xFFF59E0B),
                        size: 21,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tip,
                          style: const TextStyle(
                            color: Color(0xFF4B5563),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _heading(String text) => Text(
    text.toUpperCase(),
    style: GoogleFonts.archivoBlack(
      fontSize: 15,
      letterSpacing: .4,
      color: const Color(0xFF102A43),
    ),
  );

  Widget _status(String text, {Color color = const Color(0xFF7C3AED)}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(.16),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: .5,
          ),
        ),
      );
}
