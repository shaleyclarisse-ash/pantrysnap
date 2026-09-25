import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/pantry_provider.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_screen.dart';

class SavedRecipesScreen extends StatelessWidget {
  const SavedRecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    final saved = provider.storageService.getAllSaved();

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Recipes')),
      body: saved.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bookmark_border,
                        size: 48,
                        color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 12),
                    const Text(
                      'Recipes you save will show up here for offline access while cooking.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: saved.length,
              itemBuilder: (context, index) {
                final recipe = saved[index];
                return RecipeCard(
                  recipe: recipe,
                  isSaved: true,
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
