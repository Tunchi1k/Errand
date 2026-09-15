import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:errand/services/custom_toast.dart';
import 'package:errand/services/notification_service.dart';

class PostTaskPage extends StatefulWidget {
  const PostTaskPage({super.key});

  @override
  State<PostTaskPage> createState() => _PostTaskPageState();
}

class _PostTaskPageState extends State<PostTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  String _category = 'Delivery';
  double _urgency = 3;
  bool _isSubmitting = false;
  bool _showDetails = false;
  int? _selectedPresetPay;

  static const campusLocations = [
    'Library',
    'New residence',
    'October car park',
    'Computer Science Building',
    'Great East Road (Main Gate)',
    'Nadias',
    'Ruins',
    'Sports Complex',
  ];
  static const presetPayAmounts = [20, 30, 50];

  final List<String> _categories = const [
    'Delivery',
    'Groceries',
    'Documents',
    'Laundry',
    'Other',
  ];

  void _autoSelectCategory() {
    final title = _titleController.text.toLowerCase();
    final category =
        title.contains('grocery') || title.contains('food')
            ? 'Groceries'
            : title.contains('package') ||
                title.contains('collect') ||
                title.contains('document')
            ? 'Delivery'
            : null;
    if (category != null && category != _category)
      setState(() => _category = category);
  }

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_autoSelectCategory);
  }

  @override
  void dispose() {
    _titleController.removeListener(_autoSelectCategory);
    _titleController.dispose();
    _descriptionController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _postErrand() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in before posting.')),
      );
      return;
    }

    final profileSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final profile = profileSnapshot.data() ?? {};
    final isSender = profile['role']?.toString() == 'Sender';
    final requiredProfileFields = [
      profile['name'],
      profile['phone'],
      profile['studentId'],
      profile['gender'],
      profile['roomNumber'],
    ];
    final profileIsComplete = requiredProfileFields.every(
      (value) => value != null && value.toString().trim().isNotEmpty,
    );
    if (isSender && !profileIsComplete) {
      CustomToast.show(
        context,
        'Profile Incomplete\n\nPlease complete your phone number and personal details before posting an errand.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final price = double.parse(_priceController.text.trim());
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final userData = userDoc.data() ?? {};

      final errandRef = await FirebaseFirestore.instance
          .collection('errands')
          .add({
            'title': _titleController.text.trim(),
            'description': _descriptionController.text.trim(),
            'category': _category,
            'pickupLocation': _pickupController.text.trim(),
            'dropoffLocation': _dropoffController.text.trim(),
            'price': price,
            'urgency': _urgency.round(),
            'notes': _notesController.text.trim(),
            'status': 'Active',
            'senderId': user.uid,
            'senderName': userData['name'] ?? user.displayName ?? 'Sender',
            'runnerId': null,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      await _notifyEligibleRunners(
        senderData: userData,
        senderFallbackName: user.displayName,
        price: price,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SearchingForRunnerPage(errandId: errandRef.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not post errand: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _notifyEligibleRunners({
    required Map<String, dynamic> senderData,
    required String? senderFallbackName,
    required double price,
  }) async {
    try {
      final runnersSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'Runner')
              .get();
      if (runnersSnapshot.docs.isEmpty) return;

      final senderName =
          senderData['name']?.toString() ?? senderFallbackName ?? 'A sender';
      final senderPhone = senderData['phone']?.toString() ?? 'Not provided';
      final pickup = _pickupController.text.trim();
      final dropoff = _dropoffController.text.trim();
      final hasDecimals = price % 1 != 0;
      final reward = 'K${price.toStringAsFixed(hasDecimals ? 2 : 0)}';

      final message = [
        'A new errand was just posted.',
        '',
        'Sender:\n$senderName',
        '',
        'Phone:\n$senderPhone',
        '',
        'Pickup:\n$pickup',
        '',
        'Drop-off:\n$dropoff',
        '',
        'Reward:\n$reward',
      ].join('\n');

      await Future.wait([
        for (final runnerDoc in runnersSnapshot.docs)
          NotificationService.sendNotification(
            userId: runnerDoc.id,
            title: 'New Errand Available',
            message: message,
            actionLabel: 'View Errand',
            destinationPage: 'find_errands',
            notificationType: 'new_errand',
          ),
      ]);
    } catch (e) {
      debugPrint('Error notifying eligible runners: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Post Errand',
          style: GoogleFonts.archivoBlack(fontSize: 30),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              _buildTextField(
                controller: _titleController,
                label: 'Errand title',
                hint: 'Buy groceries, collect a package...',
                icon: Iconsax.task_square,
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Enter an errand title'
                            : null,
              ),
              const SizedBox(height: 10),
              _buildCategoryChip(),
              const SizedBox(height: 16),
              _buildRouteCard(),
              const SizedBox(height: 16),
              _buildPayBlock(),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _showDetails = !_showDetails),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _showDetails ? '− Hide details' : '+ Add details',
                  ),
                ),
              ),
              if (_showDetails)
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Details for your runner',
                  hint:
                      'What should they do, and any contact/timing instructions?',
                  icon: Iconsax.note_text,
                  maxLines: 4,
                ),
              const SizedBox(height: 28),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _postErrand,
                  icon:
                      _isSubmitting
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Iconsax.send_2, color: Colors.white),
                  label: Text(
                    _isSubmitting ? 'Posting...' : 'Post Errand',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 63, 97),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validatePrice(String? value) {
    final price = double.tryParse(value?.trim() ?? '');
    if (price == null) return 'Enter a valid amount';
    if (price <= 0) return 'Amount must be greater than zero';
    return null;
  }

  Widget _buildCategoryChip() => Align(
    alignment: Alignment.centerLeft,
    child: ActionChip(
      label: Text('$_category ▾'),
      labelStyle: const TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: const Color.fromARGB(255, 0, 63, 97),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onPressed:
          () => showModalBottomSheet<void>(
            context: context,
            builder:
                (context) => SafeArea(
                  child: ListView(
                    shrinkWrap: true,
                    children:
                        _categories
                            .map(
                              (category) => ListTile(
                                title: Text(category),
                                onTap: () {
                                  setState(() => _category = category);
                                  Navigator.pop(context);
                                },
                              ),
                            )
                            .toList(),
                  ),
                ),
          ),
    ),
  );

  Widget _buildRouteCard() => _notificationSurface(
    child: Column(
      children: [
        _buildLocationInput(
          _pickupController,
          'Pickup location',
          Iconsax.location,
        ),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '●\n│\n○',
            style: TextStyle(color: Color(0xFF00A8D6), height: .7),
          ),
        ),
        _buildLocationInput(
          _dropoffController,
          'Drop-off location',
          Iconsax.location_tick,
        ),
      ],
    ),
  );

  Widget _buildLocationInput(
    TextEditingController controller,
    String hint,
    IconData icon,
  ) => TextFormField(
    controller: controller,
    validator:
        (value) => value == null || value.trim().isEmpty ? 'Enter $hint' : null,
    decoration: _inputDecoration(hint: hint, icon: icon),
    onTap: () async {
      final choice = await showModalBottomSheet<String>(
        context: context,
        builder:
            (context) => SafeArea(
              child: ListView(
                shrinkWrap: true,
                children:
                    campusLocations
                        .map(
                          (location) => ListTile(
                            leading: const Icon(Iconsax.location),
                            title: Text(location),
                            onTap: () => Navigator.pop(context, location),
                          ),
                        )
                        .toList(),
              ),
            ),
      );
      if (choice != null) controller.text = choice;
    },
  );

  Widget _buildPayBlock() => _notificationSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Runner pay', style: GoogleFonts.archivoBlack(fontSize: 17)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            ...presetPayAmounts.map(
              (amount) => ChoiceChip(
                label: Text('$amount ZMW'),
                selected: _selectedPresetPay == amount,
                labelStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                backgroundColor: const Color.fromARGB(255, 0, 63, 97),
                selectedColor: const Color.fromARGB(255, 0, 63, 97),
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                onSelected:
                    (_) => setState(() {
                      _selectedPresetPay = amount;
                      _priceController.text = amount.toString();
                    }),
              ),
            ),
            ChoiceChip(
              label: const Text('Custom'),
              selected: _selectedPresetPay == null,
              labelStyle: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              backgroundColor: const Color.fromARGB(255, 0, 63, 97),
              selectedColor: const Color.fromARGB(255, 0, 63, 97),
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              onSelected: (_) => setState(() => _selectedPresetPay = null),
            ),
          ],
        ),
        if (_selectedPresetPay == null) ...[
          const SizedBox(height: 10),
          _buildTextField(
            controller: _priceController,
            label: 'Amount in ZMW',
            hint: 'Enter amount',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: _validatePrice,
          ),
        ],
      ],
    ),
  );

  Widget _notificationSurface({required Widget child}) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    ),
  );

  Widget _buildCategoryPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _category,
          items:
              _categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _category = value);
          },
          decoration: _inputDecoration(
            hint: 'Select category',
            icon: Iconsax.category,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.archivoBlack(fontSize: 17)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: _inputDecoration(hint: hint, icon: icon),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, color: Colors.black54),
      filled: true,
      fillColor: const Color(0xFFF4F6F8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color.fromARGB(255, 0, 63, 97),
          width: 1.4,
        ),
      ),
    );
  }
}

class SearchingForRunnerPage extends StatefulWidget {
  const SearchingForRunnerPage({super.key, required this.errandId});

  final String errandId;

  @override
  State<SearchingForRunnerPage> createState() => _SearchingForRunnerPageState();
}

class _SearchingForRunnerPageState extends State<SearchingForRunnerPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _animation = Tween<double>(
      begin: 0.4,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Finding Runner',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  width: 180 * _animation.value,
                  height: 180 * _animation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color.fromARGB(
                      255,
                      0,
                      63,
                      97,
                    ).withOpacity(1 - _animation.value),
                  ),
                  child: child,
                );
              },
              child: const Center(
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: Color.fromARGB(255, 0, 63, 97),
                  child: Icon(Iconsax.routing_2, color: Colors.white, size: 40),
                ),
              ),
            ),
            const SizedBox(height: 34),
            const Text(
              'Your errand is live',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Text(
                'Runners can now see this request and you will be notified when a runner accepts it.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 15),
              ),
            ),
            const SizedBox(height: 28),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
