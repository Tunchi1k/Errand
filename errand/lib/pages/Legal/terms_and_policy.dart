import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsAndPolicyPage extends StatefulWidget {
  const TermsAndPolicyPage({super.key});

  @override
  State<TermsAndPolicyPage> createState() => _TermsAndPolicyPageState();
}

class _TermsAndPolicyPageState extends State<TermsAndPolicyPage>
    with SingleTickerProviderStateMixin {
  static const _surfaceGrey = Color(0xFFF1F3F5);
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Terms & Policy',
          style: GoogleFonts.archivoBlack(fontSize: 30),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: _surfaceGrey,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: const Color(0xFF111827),
          fontWeight: FontWeight.w800,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF9FAFB), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Material(
                color: _surfaceGrey,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _surfaceGrey,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF6B7280),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w900),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                    indicator: BoxDecoration(
                      color: const Color(0xFF102A43),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tabs: const [
                      Tab(text: 'Terms of Service'),
                      Tab(text: 'Privacy Policy'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    _LegalDocument(sections: _termsSections),
                    _LegalDocument(sections: _privacySections),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalDocument extends StatelessWidget {
  const _LegalDocument({required this.sections});

  final List<_LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        const Text(
          'Last updated August 6, 2026',
          style: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        for (final section in sections) ...[
          _LegalSectionCard(section: section),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _LegalSectionCard extends StatelessWidget {
  const _LegalSectionCard({required this.section});

  final _LegalSection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF111827).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: GoogleFonts.archivoBlack(
              color: const Color(0xFF111827),
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            section.body,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              height: 1.5,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalSection {
  const _LegalSection(this.title, this.body);

  final String title;
  final String body;
}

const _termsSections = <_LegalSection>[
  _LegalSection(
    '1. Acceptance of Terms',
    'By creating an Errand account you agree to these Terms of Service. '
        'Errand connects Senders who need small tasks completed with Runners '
        'willing to complete them for a reward. If you do not agree with '
        'these terms, please do not use the app.',
  ),
  _LegalSection(
    '2. Sender & Runner Roles',
    'Senders may post errands describing a pickup location, drop-off '
        'location, and reward. Runners may browse and accept available '
        'errands. Every account can switch between the Sender and Runner '
        'role from the Profile screen at any time.',
  ),
  _LegalSection(
    '3. Floats & Payments',
    'Runners use Floats to accept errands. Floats are purchased through the '
        'app and deducted automatically when a delivery is completed. '
        'Rewards for completed errands are credited to the Runner\'s '
        'earnings balance. Errand does not process direct cash payments '
        'between users.',
  ),
  _LegalSection(
    '4. Conduct & Safety',
    'Users agree to communicate respectfully, meet at agreed locations, and '
        'complete errands honestly. Sharing accurate contact details (name '
        'and phone number) with your matched Sender or Runner is required '
        'so deliveries can be coordinated safely.',
  ),
  _LegalSection(
    '5. Cancellations',
    'Senders may cancel an errand before it is picked up; the assigned '
        'Runner will be notified immediately. Repeated or last-minute '
        'cancellations may affect your account standing.',
  ),
  _LegalSection(
    '6. Account Suspension',
    'Errand may suspend or remove accounts that violate these terms, '
        'engage in fraudulent activity, or put other users at risk. We '
        'reserve the right to update these terms as the app evolves.',
  ),
];

const _privacySections = <_LegalSection>[
  _LegalSection(
    '1. Information We Collect',
    'We collect the information you provide when creating your profile, '
        'such as your name, phone number, student ID, gender, and room '
        'number, along with details of the errands you post or accept.',
  ),
  _LegalSection(
    '2. How We Use Your Information',
    'Your profile information is used to verify runner accounts, '
        'coordinate errands, and send you notifications about the status '
        'of your requests and deliveries.',
  ),
  _LegalSection(
    '3. Sharing Between Users',
    'When a Runner accepts your errand, your name and phone number are '
        'shared with that Runner, and their name and phone number are '
        'shared with you, so you can coordinate pickup and delivery '
        'directly.',
  ),
  _LegalSection(
    '4. Data Storage & Security',
    'Your data is stored securely using Firebase services. We take '
        'reasonable steps to protect your information, but no system can '
        'guarantee absolute security.',
  ),
  _LegalSection(
    '5. Your Choices',
    'You can review and update your profile information at any time from '
        'the Profile screen. If you would like your account and data '
        'removed, contact us through the Help Center.',
  ),
];
