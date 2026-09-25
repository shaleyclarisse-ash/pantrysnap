import 'package:hive_flutter/hive_flutter.dart';

import '../models/recipe.dart';

/// Wraps Hive so the rest of the app never touches box names / adapters
/// directly. Call [StorageService.init] once in main() before runApp.
class StorageService {
  static const String _boxName = 'saved_recipes';
  late Box<Recipe> _box;

  static final StorageService instance = StorageService._internal();
  StorageService._internal();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();

    Hive.registerAdapter(IngredientAdapter());
    Hive.registerAdapter(RecipeStepModelAdapter());
    Hive.registerAdapter(DifficultyAdapter());
    Hive.registerAdapter(RecipeAdapter());

    _box = await Hive.openBox<Recipe>(_boxName);
    _initialized = true;
  }

  List<Recipe> getAllSaved() {
    return _box.values.toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  Future<void> save(Recipe recipe) async {
    await _box.put(recipe.id, recipe);
  }

  Future<void> remove(String recipeId) async {
    await _box.delete(recipeId);
  }

  bool isSaved(String recipeId) => _box.containsKey(recipeId);

  Stream<BoxEvent> watch() => _box.watch();
}
