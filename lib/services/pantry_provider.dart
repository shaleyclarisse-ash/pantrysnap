import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../models/recipe.dart';
import 'gemini_service.dart';
import 'image_service.dart';
import 'storage_service.dart';

enum ScanStatus { idle, imageSelected, loading, success, error }

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

  final Set<String> selectedDietary = {};
  int? selectedMaxMinutes;
  int servings = 2;

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

  void clearImage() {
    selectedImageBytes = null;
    selectedImageMime = null;
    status = ScanStatus.idle;
    results = [];
    notifyListeners();
  }

  Future<void> analyzePantry() async {
    if (selectedImageBytes == null || selectedImageMime == null) return;

    status = ScanStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final filters = RecipeFilters(
        dietary: selectedDietary,
        maxTotalMinutes: selectedMaxMinutes,
        servings: servings,
      );

      final recipes = await geminiService.generateRecipesFromImage(
        imageBytes: selectedImageBytes!,
        mimeType: selectedImageMime!,
        filters: filters,
      );

      results = recipes;
      status = ScanStatus.success;
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
