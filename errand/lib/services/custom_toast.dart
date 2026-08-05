import 'dart:async';
import 'package:flutter/material.dart';

class CustomToast {
  const CustomToast._();

  static void show(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastOverlay(message: message, onFinished: entry.remove),
    );
    overlay.insert(entry);
  }
}

class _ToastOverlay extends StatefulWidget {
  const _ToastOverlay({required this.message, required this.onFinished});
  final String message;
  final VoidCallback onFinished;

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay> {
  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _visible = true);
      _timer = Timer(const Duration(milliseconds: 2600), _dismiss);
    });
  }

  void _dismiss() {
    if (!mounted) return;
    setState(() => _visible = false);
    _timer = Timer(const Duration(milliseconds: 350), widget.onFinished);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: IgnorePointer(
      child: Center(
        child: AnimatedOpacity(
          opacity: _visible ? 1 : 0,
          duration: const Duration(milliseconds: 250),
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(widget.message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, height: 1.35)),
            ),
          ),
        ),
      ),
    ),
  );
}
