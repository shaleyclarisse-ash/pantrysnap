import 'dart:async';

import 'package:flutter/material.dart';

import '../models/recipe.dart';

class CookingModeScreen extends StatefulWidget {
  final Recipe recipe;
  const CookingModeScreen({super.key, required this.recipe});

  @override
  State<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen> {
  int _currentStep = 0;
  Timer? _timer;
  int _secondsRemaining = 0;
  bool _timerRunning = false;

  RecipeStepModel get _step => widget.recipe.steps[_currentStep];
  bool get _isLastStep => _currentStep == widget.recipe.steps.length - 1;
  bool get _isFirstStep => _currentStep == 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resetTimerForCurrentStep() {
    _timer?.cancel();
    _timerRunning = false;
    _secondsRemaining = (_step.durationMinutes ?? 0) * 60;
  }

  void _startTimer() {
    if (_step.durationMinutes == null) return;
    _timer?.cancel();
    setState(() => _timerRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        timer.cancel();
        setState(() => _timerRunning = false);
        return;
      }
      setState(() => _secondsRemaining--);
    });
  }

  void _goToStep(int index) {
    setState(() {
      _currentStep = index.clamp(0, widget.recipe.steps.length - 1);
      _resetTimerForCurrentStep();
    });
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final totalSteps = widget.recipe.steps.length;

    if (_currentStep == 0 && _secondsRemaining == 0 && !_timerRunning) {
      _secondsRemaining = (_step.durationMinutes ?? 0) * 60;
    }

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(widget.recipe.title, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'STEP ${_currentStep + 1} OF $totalSteps',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: scheme.primary, letterSpacing: 1.2),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_currentStep + 1) / totalSteps,
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(scheme.primary),
              ),
              const Spacer(),
              Text(
                _step.instruction,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700, height: 1.3),
              ),
              const SizedBox(height: 32),
              if (_step.durationMinutes != null) ...[
                Text(
                  _formatTime(_secondsRemaining),
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: Icon(_timerRunning
                      ? Icons.pause
                      : Icons.play_arrow_rounded),
                  label: Text(_timerRunning ? 'Pause timer' : 'Start timer'),
                  onPressed: () {
                    if (_timerRunning) {
                      _timer?.cancel();
                      setState(() => _timerRunning = false);
                    } else {
                      _startTimer();
                    }
                  },
                ),
              ],
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                      onPressed:
                      _isFirstStep ? null : () => _goToStep(_currentStep - 1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      icon: Icon(_isLastStep
                          ? Icons.check
                          : Icons.arrow_forward),
                      label: Text(_isLastStep ? 'Done' : 'Next'),
                      onPressed: () {
                        if (_isLastStep) {
                          Navigator.pop(context);
                        } else {
                          _goToStep(_currentStep + 1);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
