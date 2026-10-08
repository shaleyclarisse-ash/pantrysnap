import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../services/pantry_provider.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_screen.dart';

class SavedRecipesScreen extends StatefulWidget {
  const SavedRecipesScreen({super.key});

  @override
  State<SavedRecipesScreen> createState() => _SavedRecipesScreenState();
}

class _SavedRecipesScreenState extends State<SavedRecipesScreen> {
  String _query = '';
  Difficulty? _difficultyFilter;
  int? _maxMinutesFilter;
  bool _showSearch = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    final allSaved = provider.storageService.getAllSaved();

    final filtered = allSaved.where((recipe) {
      if (_query.trim().isNotEmpty) {
        final q = _query.toLowerCase();
        final matchesTitle = recipe.title.toLowerCase().contains(q);
        final matchesIngredient = recipe.ingredients
            .any((i) => i.name.toLowerCase().contains(q));
        final matchesTag =
        recipe.tags.any((t) => t.toLowerCase().contains(q));
        if (!matchesTitle && !matchesIngredient && !matchesTag) return false;
      }
      if (_difficultyFilter != null &&
          recipe.difficulty != _difficultyFilter) {
        return false;
      }
      if (_maxMinutesFilter != null &&
          recipe.totalTimeMinutes > _maxMinutesFilter!) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Recipes'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.search_off : Icons.search),
            onPressed: () => setState(() => _showSearch = !_showSearch),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search by name, ingredient, or tag',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...Difficulty.values.map((d) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(difficultyLabel(d)),
                        selected: _difficultyFilter == d,
                        onSelected: (selected) => setState(() =>
                        _difficultyFilter = selected ? d : null),
                      ),
                    )),
                    ...[15, 30, 45].map((minutes) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('Under ${minutes}m'),
                        selected: _maxMinutesFilter == minutes,
                        onSelected: (selected) => setState(() =>
                        _maxMinutesFilter = selected ? minutes : null),
                      ),
                    )),
                  ],
                ),
              ),
            ),
          Expanded(
            child: allSaved.isEmpty
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
                : filtered.isEmpty
                ? Center(
              child: Text(
                'No saved recipes match your search.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final recipe = filtered[index];
                return RecipeCard(
                  recipe: recipe,
                  isSaved: true,
                  onToggleSave: () => context
                      .read<PantryProvider>()
                      .toggleSaveRecipe(recipe),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RecipeDetailScreen(recipe: recipe),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
