import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

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

  final List<String> _categories = const [
    'Delivery',
    'Groceries',
    'Documents',
    'Laundry',
    'Other',
  ];

  @override
  void dispose() {
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

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => SearchingForRunnerPage(errandId: errandRef.id),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Post Errand',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
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
              const SizedBox(height: 16),
              _buildCategoryPicker(),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'What should the runner do?',
                icon: Iconsax.note_text,
                maxLines: 1,
                validator:
                    (value) =>
                        value == null || value.trim().length < 10
                            ? 'Add at least 10 characters'
                            : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _pickupController,
                label: 'Pickup location',
                hint: 'Where should the runner start?',
                icon: Iconsax.location,
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Enter pickup location'
                            : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _dropoffController,
                label: 'Drop-off location',
                hint: 'Where should the runner deliver?',
                icon: Iconsax.location_tick,
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Enter drop-off location'
                            : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _priceController,
                label: 'Runner pay',
                hint: 'Amount in ZMW',
                icon: Iconsax.money,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _validatePrice,
              ),
              const SizedBox(height: 18),
              const SizedBox(height: 18),
              _buildTextField(
                controller: _notesController,
                label: 'Notes',
                hint: 'Optional details, contact instructions, timing...',
                icon: Iconsax.message_text,
                maxLines: 3,
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
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
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
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.black54),
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

    _animation = Tween<double>(begin: 0.4, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
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
                'Runners can now see this request. Reference: ${widget.errandId}',
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
