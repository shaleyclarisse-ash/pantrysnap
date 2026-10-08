import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/pantry_provider.dart';
import 'ingredient_confirm_screen.dart';
import 'recipe_list_screen.dart';

enum LoadingMode { detectIngredients, generateRecipes }

/// Full-screen animated loading state shown while Gemini is working.
/// Reused for both phases of the scan flow:
///  - detectIngredients: identifies what's in the photo, then hands off
///    to IngredientConfirmScreen for the user to review/edit
///  - generateRecipes: turns the confirmed ingredient list into recipes,
///    then hands off to RecipeListScreen
class LoadingScreen extends StatefulWidget {
  final LoadingMode mode;
  const LoadingScreen({super.key, this.mode = LoadingMode.generateRecipes});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  static const _detectMessages = [
    'Scanning your pantry...',
    'Spotting fresh ingredients...',
    'Reading labels and packaging...',
    'Double-checking the details...',
  ];

  static const _generateMessages = [
    'Consulting the recipe gods...',
    'Weighing flavor combinations...',
    'Checking what pairs well...',
    'Plating up some ideas...',
  ];

  late final AnimationController _pulseController;
  late final AnimationController _rotateController;
  int _messageIndex = 0;
  Timer? _messageTimer;
  bool _hasStarted = false;

  List<String> get _messages => widget.mode == LoadingMode.detectIngredients
      ? _detectMessages
      : _generateMessages;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _messageTimer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (!mounted) return;
      setState(() => _messageIndex = (_messageIndex + 1) % _messages.length);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_hasStarted) {
      _hasStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<PantryProvider>();
        if (widget.mode == LoadingMode.detectIngredients) {
          provider.detectIngredients();
        } else {
          provider.generateFromConfirmedIngredients();
        }
      });
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Consumer<PantryProvider>(
            builder: (context, provider, _) {
              final targetStatus = widget.mode == LoadingMode.detectIngredients
                  ? ScanStatus.ingredientsReady
                  : ScanStatus.success;

              if (provider.status == targetStatus) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  final nextScreen = widget.mode == LoadingMode.detectIngredients
                      ? const IngredientConfirmScreen()
                      : const RecipeListScreen();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => nextScreen),
                  );
                });
              }

              if (provider.status == ScanStatus.error) {
                return _ErrorState(message: provider.errorMessage);
              }

              return _LoadingContent(
                pulseController: _pulseController,
                rotateController: _rotateController,
                message: _messages[_messageIndex],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoadingContent extends StatelessWidget {
  final AnimationController pulseController;
  final AnimationController rotateController;
  final String message;

  const _LoadingContent({
    required this.pulseController,
    required this.rotateController,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  RotationTransition(
                    turns: rotateController,
                    child: CustomPaint(
                      size: const Size(180, 180),
                      painter: _OrbitDotsPainter(color: scheme.primary),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: pulseController,
                    builder: (context, child) {
                      final scale = 0.9 + (pulseController.value * 0.15);
                      final opacity = 0.15 + (pulseController.value * 0.15);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.primary.withValues(alpha: opacity),
                          ),
                        ),
                      );
                    },
                  ),
                  AnimatedBuilder(
                    animation: pulseController,
                    builder: (context, child) {
                      final scale = 1.0 + (pulseController.value * 0.08);
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.primaryContainer,
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.25),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        size: 40,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.25),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                message,
                key: ValueKey(message),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 200,
                height: 6,
                child: LinearProgressIndicator(
                  backgroundColor: scheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(scheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This usually takes a few seconds',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrbitDotsPainter extends CustomPainter {
  final Color color;
  _OrbitDotsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 6;
    const dotCount = 6;

    for (int i = 0; i < dotCount; i++) {
      final angle = (2 * math.pi / dotCount) * i;
      final dotCenter = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final paint = Paint()
        ..color = color.withValues(alpha: 0.25 + (0.55 * (i / dotCount)));
      canvas.drawCircle(dotCenter, 5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitDotsPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ErrorState extends StatelessWidget {
  final String? message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'Please try again.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}
