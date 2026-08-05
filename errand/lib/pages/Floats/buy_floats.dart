import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:errand/pages/Homepage/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:errand/services/notification_service.dart';
import 'package:errand/services/custom_toast.dart';

class BuyFloatsPage extends StatelessWidget {
  const BuyFloatsPage({super.key});

  static const List<FloatPackage> _packages = [
    FloatPackage(
      floats: 10,
      description: 'Access to approximately 10 errands',
      amount: 30,
    ),
    FloatPackage(
      floats: 25,
      description: 'Access to approximately 25 errands',
      amount: 60,
      isMostPopular: true,
    ),
    FloatPackage(
      floats: 50,
      description: 'Access to approximately 50 errands',
      amount: 100,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6F8),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          },
        ),
        title: const Text('Buy Floats'),
        centerTitle: true,
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: const Color(0xFF111827),
          fontWeight: FontWeight.w800,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<int>(
                stream: _watchCurrentFloats(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const FloatBalanceCard(
                      balance: 0,
                      helperText: 'Could not load your float balance',
                    );
                  }

                  return FloatBalanceCard(
                    balance: snapshot.data ?? 0,
                    loading:
                        snapshot.connectionState == ConnectionState.waiting,
                  );
                },
              ),
              const SizedBox(height: 16),
              const FloatInfoCard(),
              const SizedBox(height: 28),
              Text(
                'Choose a Package',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              ..._packages.map(
                (package) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: FloatPackageCard(
                    package: package,
                    onBuy: () => _openPaymentSheet(context, package),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPaymentSheet(
    BuildContext context,
    FloatPackage package,
  ) async {
    final selection = await showModalBottomSheet<PurchaseSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentMethodBottomSheet(package: package),
    );

    if (selection == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Purchase'),
            content: Text(
              'Package: ${selection.package.floats} Floats\n'
              'Amount: K${selection.package.amount}\n'
              'Payment Method: ${selection.paymentMethod.name}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );

    if (confirmed != true || !context.mounted) return;

    await _submitPurchase(context, selection);
  }

  Stream<int> _watchCurrentFloats() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
          final floats = snapshot.data()?['floats'];
          return floats is num ? floats.toInt() : 0;
        });
  }

  Future<void> _submitPurchase(
    BuildContext context,
    PurchaseSelection selection,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      CustomToast.show(context, 'Please sign in to buy floats.');
      return;
    }

    // Verify user role is Runner
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final role = userDoc.data()?['role']?.toString();
    if (role != 'Runner') {
      CustomToast.show(context, 'Runner Access Required\n\nFloats are only available for runner accounts. Switch to a runner account to purchase floats and start accepting errands.');
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(user.uid);
      final purchaseRef = firestore.collection('floatPurchases').doc();
      final batch = firestore.batch();

      batch.set(userRef, {
        'floats': FieldValue.increment(selection.package.floats),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      batch.set(purchaseRef, {
        'userId': user.uid,
        'floats': selection.package.floats,
        'amount': selection.package.amount,
        'paymentMethod': selection.paymentMethod.name,
        'status': 'submitted',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      final previousFloats = userDoc.data()?['floats'];
      final newBalance = (previousFloats is num ? previousFloats.toInt() : 0) +
          selection.package.floats;
      await NotificationService.sendNotification(
        userId: user.uid,
        title: 'Floats Purchased',
        message: 'Your float purchase was successful.\n\n'
            'Floats Added:\n${selection.package.floats} Floats\n\n'
            'New Float Balance:\n$newBalance Floats',
        actionLabel: 'View Float Balance',
        destinationPage: 'buy_floats',
        notificationType: 'floats_purchased',
      );
      if (!context.mounted) return;

      CustomToast.show(context, 'Purchase request submitted successfully.');
    } catch (e) {
      if (!context.mounted) return;

      CustomToast.show(context, 'Could not submit purchase request: $e');
    }
  }

}

class FloatBalanceCard extends StatelessWidget {
  const FloatBalanceCard({
    super.key,
    required this.balance,
    this.loading = false,
    this.helperText,
  });

  final int balance;
  final bool loading;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final hasFloats = balance > 0;
    final balanceText =
        loading ? 'Loading Floats' : '$balance Floats Remaining';
    final statusText =
        helperText ??
        (hasFloats
            ? 'Eligible to accept errands'
            : 'You need floats to accept errands');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF102A43),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x240F172A),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Float Balance',
            style: TextStyle(
              color: Color(0xFFD9E2EC),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            balanceText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 31,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            statusText,
            style: const TextStyle(
              color: Color(0xFFBFD7EA),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class FloatInfoCard extends StatelessWidget {
  const FloatInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What Are Floats?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Floats are credits that allow runners to accept errands. One completed errand uses one float.',
            style: TextStyle(
              color: Color(0xFF4B5563),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class FloatPackageCard extends StatelessWidget {
  const FloatPackageCard({
    super.key,
    required this.package,
    required this.onBuy,
  });

  final FloatPackage package;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final highlighted = package.isMostPopular;

    return _SurfaceCard(
      borderColor:
          highlighted ? const Color(0xFF1D4ED8) : const Color(0xFFE5E7EB),
      backgroundColor: highlighted ? const Color(0xFFF8FBFF) : Colors.white,
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
                    Text(
                      '${package.floats} Floats',
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      package.description,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (highlighted) const _PopularBadge(),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'K${package.amount}',
                  style: const TextStyle(
                    color: Color(0xFF102A43),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              FilledButton(
                onPressed: onBuy,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF102A43),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Buy Package'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PaymentMethodBottomSheet extends StatefulWidget {
  const PaymentMethodBottomSheet({super.key, required this.package});

  final FloatPackage package;

  @override
  State<PaymentMethodBottomSheet> createState() =>
      _PaymentMethodBottomSheetState();
}

class _PaymentMethodBottomSheetState extends State<PaymentMethodBottomSheet> {
  PaymentMethod? _selectedMethod;

  static const List<PaymentMethod> _paymentMethods = [
    PaymentMethod('MTN Mobile Money'),
    PaymentMethod('Airtel Money'),
    PaymentMethod('Zamtel Kwacha'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text(
              'Choose Payment Method',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF111827),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            ..._paymentMethods.map(
              (method) => _PaymentMethodTile(
                method: method,
                selectedMethod: _selectedMethod,
                onSelected: () => setState(() => _selectedMethod = method),
              ),
            ),
            if (_selectedMethod != null) ...[
              const SizedBox(height: 16),
              _PurchaseSummary(
                package: widget.package,
                paymentMethod: _selectedMethod!,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      PurchaseSelection(
                        package: widget.package,
                        paymentMethod: _selectedMethod!,
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF102A43),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class FloatPackage {
  const FloatPackage({
    required this.floats,
    required this.description,
    required this.amount,
    this.isMostPopular = false,
  });

  final int floats;
  final String description;
  final int amount;
  final bool isMostPopular;
}

class PaymentMethod {
  const PaymentMethod(this.name);

  final String name;
}

class PurchaseSelection {
  const PurchaseSelection({required this.package, required this.paymentMethod});

  final FloatPackage package;
  final PaymentMethod paymentMethod;
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.backgroundColor = Colors.white,
    this.borderColor = const Color(0xFFE5E7EB),
  });

  final Widget child;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PopularBadge extends StatelessWidget {
  const _PopularBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Most Popular',
        style: TextStyle(
          color: Color(0xFF1D4ED8),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.method,
    required this.selectedMethod,
    required this.onSelected,
  });

  final PaymentMethod method;
  final PaymentMethod? selectedMethod;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = method == selectedMethod;

    return Card(
      elevation: 0,
      color: selected ? const Color(0xFFF0F7FF) : const Color(0xFFF9FAFB),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? const Color(0xFF1D4ED8) : const Color(0xFFE5E7EB),
        ),
      ),
      child: ListTile(
        onTap: onSelected,
        title: Text(
          method.name,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: const Text(
          'Pay using mobile money',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: selected ? const Color(0xFF1D4ED8) : const Color(0xFF9CA3AF),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}

class _PurchaseSummary extends StatelessWidget {
  const _PurchaseSummary({required this.package, required this.paymentMethod});

  final FloatPackage package;
  final PaymentMethod paymentMethod;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: 'Selected Package',
            value: '${package.floats} Floats',
          ),
          const SizedBox(height: 10),
          _SummaryRow(label: 'Amount', value: 'K${package.amount}'),
          const SizedBox(height: 10),
          _SummaryRow(label: 'Payment Method', value: paymentMethod.name),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
