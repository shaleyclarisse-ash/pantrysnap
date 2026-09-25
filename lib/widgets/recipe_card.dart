import 'package:flutter/material.dart';

import '../models/recipe.dart';

Color difficultyColor(Difficulty d, BuildContext context) {
  switch (d) {
    case Difficulty.easy:
      return Colors.green;
    case Difficulty.medium:
      return Colors.orange;
    case Difficulty.hard:
      return Colors.red;
  }
}

String difficultyLabel(Difficulty d) {
  switch (d) {
    case Difficulty.easy:
      return 'Easy';
    case Difficulty.medium:
      return 'Medium';
    case Difficulty.hard:
      return 'Hard';
  }
}

/// A summary card for a recipe, used in list views. Tapping it opens
/// the full recipe detail screen.
class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final bool isSaved;
  final VoidCallback onToggleSave;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    required this.isSaved,
    required this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      recipe.title,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: isSaved ? theme.colorScheme.primary : null,
                    ),
                    onPressed: onToggleSave,
                    tooltip: isSaved ? 'Remove from saved' : 'Save recipe',
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                recipe.description,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoPill(
                    icon: Icons.timer_outlined,
                    label: '${recipe.totalTimeMinutes} min',
                  ),
                  _InfoPill(
                    icon: Icons.restaurant_outlined,
                    label: '${recipe.servings} servings',
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: difficultyColor(recipe.difficulty, context)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      difficultyLabel(recipe.difficulty),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: difficultyColor(recipe.difficulty, context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (recipe.missingIngredients.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shopping_cart_outlined,
                        size: 16, color: theme.colorScheme.tertiary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Missing: ${recipe.missingIngredients.map((e) => e.name).join(", ")}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.tertiary),
                      ),
                    ),
                  ],
                ),
              ],
              if (recipe.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: recipe.tags
                      .map((t) => Chip(
                            label: Text(t, style: theme.textTheme.labelSmall),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}
