import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  static const _background = Color(0xFFF3F4F6);
  static const _navy = Color(0xFF102A43);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: Text(
          'Help Center',
          style: GoogleFonts.archivoBlack(fontSize: 30),
        ),
        centerTitle: true,
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: _navy,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.support_agent_outlined, color: Colors.white, size: 34),
                const SizedBox(height: 14),
                Text(
                  'How can we help?',
                  style: GoogleFonts.archivoBlack(
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Find answers to common questions about using Errand.',
                  style: TextStyle(color: Color(0xFFD9E2EC), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _HelpSection(
            title: 'Frequently Asked Questions',
            children: const [
              _HelpItem(
                question: 'How do I post an errand?',
                answer: 'Open the menu, choose Post Errand, and provide the task details, locations, and runner pay.',
              ),
              _HelpItem(
                question: 'How do I become a runner?',
                answer: 'Open your profile, switch your role to Runner, then apply for verification from the home menu.',
              ),
              _HelpItem(
                question: 'What are floats used for?',
                answer: 'Runners use floats to accept errands. You can purchase them from the Buy Floats page.',
              ),
              _HelpItem(
                question: 'How do I update my account details?',
                answer: 'Open Profile and tap the information you want to change.',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(color: Color(0x0D111827), blurRadius: 10, offset: Offset(0, 3)),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.mail_outline, color: _navy),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Still need help? Contact the Errand support team.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  tooltip: 'Contact support',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _showContactDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Text('Please contact the Errand support team for assistance with your account or an active errand.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [BoxShadow(color: Color(0x0D111827), blurRadius: 10, offset: Offset(0, 3))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ...children,
      ],
    ),
  );
}

class _HelpItem extends StatelessWidget {
  const _HelpItem({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: Text(question, style: const TextStyle(fontWeight: FontWeight.w500)),
    iconColor: const Color(0xFF102A43),
    collapsedIconColor: const Color(0xFF6B7280),
    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
    children: [Text(answer, style: const TextStyle(color: Color(0xFF4B5563), height: 1.4))],
  );
}
