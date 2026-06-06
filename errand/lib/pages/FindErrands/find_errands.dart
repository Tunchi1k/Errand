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
    'Food Delivery',
    'Shopping',
    'Parcel Pickup',
    'Printing',
    'Other',
  ];

  final _repository = MockErrandRepository();
  final TextEditingController _searchController = TextEditingController();

  RunnerStats? _stats;
  List<Errand> _errands = const [];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadErrands();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadErrands() async {
    final result = await _repository.fetchAvailableErrands();
    if (!mounted) return;

    setState(() {
      _stats = result.stats;
      _errands = result.errands;
      _isLoading = false;
    });
  }

  List<Errand> get _filteredErrands {
    return _errands.where((errand) {
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
    final stats =
        _stats ??
        const RunnerStats(
          availableErrands: 12,
          todayEarnings: 'K85',
          rating: '4.8',
          floatBalance: 10,
          hasActiveFloats: false,
        );
    final filteredErrands = _filteredErrands;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8FB),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goHome,
          tooltip: 'Back',
        ),
        title: const Text('Find Errands'),
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: const Color(0xFF111827),
          fontWeight: FontWeight.w800,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: _openNotifications,
            tooltip: 'Notifications',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const _FindErrandsSkeleton()
                : RefreshIndicator(
                  onRefresh: _loadErrands,
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            if (!stats.hasActiveFloats) ...[
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

                            // Runner summary.
                            _RunnerStatsCard(stats: stats),
                            const SizedBox(height: 26),

                            // Recommended errand.
                            _SectionHeader(title: 'Recommended For You'),
                            const SizedBox(height: 12),
                            if (_errands.isNotEmpty)
                              _RecommendedErrandCard(errand: _errands.first),
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
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              if (index.isOdd) {
                                return const SizedBox(height: 14);
                              }

                              return _ErrandCard(
                                errand: filteredErrands[index ~/ 2],
                              );
                            }, childCount: filteredErrands.length * 2 - 1),
                          ),
                        ),
                    ],
                  ),
                ),
      ),
    );
  }

  void _openNotifications() {
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to view notifications.')),
      );
      return;
    }

    Navigator.pushNamed(context, '/notifications');
  }

  void _showFloatPurchasePlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Float purchase will be available soon.')),
    );
  }
}

class Errand {
  const Errand({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.pickupLocation,
    required this.deliveryLocation,
    required this.reward,
    required this.distance,
    required this.postedAgo,
    required this.senderRating,
    required this.estimatedTime,
  });

  final String id;
  final String category;
  final String title;
  final String description;
  final String pickupLocation;
  final String deliveryLocation;
  final String reward;
  final String distance;
  final String postedAgo;
  final double senderRating;
  final String estimatedTime;

  factory Errand.fromFirestore(String id, Map<String, dynamic> data) {
    return Errand(
      id: id,
      category: data['category']?.toString() ?? 'Other',
      title: data['title']?.toString() ?? 'Untitled Errand',
      description: data['description']?.toString() ?? '',
      pickupLocation: data['pickupLocation']?.toString() ?? '',
      deliveryLocation: data['deliveryLocation']?.toString() ?? '',
      reward: data['reward']?.toString() ?? 'K0',
      distance: data['distance']?.toString() ?? '0 km',
      postedAgo: data['postedAgo']?.toString() ?? 'Just now',
      senderRating: (data['senderRating'] as num?)?.toDouble() ?? 0,
      estimatedTime: data['estimatedTime']?.toString() ?? '30 min',
    );
  }
}

class RunnerStats {
  const RunnerStats({
    required this.availableErrands,
    required this.todayEarnings,
    required this.rating,
    required this.floatBalance,
    required this.hasActiveFloats,
  });

  final int availableErrands;
  final String todayEarnings;
  final String rating;
  final int floatBalance;
  final bool hasActiveFloats;
}

class ErrandFeed {
  const ErrandFeed({required this.stats, required this.errands});

  final RunnerStats stats;
  final List<Errand> errands;
}

abstract class ErrandRepository {
  Future<ErrandFeed> fetchAvailableErrands();
}

