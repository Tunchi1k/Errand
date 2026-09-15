import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

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
        title: Text(
          'Searching for Runner',
          style: GoogleFonts.archivoBlack(fontSize: 22, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder:
                        (context, child) => Container(
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
                        ),
                    child: const Center(
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor: Color.fromARGB(255, 0, 63, 97),
                        child: Icon(
                          Iconsax.routing_2,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 34),
              const Text(
                'Your errand is live',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 36),
                child: Text(
                  'Runnerss can now see this request and you will be notified when a runner accepts it.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 15),
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
      ),
    );
  }
}
