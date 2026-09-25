import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../services/pantry_provider.dart';
import '../widgets/recipe_card.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<PantryProvider>();
    final saved = provider.isRecipeSaved(recipe.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () =>
                context.read<PantryProvider>().toggleSaveRecipe(recipe),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(recipe.description, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.timer_outlined, size: 16),
                label: Text('Prep ${recipe.prepTimeMinutes}m · Cook ${recipe.cookTimeMinutes}m'),
              ),
              Chip(
                avatar: const Icon(Icons.restaurant_outlined, size: 16),
                label: Text('${recipe.servings} servings'),
              ),
              Chip(
                avatar: Icon(Icons.bar_chart,
                    size: 16, color: difficultyColor(recipe.difficulty, context)),
                label: Text(difficultyLabel(recipe.difficulty)),
              ),
            ],
          ),
          if (recipe.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: recipe.tags
                  .map((t) => Chip(
                        label: Text(t),
                        backgroundColor: theme.colorScheme.primaryContainer,
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 24),
          _SectionHeader(
              icon: Icons.check_circle_outline,
              title: 'Ingredients you have (${recipe.ingredients.length})'),
          const SizedBox(height: 8),
          ...recipe.ingredients.map((i) => _IngredientTile(ingredient: i)),
          if (recipe.missingIngredients.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionHeader(
                icon: Icons.shopping_cart_outlined,
                title: 'You may need to buy (${recipe.missingIngredients.length})',
                color: theme.colorScheme.tertiary),
            const SizedBox(height: 8),
            ...recipe.missingIngredients
                .map((i) => _IngredientTile(ingredient: i, missing: true)),
          ],
          const SizedBox(height: 24),
          _SectionHeader(icon: Icons.list_alt, title: 'Instructions'),
          const SizedBox(height: 8),
          ...recipe.steps.map((s) => _StepTile(step: s)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;
  const _SectionHeader({required this.icon, required this.title, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _IngredientTile extends StatelessWidget {
  final Ingredient ingredient;
  final bool missing;
  const _IngredientTile({required this.ingredient, this.missing = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            missing ? Icons.remove_shopping_cart_outlined : Icons.circle,
            size: missing ? 16 : 6,
            color: missing
                ? theme.colorScheme.tertiary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text('${ingredient.name} — ${ingredient.quantity}',
                style: theme.textTheme.bodyMedium),
          ),
          if (ingredient.isPantryStaple)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text('staple',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.outline)),
            ),
        ],
      ),
    );
  }
}

/// Expandable instruction tile, per the "Dynamic Recipe Cards UI" spec.
class _StepTile extends StatefulWidget {
  final RecipeStepModel step;
  const _StepTile({required this.step});

  @override
  State<_StepTile> createState() => _StepTileState();
}

class _StepTileState extends State<_StepTile> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        initiallyExpanded: _expanded,
        onExpansionChanged: (v) => setState(() => _expanded = v),
        leading: CircleAvatar(
          radius: 14,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text('${widget.step.stepNumber}',
              style: theme.textTheme.labelLarge),
        ),
        title: Text(
          widget.step.durationMinutes != null
              ? 'Step ${widget.step.stepNumber} · ${widget.step.durationMinutes} min'
              : 'Step ${widget.step.stepNumber}',
          style: theme.textTheme.labelLarge,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(widget.step.instruction,
                  style: theme.textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}
