import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyRequestsPage extends StatelessWidget {
  const MyRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('My Requests'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF6F8FB),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: const Color(0xFF111827),
          fontWeight: FontWeight.w800,
        ),
      ),
      body: SafeArea(
        child:
            user == null
                ? const _SignedOutState()
                : StreamBuilder<List<RequestErrand>>(
                  stream: FirestoreRequestsRepository().watchUserRequests(
                    user.uid,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _RequestsLoadingState();
                    }

                    if (snapshot.hasError) {
                      return const _RequestsErrorState();
                    }

                    final requests = snapshot.data ?? const <RequestErrand>[];
                    if (requests.isEmpty) {
                      return const _EmptyRequestsState();
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                      itemCount: requests.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder:
                          (context, index) =>
                              _RequestCard(request: requests[index]),
                    );
                  },
                ),
      ),
    );
  }
}

class RequestErrand {
  const RequestErrand({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.price,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String pickupLocation;
  final String dropoffLocation;
  final double price;
  final String status;
  final Timestamp? createdAt;

  factory RequestErrand.fromFirestore(String id, Map<String, dynamic> data) {
    final price = data['price'];

    return RequestErrand(
      id: id,
      title: data['title']?.toString() ?? 'Untitled Errand',
      description: data['description']?.toString() ?? '',
      category: data['category']?.toString() ?? 'Other',
      pickupLocation: data['pickupLocation']?.toString() ?? '',
      dropoffLocation:
          data['dropoffLocation']?.toString() ??
          data['deliveryLocation']?.toString() ??
          '',
      price: price is num ? price.toDouble() : 0,
      status: data['status']?.toString() ?? 'Active',
      createdAt: data['createdAt'] is Timestamp ? data['createdAt'] : null,
    );
  }

  String get formattedPrice {
    final hasDecimals = price % 1 != 0;
    return 'K${price.toStringAsFixed(hasDecimals ? 2 : 0)}';
  }

  String get postedAgo {
    if (createdAt == null) return 'Just now';

    final difference = DateTime.now().difference(createdAt!.toDate());
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    }
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    return '${difference.inDays} days ago';
  }
}

class FirestoreRequestsRepository {
  Stream<List<RequestErrand>> watchUserRequests(String userId) {
    return FirebaseFirestore.instance
        .collection('errands')
        .where('senderId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final docs = [...snapshot.docs];
          docs.sort((a, b) {
            final aCreatedAt = a.data()['createdAt'];
            final bCreatedAt = b.data()['createdAt'];

            if (aCreatedAt is Timestamp && bCreatedAt is Timestamp) {
              return bCreatedAt.compareTo(aCreatedAt);
            }

            return 0;
          });

          return docs
              .map((doc) => RequestErrand.fromFirestore(doc.id, doc.data()))
              .toList();
        });
  }

