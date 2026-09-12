import 'package:flutter/material.dart';

/// A small transition screen used while a destination page is being prepared.
class AppLoadingScreen extends StatefulWidget {
  const AppLoadingScreen({super.key, required this.pageBuilder});

  final WidgetBuilder pageBuilder;

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen> {
  Widget? _page;

  @override
  void initState() {
    super.initState();
    _preparePage();
  }

  Future<void> _preparePage() async {
    // Keep the transition visible long enough to feel intentional, while
    // yielding to Flutter so the destination can be laid out smoothly.
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    setState(() => _page = widget.pageBuilder(context));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _page ?? const _LoadingBody(key: ValueKey('loading')),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      key: const ValueKey('loading'),
      backgroundColor: scheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('images/logo.png', width: 76, height: 76),
          ],
        ),
      ),
    );
  }
}
