import 'package:flutter/widgets.dart';

/// Shared layout values used to keep screens comfortable on small phones and
/// avoid excessively wide content on tablets and desktop windows.
class Responsive {
  const Responsive._();

  static double width(BuildContext context, double value) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return value.clamp(0, screenWidth);
  }

  static double horizontalPadding(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    if (screenWidth < 360) return 16;
    if (screenWidth < 600) return 20;
    return 32;
  }

  static double contentMaxWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 600 ? double.infinity : 620;
  }
}
