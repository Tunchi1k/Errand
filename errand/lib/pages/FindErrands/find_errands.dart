import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:errand/pages/FindErrands/errand_repository.dart';
import 'package:errand/pages/Homepage/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FindErrandsPage extends StatefulWidget {
  const FindErrandsPage({super.key});

  @override
  State<FindErrandsPage> createState() => _FindErrandsPageState();
}

class _FindErrandsPageState extends State<FindErrandsPage> {
  static const List<String> _categories = [
    'All',
    'Delivery',
    'Groceries',
    'Documents',
    'Laundry',
    'Other',
  ];

  final _repository = FirestoreErrandRepository();
  final TextEditingController _searchController = TextEditingController();
  Stream<List<Errand>>? _errandsStream;

  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _hasActiveFloats = true;

  @override
  void initState() {
    super.initState();
    _resetErrandsStream();
    _loadFloatEligibility();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFloatEligibility() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    if (!mounted) return;

    final floats = snapshot.data()?['floats'];
    setState(() {
      _hasActiveFloats = floats is num && floats > 0;
    });
  }

  void _resetErrandsStream() {
    _errandsStream = _repository.watchAvailableErrands();
  }

  Stream<List<Errand>> _currentErrandsStream() {
    return _errandsStream ??= _repository.watchAvailableErrands();
  }

  List<Errand> _filterErrands(List<Errand> errands) {
    return errands.where((errand) {
      final matchesCategory =
          _selectedCategory == 'All' || errand.category == _selectedCategory;
      final normalizedQuery = _searchQuery.trim().toLowerCase();
      final matchesSearch =
          normalizedQuery.isEmpty ||
          errand.title.toLowerCase().contains(normalizedQuery) ||
          errand.description.toLowerCase().contains(normalizedQuery) ||
          errand.pickupLocation.toLowerCase().contains(normalizedQuery) ||
          errand.deliveryLocation.toLowerCase().contains(normalizedQuery);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _goHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 233, 233, 233),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 233, 233, 233),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goHome,
          tooltip: 'Back',
        ),
        title: const Text('Find errands'),
        centerTitle: true,
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: const Color(0xFF111827),
          fontWeight: FontWeight.w800,
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Errand>>(
          stream: _currentErrandsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _FindErrandsSkeleton();
            }

            if (snapshot.hasError) {
              return _ErrorState(
                onRetry: () {
                  setState(() {
                    _resetErrandsStream();
                  });
                },
              );
            }

            final errands = snapshot.data ?? const <Errand>[];
            final filteredErrands = _filterErrands(errands);

            return RefreshIndicator(
              onRefresh: _loadFloatEligibility,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (!_hasActiveFloats) ...[
                          _FloatEligibilityBanner(
                            onBuyFloats: _showFloatPurchasePlaceholder,
                          ),
                          const SizedBox(height: 18),
                        ],

                        // Search and category filters.
                        _SearchField(
                          controller: _searchController,
                          onChanged:
                              (value) => setState(() {
                                _searchQuery = value;
                              }),
                        ),
                        const SizedBox(height: 16),
                        _CategoryFilterBar(
                          categories: _categories,
                          selectedCategory: _selectedCategory,
                          onSelected:
                              (category) => setState(() {
                                _selectedCategory = category;
                              }),
                        ),
                        const SizedBox(height: 20),

                        // Recommended errand.
                        _SectionHeader(title: 'Recommended For You'),
                        const SizedBox(height: 12),
                        if (errands.isNotEmpty)
                          _RecommendedErrandCard(
                            errand: errands.first,
                            onViewDetails: () => _openErrandDetails(errands.first),
                          )
                        else
                          const _CompactEmptyRecommendedCard(),
                        const SizedBox(height: 28),

                        // Available errands.
                        _SectionHeader(title: 'Available Errands'),
                        const SizedBox(height: 12),
                      ]),
                    ),
                  ),
                  if (filteredErrands.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyErrandsState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          if (index.isOdd) {
                            return const SizedBox(height: 14);
                          }

                          return _ErrandCard(
                            errand: filteredErrands[index ~/ 2],
                            onViewDetails:
                                () => _openErrandDetails(
                                  filteredErrands[index ~/ 2],
                                ),
                          );
                        }, childCount: filteredErrands.length * 2 - 1),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showFloatPurchasePlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Float purchase will be available soon.')),
    );
  }

  void _openErrandDetails(Errand errand) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => _ErrandDetailsSheet(
            errand: errand,
            onAccept: () => _acceptErrand(context, errand),
          ),
    );
  }

  Future<void> _acceptErrand(BuildContext sheetContext, Errand errand) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showFindErrandsSnackBar(
        sheetContext,
        message: 'Sign in to accept errands.',
        isError: true,
      );
      return;
    }

    // Ensure only users with role 'Runner' can accept errands
    final userSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final role = userSnapshot.data()?['role']?.toString();
    if (role != 'Runner') {
      _showFindErrandsSnackBar(
        sheetContext,
        message: 'You are not a runner.',
        isError: true,
      );
      return;
    }

    final result = await _repository.acceptErrand(
      errandId: errand.id,
      runnerId: user.uid,
    );
    if (!mounted) return;

    if (sheetContext.mounted) Navigator.pop(sheetContext);
    await _loadFloatEligibility();

    final message = switch (result) {
      AcceptErrandResult.accepted => 'Errand accepted. Check My Deliveries.',
      AcceptErrandResult.noFloats =>
        'You need active floats to accept errands.',
      AcceptErrandResult.activeErrandExists =>
        'Complete your active delivery before accepting another.',
      AcceptErrandResult.errandUnavailable =>
        'This errand is no longer available.',
      AcceptErrandResult.userNotFound => 'Could not verify your runner account.',
    };

    _showFindErrandsSnackBar(
      context,
      message: message,
      isError: result != AcceptErrandResult.accepted,
    );
  }
}

