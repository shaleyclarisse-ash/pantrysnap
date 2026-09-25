import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/pantry_provider.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_screen.dart';

class RecipeListScreen extends StatelessWidget {
  const RecipeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    final recipes = provider.results;

    return Scaffold(
      appBar: AppBar(title: const Text('Recipes for you')),
      body: recipes.isEmpty
          ? const Center(child: Text('No recipes generated yet.'))
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
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