  Future<void> updateRequest(
    String requestId,
    Map<String, dynamic> updates,
  ) async {
    await FirebaseFirestore.instance
        .collection('errands')
        .doc(requestId)
        .update({...updates, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> deleteRequest(String requestId) async {
    await FirebaseFirestore.instance
        .collection('errands')
        .doc(requestId)
        .delete();
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final RequestErrand request;

  @override
  Widget build(BuildContext context) {
    final repository = FirestoreRequestsRepository();

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
                    _StatusBadge(status: request.status),
                    const SizedBox(height: 10),
                    Text(
                      request.title,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              _PricePill(price: request.formattedPrice),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            request.description,
            style: const TextStyle(color: Color(0xFF4B5563), height: 1.4),
          ),
          const SizedBox(height: 14),
          _RequestLocationBlock(request: request),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(icon: Icons.category_outlined, label: request.category),
              _MetaChip(icon: Icons.access_time, label: request.postedAgo),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showEditRequestSheet(context, request),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Update'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF102A43),
                    side: const BorderSide(color: Color(0xFF102A43)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    final shouldDelete = await _confirmDelete(context);
                    if (!shouldDelete || !context.mounted) return;

                    await repository.deleteRequest(request.id);
                    if (!context.mounted) return;

                    _showRequestSnackBar(context, message: 'Request deleted');
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF991B1B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequestLocationBlock extends StatelessWidget {
  const _RequestLocationBlock({required this.request});

  final RequestErrand request;

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
            value: request.pickupLocation,
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
            icon: Icons.location_on_outlined,
            label: 'Drop-off',
            value: request.dropoffLocation,
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
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF102A43), size: 20),
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
            value.isEmpty ? 'Not set' : value,
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status.toLowerCase()) {
      'completed' => const Color(0xFF047857),
      'cancelled' => const Color(0xFF991B1B),
      _ => const Color(0xFF102A43),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  const _PricePill({required this.price});

  final String price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        price,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF4B5563)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditRequestSheet extends StatefulWidget {
  const _EditRequestSheet({required this.request});

  final RequestErrand request;

  @override
  State<_EditRequestSheet> createState() => _EditRequestSheetState();
}

class _EditRequestSheetState extends State<_EditRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _pickupController;
  late final TextEditingController _dropoffController;
  late final TextEditingController _priceController;
  late String _category;
  late String _status;
  bool _isSaving = false;

  static const _categories = [
    'Delivery',
    'Groceries',
    'Documents',
    'Laundry',
    'Other',
  ];

  static const _statuses = ['Active', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.request.title);
    _descriptionController = TextEditingController(
      text: widget.request.description,
    );
    _pickupController = TextEditingController(
      text: widget.request.pickupLocation,
    );
    _dropoffController = TextEditingController(
      text: widget.request.dropoffLocation,
    );
    _priceController = TextEditingController(
      text: widget.request.price == 0 ? '' : widget.request.price.toString(),
    );
    _category =
        _categories.contains(widget.request.category)
            ? widget.request.category
            : 'Other';
    _status =
        _statuses.contains(widget.request.status)
            ? widget.request.status
            : 'Active';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final messenger = ScaffoldMessenger.of(context);
      await FirestoreRequestsRepository().updateRequest(widget.request.id, {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _category,
        'pickupLocation': _pickupController.text.trim(),
        'dropoffLocation': _dropoffController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'status': _status,
      });

      if (!mounted) return;
      Navigator.pop(context);
      _showRequestSnackBarWithMessenger(messenger, message: 'Request updated');
    } catch (error) {
      if (!mounted) return;
      _showRequestSnackBar(
        context,
        message: 'Could not update request',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update Request',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              _EditField(
                controller: _titleController,
                label: 'Title',
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Enter a title'
                            : null,
              ),
              const SizedBox(height: 12),
              _EditField(
                controller: _descriptionController,
                label: 'Description',
                validator:
                    (value) =>
                        value == null || value.trim().length < 10
                            ? 'Add at least 10 characters'
                            : null,
              ),
              const SizedBox(height: 12),
              _EditDropdown(
                label: 'Category',
                value: _category,
                items: _categories,
                onChanged: (value) => setState(() => _category = value),
              ),
              const SizedBox(height: 12),
              _EditField(
                controller: _pickupController,
                label: 'Pickup location',
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Enter pickup location'
                            : null,
              ),
              const SizedBox(height: 12),
              _EditField(
                controller: _dropoffController,
                label: 'Drop-off location',
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Enter drop-off location'
                            : null,
              ),
              const SizedBox(height: 12),
              _EditField(
                controller: _priceController,
                label: 'Runner pay',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final price = double.tryParse(value?.trim() ?? '');
                  if (price == null) return 'Enter a valid amount';
                  if (price <= 0) return 'Amount must be greater than zero';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _EditDropdown(
                label: 'Status',
                value: _status,
                items: _statuses,
                onChanged: (value) => setState(() => _status = value),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF102A43),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.controller,
    required this.label,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: _inputDecoration(label),
    );
  }
}

class _EditDropdown extends StatelessWidget {
  const _EditDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items:
          items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      decoration: _inputDecoration(label),
    );
  }
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF102A43), width: 1.3),
    ),
  );
}

Future<bool> _confirmDelete(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Delete request?'),
          content: const Text(
            'This request will be permanently removed from your errands.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF991B1B),
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
  );

  return result == true;
}

void _showEditRequestSheet(BuildContext context, RequestErrand request) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _EditRequestSheet(request: request),
  );
}

void _showRequestSnackBar(
  BuildContext context, {
  required String message,
  bool isError = false,
}) {
  _showRequestSnackBarWithMessenger(
    ScaffoldMessenger.of(context),
    message: message,
    isError: isError,
  );
}

void _showRequestSnackBarWithMessenger(
  ScaffoldMessengerState messenger, {
  required String message,
  bool isError = false,
}) {
  messenger
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

class _SignedOutState extends StatelessWidget {
  const _SignedOutState();

  @override
  Widget build(BuildContext context) {
    return const _CenteredState(
      icon: Icons.lock_outline,
      title: 'Sign in required',
      message: 'Please sign in to view your requests.',
    );
  }
}

class _EmptyRequestsState extends StatelessWidget {
  const _EmptyRequestsState();

  @override
  Widget build(BuildContext context) {
    return const _CenteredState(
      icon: Icons.assignment_outlined,
      title: 'No requests yet',
      message: 'Your posted errands will appear here.',
    );
  }
}

class _RequestsErrorState extends StatelessWidget {
  const _RequestsErrorState();

  @override
  Widget build(BuildContext context) {
    return const _CenteredState(
      icon: Icons.cloud_off_outlined,
      title: 'Could not load requests',
      message: 'Please check your connection and try again.',
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF9CA3AF), size: 58),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestsLoadingState extends StatelessWidget {
  const _RequestsLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, __) => const _RequestSkeletonCard(),
    );
  }
}

class _RequestSkeletonCard extends StatelessWidget {
  const _RequestSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