class MockErrandRepository implements ErrandRepository {
  @override
  Future<ErrandFeed> fetchAvailableErrands() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    return const ErrandFeed(
      stats: RunnerStats(
        availableErrands: 12,
        todayEarnings: 'K85',
        rating: '4.8',
        floatBalance: 10,
        hasActiveFloats: false,
      ),
      errands: [
        Errand(
          id: 'errand-1',
          category: 'Food Delivery',
          title: 'Food Pickup',
          description:
              'Pick up lunch from Campus Mall and deliver it to the School of Engineering.',
          pickupLocation: 'Campus Mall',
          deliveryLocation: 'School of Engineering',
          reward: 'K25',
          distance: '1.2 km',
          postedAgo: '3 minutes ago',
          senderRating: 4.9,
          estimatedTime: '20 min',
        ),
        Errand(
          id: 'errand-2',
          category: 'Shopping',
          title: 'Grocery Run',
          description:
              'Buy listed groceries from FreshMart and deliver them to Hostel Block B.',
          pickupLocation: 'FreshMart',
          deliveryLocation: 'Hostel Block B',
          reward: 'K40',
          distance: '2.8 km',
          postedAgo: '8 minutes ago',
          senderRating: 4.7,
          estimatedTime: '35 min',
        ),
        Errand(
          id: 'errand-3',
          category: 'Printing',
          title: 'Print Assignment',
          description:
              'Print and bind a 25-page report, then deliver it to the library entrance.',
          pickupLocation: 'Print Hub',
          deliveryLocation: 'Main Library',
          reward: 'K18',
          distance: '0.7 km',
          postedAgo: '14 minutes ago',
          senderRating: 4.8,
          estimatedTime: '15 min',
        ),
        Errand(
          id: 'errand-4',
          category: 'Parcel Pickup',
          title: 'Collect Package',
          description:
              'Collect a small parcel from the courier desk and deliver it to Admin Block.',
          pickupLocation: 'Courier Desk',
          deliveryLocation: 'Admin Block',
          reward: 'K30',
          distance: '1.9 km',
          postedAgo: '22 minutes ago',
          senderRating: 5.0,
          estimatedTime: '25 min',
        ),
      ],
    );
  }
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
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
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
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = category == selectedCategory;

          return FilterChip(
            label: Text(category),
            selected: selected,
            onSelected: (_) => onSelected(category),
            showCheckmark: false,
            labelStyle: TextStyle(
              color: selected ? colorScheme.onPrimary : const Color(0xFF374151),
              fontWeight: FontWeight.w700,
            ),
            selectedColor: colorScheme.primary,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: selected ? colorScheme.primary : const Color(0xFFE5E7EB),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
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

class _RunnerStatsCard extends StatelessWidget {
  const _RunnerStatsCard({required this.stats});

  final RunnerStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;

          return GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: compact ? 2 : 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: compact ? 1.8 : 1.12,
            ),
            children: [
              _StatTile(
                label: 'Available Errands',
                value: stats.availableErrands.toString(),
                icon: Icons.assignment_outlined,
                color: const Color(0xFF2563EB),
              ),
              _StatTile(
                label: "Today's Earnings",
                value: stats.todayEarnings,
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFF059669),
              ),
              _StatTile(
                label: 'Rating',
                value: stats.rating,
                icon: Icons.star_border_rounded,
                color: const Color(0xFFF59E0B),
              ),
              _StatTile(
                label: 'Float Balance',
                value: stats.floatBalance.toString(),
                icon: Icons.toll_outlined,
                color: const Color(0xFF7C3AED),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
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
      ),
    );
  }
}

class _RecommendedErrandCard extends StatelessWidget {
  const _RecommendedErrandCard({required this.errand});

  final Errand errand;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
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
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
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

class _ErrandCard extends StatelessWidget {
  const _ErrandCard({required this.errand});

  final Errand errand;

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
            style: const TextStyle(color: Color(0xFF4B5563), height: 1.4),
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
              onPressed: () {},
              style: FilledButton.styleFrom(
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
          color: Color(0xFF1D4ED8),
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
        color: dark ? const Color(0xFF22C55E) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        reward,
        style: TextStyle(
          color: dark ? Colors.white : const Color(0xFF047857),
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
  const _MetaChip({
    required this.icon,
    required this.label,
    this.dark = false,
  });

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
          _SkeletonBox(height: 178, radius: 20),
          SizedBox(height: 26),
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
