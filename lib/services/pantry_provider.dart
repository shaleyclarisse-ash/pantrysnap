import 'package:flutter/foundation.dart';

import '../models/recipe.dart';
import 'gemini_service.dart';
import 'image_service.dart';
import 'storage_service.dart';

enum ScanStatus {
  idle,
  imageSelected,
  detecting,
  ingredientsReady,
  loading,
  success,
  error
}

const List<String> kAvailableDietaryFilters = [
  'Vegan',
  'Vegetarian',
  'High-Protein',
  'Low-Carb',
  'Gluten-Free',
  'Dairy-Free',
];

const List<int> kTimeFilterOptions = [15, 20, 30, 45];

class PantryProvider extends ChangeNotifier {
  final GeminiService geminiService;
  final ImageService imageService = ImageService();
  final StorageService storageService = StorageService.instance;

  PantryProvider({required this.geminiService});

  ScanStatus status = ScanStatus.idle;
  String? errorMessage;

  Uint8List? selectedImageBytes;
  String? selectedImageMime;

  // Ingredients detected from the photo, editable by the user before
  // recipes are generated (the "confirm ingredients" step).
  List<Ingredient> detectedIngredients = [];

  final Set<String> selectedDietary = {};
  int? selectedMaxMinutes;
  int servings = 2;
  String cuisine = '';

  List<Recipe> results = [];

  Future<void> pickImage({required bool fromCamera}) async {
    try {
      final captured = fromCamera
          ? await imageService.pickFromCamera()
          : await imageService.pickFromGallery();
      if (captured == null) return;

      selectedImageBytes = captured.bytes;
      selectedImageMime = captured.mimeType;
      status = ScanStatus.imageSelected;
      errorMessage = null;
      detectedIngredients = [];
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      status = ScanStatus.error;
      notifyListeners();
    }
  }

  void toggleDietary(String label) {
    if (selectedDietary.contains(label)) {
      selectedDietary.remove(label);
    } else {
      selectedDietary.add(label);
    }
    notifyListeners();
  }

  void setMaxMinutes(int? minutes) {
    selectedMaxMinutes = (selectedMaxMinutes == minutes) ? null : minutes;
    notifyListeners();
  }

  void setServings(int value) {
    servings = value.clamp(1, 12);
    notifyListeners();
  }

  void setCuisine(String value) {
    cuisine = value;
    notifyListeners();
  }

  void clearImage() {
    selectedImageBytes = null;
    selectedImageMime = null;
    status = ScanStatus.idle;
    results = [];
    detectedIngredients = [];
    notifyListeners();
  }

  RecipeFilters _currentFilters() => RecipeFilters(
    dietary: selectedDietary,
    maxTotalMinutes: selectedMaxMinutes,
    servings: servings,
    cuisine: cuisine.isEmpty ? null : cuisine,
  );

  // ---------------- Step 1: detect ingredients ----------------

  Future<void> detectIngredients() async {
    if (selectedImageBytes == null || selectedImageMime == null) return;

    status = ScanStatus.detecting;
    errorMessage = null;
    notifyListeners();

    try {
      final ingredients = await geminiService.detectIngredients(
        imageBytes: selectedImageBytes!,
        mimeType: selectedImageMime!,
      );
      detectedIngredients = ingredients;
      status = ScanStatus.ingredientsReady;
    } catch (e) {
      errorMessage = e is GeminiPantryException ? e.message : e.toString();
      status = ScanStatus.error;
    }
    notifyListeners();
  }

  // Editing the confirmed ingredient list before generating recipes.
  void addDetectedIngredient(Ingredient ingredient) {
    detectedIngredients = [...detectedIngredients, ingredient];
    notifyListeners();
  }

  void removeDetectedIngredient(int index) {
    detectedIngredients = List.of(detectedIngredients)..removeAt(index);
    notifyListeners();
  }

  void updateDetectedIngredient(int index, Ingredient updated) {
    detectedIngredients = List.of(detectedIngredients);
    detectedIngredients[index] = updated;
    notifyListeners();
  }

  // ---------------- Step 2: generate recipes ----------------

  /// Generates recipes from the confirmed (possibly edited) ingredient
  /// list rather than re-sending the photo.
  Future<void> generateFromConfirmedIngredients() async {
    status = ScanStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final recipes = await geminiService.generateRecipesFromIngredients(
        ingredients: detectedIngredients,
        filters: _currentFilters(),
      );
      results = recipes;
      status = ScanStatus.success;
      for (final recipe in recipes) {
        await storageService.logHistory(recipe);
      }
    } catch (e) {
      errorMessage = e is GeminiPantryException ? e.message : e.toString();
      status = ScanStatus.error;
    }
    notifyListeners();
  }

  /// Legacy one-shot path (image -> recipes directly, no confirm step).
  /// Kept for flexibility / a "skip confirmation" shortcut.
  Future<void> analyzePantry() async {
    if (selectedImageBytes == null || selectedImageMime == null) return;

    status = ScanStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final recipes = await geminiService.generateRecipesFromImage(
        imageBytes: selectedImageBytes!,
        mimeType: selectedImageMime!,
        filters: _currentFilters(),
      );

      results = recipes;
      status = ScanStatus.success;
      for (final recipe in recipes) {
        await storageService.logHistory(recipe);
      }
    } catch (e) {
      errorMessage = e is GeminiPantryException ? e.message : e.toString();
      status = ScanStatus.error;
    }
    notifyListeners();
  }

  Future<void> toggleSaveRecipe(Recipe recipe) async {
    if (storageService.isSaved(recipe.id)) {
      await storageService.remove(recipe.id);
    } else {
      await storageService.save(recipe);
    }
    notifyListeners();
  }

  bool isRecipeSaved(String id) => storageService.isSaved(id);
}
