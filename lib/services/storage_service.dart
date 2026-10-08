import 'package:hive_flutter/hive_flutter.dart';

import '../models/pantry_models.dart';
import '../models/recipe.dart';

/// Wraps Hive so the rest of the app never touches box names / adapters
/// directly. Call [StorageService.init] once in main() before runApp.
///
/// Boxes:
///  - saved_recipes   : recipes the user explicitly bookmarked
///  - recipe_history   : every recipe generated or opened (auto-logged)
///  - pantry_items     : My Pantry inventory
///  - shopping_items    : Shopping List
///  - meal_plan        : weekly Meal Planner entries
///  - settings         : profile + app preferences (dynamic key/value)
class StorageService {
  static const String _savedBoxName = 'saved_recipes';
  static const String _historyBoxName = 'recipe_history';
  static const String _pantryBoxName = 'pantry_items';
  static const String _shoppingBoxName = 'shopping_items';
  static const String _mealPlanBoxName = 'meal_plan';
  static const String _settingsBoxName = 'settings';

  late Box<Recipe> _savedBox;
  late Box<Recipe> _historyBox;
  late Box<PantryItem> _pantryBox;
  late Box<ShoppingItem> _shoppingBox;
  late Box<MealPlanEntry> _mealPlanBox;
  late Box _settingsBox;

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
    Hive.registerAdapter(PantryItemAdapter());
    Hive.registerAdapter(ShoppingItemAdapter());
    Hive.registerAdapter(MealPlanEntryAdapter());

    _savedBox = await Hive.openBox<Recipe>(_savedBoxName);
    _historyBox = await Hive.openBox<Recipe>(_historyBoxName);
    _pantryBox = await Hive.openBox<PantryItem>(_pantryBoxName);
    _shoppingBox = await Hive.openBox<ShoppingItem>(_shoppingBoxName);
    _mealPlanBox = await Hive.openBox<MealPlanEntry>(_mealPlanBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);

    _initialized = true;
  }

  // ---------------- Saved recipes ----------------

  List<Recipe> getAllSaved() {
    return _savedBox.values.toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  Future<void> save(Recipe recipe) async => _savedBox.put(recipe.id, recipe);

  Future<void> remove(String recipeId) async => _savedBox.delete(recipeId);

  bool isSaved(String recipeId) => _savedBox.containsKey(recipeId);

  Stream<BoxEvent> watch() => _savedBox.watch();

  // ---------------- History ----------------

  /// Logs a recipe as viewed/generated. Keeps at most the most recent 100
  /// entries so the box doesn't grow unbounded.
  Future<void> logHistory(Recipe recipe) async {
    await _historyBox.put(
        '${recipe.id}_${DateTime.now().millisecondsSinceEpoch}', recipe);
    if (_historyBox.length > 100) {
      final oldestKey = _historyBox.keys.first;
      await _historyBox.delete(oldestKey);
    }
  }

  List<Recipe> getHistory() {
    return _historyBox.values.toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  Future<void> clearHistory() async => _historyBox.clear();

  // ---------------- My Pantry ----------------

  List<PantryItem> getPantryItems() {
    return _pantryBox.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<void> savePantryItem(PantryItem item) async =>
      _pantryBox.put(item.id, item);

  Future<void> removePantryItem(String id) async => _pantryBox.delete(id);

  // ---------------- Shopping List ----------------

  List<ShoppingItem> getShoppingItems() {
    return _shoppingBox.values.toList()
      ..sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
  }

  Future<void> saveShoppingItem(ShoppingItem item) async =>
      _shoppingBox.put(item.id, item);

  Future<void> removeShoppingItem(String id) async =>
      _shoppingBox.delete(id);

  Future<void> clearCheckedShoppingItems() async {
    final checkedKeys = _shoppingBox.values
        .where((item) => item.checked)
        .map((item) => item.id)
        .toList();
    for (final key in checkedKeys) {
      await _shoppingBox.delete(key);
    }
  }

  // ---------------- Meal Planner ----------------

  List<MealPlanEntry> getMealPlan() => _mealPlanBox.values.toList();

  Future<void> saveMealPlanEntry(MealPlanEntry entry) async =>
      _mealPlanBox.put(entry.id, entry);

  Future<void> removeMealPlanEntry(String id) async =>
      _mealPlanBox.delete(id);

  // ---------------- Settings / Profile ----------------

  T? getSetting<T>(String key, {T? defaultValue}) {
    final value = _settingsBox.get(key, defaultValue: defaultValue);
    return value as T?;
  }

  Future<void> setSetting(String key, dynamic value) async =>
      _settingsBox.put(key, value);
}