void _showFindErrandsSnackBar(
  BuildContext context, {
  required String message,
  bool isError = false,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isError ? const Color(0xFF991B1B) : const Color(0xFF102A43),
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
      ),
    );
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search errands...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(
            color: const Color.fromARGB(255, 46, 46, 46),
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 22),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = category == selectedCategory;

          return InkWell(
            onTap: () => onSelected(category),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category,
                    style: TextStyle(
                      color:
                          selected
                              ? const Color.fromARGB(255, 0, 63, 97)
                              : const Color(0xFF6B7280),
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    width: selected ? 26 : 0,
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 0, 63, 97),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FloatEligibilityBanner extends StatelessWidget {
  const _FloatEligibilityBanner({required this.onBuyFloats});

  final VoidCallback onBuyFloats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        border: Border.all(color: const Color(0xFFFED7AA)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEDD5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFC2410C),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'You need active floats to accept errands.',
              style: TextStyle(
                color: Color(0xFF7C2D12),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          FilledButton(
            onPressed: onBuyFloats,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC2410C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Buy Floats'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: const Color(0xFF111827),
        fontWeight: FontWeight.w900,
        fontSize: 23,
      ),
    );
  }
}

class _RecommendedErrandCard extends StatelessWidget {
  const _RecommendedErrandCard({
    required this.errand,
    required this.onViewDetails,
  });

  final Errand errand;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260F172A),
            blurRadius: 26,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  errand.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _RewardPill(reward: errand.reward, dark: true),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            errand.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFD9E2EC),
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _MetaChip(
                icon: Icons.route_outlined,
                label: errand.distance,
                dark: true,
              ),
              _MetaChip(
                icon: Icons.schedule_outlined,
                label: errand.estimatedTime,
                dark: true,
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onViewDetails,
              style: FilledButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 187, 187, 187),
                foregroundColor: const Color(0xFF102A43),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('View Details'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactEmptyRecommendedCard extends StatelessWidget {
  const _CompactEmptyRecommendedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Text(
        'New recommendations will appear when errands are posted.',
        style: TextStyle(
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
      ),
    );
  }
}

class _ErrandCard extends StatelessWidget {
  const _ErrandCard({required this.errand, required this.onViewDetails});

  final Errand errand;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CategoryBadge(category: errand.category),
                    const SizedBox(height: 10),
                    Text(
                      errand.title,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              _RewardPill(reward: errand.reward),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            errand.description,
            style: const TextStyle(
              color: Color.fromARGB(255, 0, 0, 0),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          _LocationRow(
            pickup: errand.pickupLocation,
            destination: errand.deliveryLocation,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(icon: Icons.route_outlined, label: errand.distance),
              _MetaChip(icon: Icons.access_time, label: errand.postedAgo),
              _MetaChip(
                icon: Icons.star_border_rounded,
                label: errand.senderRating.toStringAsFixed(1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: onViewDetails,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF102A43),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('View Details'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        category,
        style: const TextStyle(
          color: Color.fromARGB(255, 10, 30, 85),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RewardPill extends StatelessWidget {
  const _RewardPill({required this.reward, this.dark = false});

  final String reward;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: dark ? const Color(0x1AFFFFFF) : const Color(0xFF102A43),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        reward,
        style: TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.pickup, required this.destination});

  final String pickup;
  final String destination;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _LocationLine(
            icon: Icons.radio_button_checked,
            label: 'Pickup',
            value: pickup,
            color: const Color(0xFF2563EB),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 14,
                child: VerticalDivider(
                  color: Color(0xFFD1D5DB),
                  thickness: 1.2,
                ),
              ),
            ),
          ),
          _LocationLine(
            icon: Icons.location_on,
            label: 'Destination',
            value: destination,
            color: const Color(0xFF059669),
          ),
        ],
      ),
    );
  }
}

