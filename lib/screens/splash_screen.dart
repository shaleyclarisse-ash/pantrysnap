import 'package:flutter/material.dart';

import 'scan_screen.dart';

/// The app's only splash screen (no separate native OS-level splash).
/// Shown as soon as Flutter boots: the logo pops in, settles, a loading
/// bar fills in underneath, then it hands off to the main scan screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<double> _loadingBarOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Logo pops in with a slight overshoot, like a real app icon animation.
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.4, end: 1.12)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.12, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
    ]).animate(_controller);

    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
    );

    _textOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.8, curve: Curves.easeIn),
    );

    _loadingBarOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
    );

    _controller.forward();

    // Hold on the finished splash for a beat, then hand off to the app.
    Future.delayed(const Duration(milliseconds: 1900), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, animation, __) => const ScanScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF5F9FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoOpacity.value.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                'assets/images/pantrysnap_transparent.png',
                width: 160,
                height: 160,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 28),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _textOpacity.value.clamp(0.0, 1.0),
                  child: child,
                );
              },
              child: Column(
                children: [
                  Text(
                    'PantrySnap',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF13324A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Snap it. Cook it.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF13324A).withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _loadingBarOpacity.value.clamp(0.0, 1.0),
                  child: child,
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 140,
                  height: 5,
                  child: LinearProgressIndicator(
                    backgroundColor:
                    const Color(0xFF13324A).withOpacity(0.12),
                    valueColor: const AlwaysStoppedAnimation(
                        Color(0xFF2E7D32)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}