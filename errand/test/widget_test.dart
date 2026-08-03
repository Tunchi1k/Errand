import 'package:errand/pages/Floats/buy_floats.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FloatBalanceCard shows active balance messaging', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FloatBalanceCard(balance: 10))),
    );

    expect(find.text('Current Float Balance'), findsOneWidget);
    expect(find.text('10 Floats Remaining'), findsOneWidget);
    expect(find.text('Eligible to accept errands'), findsOneWidget);
  });

  testWidgets('FloatPackageCard renders package details and popular badge', (
    tester,
  ) async {
    var tapped = false;
    const package = FloatPackage(
      floats: 25,
      description: 'Access to approximately 25 errands',
      amount: 60,
      isMostPopular: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FloatPackageCard(
            package: package,
            onBuy: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('25 Floats'), findsOneWidget);
    expect(find.text('Access to approximately 25 errands'), findsOneWidget);
    expect(find.text('K60'), findsOneWidget);
    expect(find.text('Most Popular'), findsOneWidget);

    await tester.tap(find.text('Buy Package'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('PaymentMethodBottomSheet shows summary after selection', (
    tester,
  ) async {
    const package = FloatPackage(
      floats: 25,
      description: 'Access to approximately 25 errands',
      amount: 60,
      isMostPopular: true,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PaymentMethodBottomSheet(package: package)),
      ),
    );

    expect(find.text('Choose Payment Method'), findsOneWidget);
    expect(find.text('MTN Mobile Money'), findsOneWidget);
    expect(find.text('Airtel Money'), findsOneWidget);
    expect(find.text('Zamtel Kwacha'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);

    await tester.tap(find.text('MTN Mobile Money'));
    await tester.pumpAndSettle();

    expect(find.text('Selected Package'), findsOneWidget);
    expect(find.text('25 Floats'), findsOneWidget);
    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('K60'), findsOneWidget);
    expect(find.text('Payment Method'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
