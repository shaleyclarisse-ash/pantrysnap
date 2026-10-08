import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../services/pantry_provider.dart';
import '../services/storage_service.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_screen.dart';

class RecipeHistoryScreen extends StatefulWidget {
  const RecipeHistoryScreen({super.key});

  @override
  State<RecipeHistoryScreen> createState() => _RecipeHistoryScreenState();
}

class _RecipeHistoryScreenState extends State<RecipeHistoryScreen> {
  late List<Recipe> history;

  @override
  void initState() {
    super.initState();
    history = StorageService.instance.getHistory();
  }

  void _refresh() {
    setState(() => history = StorageService.instance.getHistory());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear history',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear history?'),
                    content: const Text(
                        'This removes every recently viewed or generated recipe.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await StorageService.instance.clearHistory();
                  _refresh();
                }
              },
            ),
        ],
      ),
      body: history.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history,
                  size: 48, color: theme.colorScheme.outline),
              const SizedBox(height: 12),
              const Text(
                'Recipes you generate or open will show up here.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: history.length,
        itemBuilder: (context, index) {
          final recipe = history[index];
          return RecipeCard(
            recipe: recipe,
            isSaved: provider.isRecipeSaved(recipe.id),
            onToggleSave: () =>
                context.read<PantryProvider>().toggleSaveRecipe(recipe),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RecipeDetailScreen(recipe: recipe),
              ),
            ),
          );
        },
      ),
    );
  }
}