class _LocationLine extends StatelessWidget {
  const _LocationLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w800,
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, this.dark = false});

  final IconData icon;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: dark ? const Color(0x1AFFFFFF) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: dark ? Colors.white : const Color(0xFF4B5563),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: dark ? Colors.white : const Color(0xFF4B5563),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyErrandsState extends StatelessWidget {
  const _EmptyErrandsState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 10, 32, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFF9CA3AF),
              size: 58,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'No errands available at the moment.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check back later for new opportunities.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6B7280), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: Color(0xFF9CA3AF),
              size: 58,
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not load available errands.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280), height: 1.4),
            ),
            const SizedBox(height: 18),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _ErrandDetailsSheet extends StatelessWidget {
  const _ErrandDetailsSheet({
    required this.errand,
    required this.onAccept,
  });

  final Errand errand;
  final Future<void> Function() onAccept;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    errand.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF111827),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _RewardPill(reward: errand.reward),
              ],
            ),
            const SizedBox(height: 8),
            _CategoryBadge(category: errand.category),
            const SizedBox(height: 16),
            Text(
              errand.description,
              style: const TextStyle(color: Color(0xFF4B5563), height: 1.45),
            ),
            const SizedBox(height: 18),
            _DetailRow(label: 'Pickup', value: errand.pickupLocation),
            _DetailRow(label: 'Destination', value: errand.deliveryLocation),
            _DetailRow(label: 'Requester', value: errand.senderName),
            _DetailRow(label: 'Distance', value: errand.distance),
            _DetailRow(label: 'Estimated Time', value: errand.estimatedTime),
            _DetailRow(label: 'Posted', value: errand.postedAgo),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF102A43),
                      side: const BorderSide(color: Color(0xFF102A43)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AcceptButton(onAccept: onAccept),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AcceptButton extends StatefulWidget {
  const _AcceptButton({required this.onAccept});

  final Future<void> Function() onAccept;

  @override
  State<_AcceptButton> createState() => _AcceptButtonState();
}

class _AcceptButtonState extends State<_AcceptButton> {
  bool _isLoading = false;

  Future<void> _handlePress() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await widget.onAccept();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: _isLoading ? null : _handlePress,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF102A43),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text('Accept'),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not set' : value,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FindErrandsSkeleton extends StatelessWidget {
  const _FindErrandsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SkeletonBox(height: 82, radius: 18),
          SizedBox(height: 18),
          _SkeletonBox(height: 54, radius: 18),
          SizedBox(height: 16),
          _SkeletonRow(),
          SizedBox(height: 20),
          _SkeletonBox(width: 190, height: 22, radius: 8),
          SizedBox(height: 12),
          _SkeletonBox(height: 232, radius: 22),
          SizedBox(height: 28),
          _SkeletonBox(width: 160, height: 22, radius: 8),
          SizedBox(height: 12),
          _SkeletonBox(height: 286, radius: 20),
          SizedBox(height: 14),
          _SkeletonBox(height: 286, radius: 20),
        ],
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder:
            (_, index) => _SkeletonBox(
              width: index == 0 ? 64 : 118,
              height: 42,
              radius: 18,
            ),
      ),
    );
  }
}

class _SkeletonBox extends StatefulWidget {
  const _SkeletonBox({required this.height, required this.radius, this.width});

  final double? width;
  final double height;
  final double radius;

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final start = -1 + (_controller.value * 2);
        final end = start + 1;

        return Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(start, 0),
              end: Alignment(end, 0),
              colors: const [
                Color(0xFFE5E7EB),
                Color(0xFFF8FAFC),
                Color(0xFFE5E7EB),
              ],
            ),
          ),
        );
      },
    );
  }
}
