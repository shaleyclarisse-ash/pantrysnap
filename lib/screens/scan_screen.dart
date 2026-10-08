import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/pantry_provider.dart';
import '../widgets/filter_chips.dart';
import 'loading_screen.dart';
import 'meal_planner_screen.dart';
import 'recipe_history_screen.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('PantrySnap'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RecipeHistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Meal planner',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MealPlannerScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(builder: (context) {
                final name = AuthService.instance.currentUser?.displayName;
                final firstName =
                (name != null && name.trim().isNotEmpty)
                    ? name.trim().split(' ').first
                    : null;
                return Text(
                  firstName != null ? 'Hey $firstName 👋' : 'Hey there 👋',
                  style: Theme.of(context).textTheme.headlineSmall,
                );
              }),
              const SizedBox(height: 4),
              Text(
                "What's in your kitchen today?",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              _PhotoPreview(bytes: provider.selectedImageBytes),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Camera'),
                      onPressed: () => context
                          .read<PantryProvider>()
                          .pickImage(fromCamera: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Gallery'),
                      onPressed: () => context
                          .read<PantryProvider>()
                          .pickImage(fromCamera: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text('Dietary preferences',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const DietaryFilterRow(),
              const SizedBox(height: 20),
              Text('Time limit', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const TimeFilterRow(),
              const SizedBox(height: 20),
              Text('Servings', style: Theme.of(context).textTheme.titleMedium),
              const ServingsStepper(),
              const SizedBox(height: 28),
              if (provider.status == ScanStatus.error &&
                  provider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    provider.errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Find Recipes'),
                  onPressed: provider.selectedImageBytes == null
                      ? null
                      : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoadingScreen(
                              mode: LoadingMode.detectIngredients)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  final Uint8List? bytes;
  const _PhotoPreview({required this.bytes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surfaceContainerHighest,
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: bytes == null
            ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.kitchen_outlined,
                  size: 48, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 8),
              Text('No photo yet',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        )
            : Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(bytes!, fit: BoxFit.cover),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black.withValues(alpha: 0.5),
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () =>
                      context.read<PantryProvider>().clearImage(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
