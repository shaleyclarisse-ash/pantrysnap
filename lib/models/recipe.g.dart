// GENERATED CODE - manually written to match hive_generator output.
// If you run `flutter pub run build_runner build --delete-conflicting-outputs`
// this file will be regenerated automatically from the @HiveType annotations
// in recipe.dart - either approach works.

part of 'recipe.dart';

class IngredientAdapter extends TypeAdapter<Ingredient> {
  @override
  final int typeId = 0;

  @override
  Ingredient read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Ingredient(
      name: fields[0] as String,
      quantity: fields[1] as String,
      isPantryStaple: fields[2] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, Ingredient obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.isPantryStaple);
  }
}

class RecipeStepModelAdapter extends TypeAdapter<RecipeStepModel> {
  @override
  final int typeId = 1;

  @override
  RecipeStepModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecipeStepModel(
      stepNumber: fields[0] as int,
      instruction: fields[1] as String,
      durationMinutes: fields[2] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, RecipeStepModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.stepNumber)
      ..writeByte(1)
      ..write(obj.instruction)
      ..writeByte(2)
      ..write(obj.durationMinutes);
  }
}

class DifficultyAdapter extends TypeAdapter<Difficulty> {
  @override
  final int typeId = 2;

  @override
  Difficulty read(BinaryReader reader) {
    final index = reader.readByte();
    return Difficulty.values[index];
  }

  @override
  void write(BinaryWriter writer, Difficulty obj) {
    writer.writeByte(obj.index);
  }
}

class RecipeAdapter extends TypeAdapter<Recipe> {
  @override
  final int typeId = 3;

  @override
  Recipe read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Recipe(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      prepTimeMinutes: fields[3] as int,
      cookTimeMinutes: fields[4] as int,
      difficulty: fields[5] as Difficulty,
      servings: fields[6] as int,
      ingredients: (fields[7] as List).cast<Ingredient>(),
      missingIngredients: (fields[8] as List).cast<Ingredient>(),
      steps: (fields[9] as List).cast<RecipeStepModel>(),
      tags: (fields[10] as List).cast<String>(),
      savedAt: fields[11] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Recipe obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.prepTimeMinutes)
      ..writeByte(4)
      ..write(obj.cookTimeMinutes)
      ..writeByte(5)
      ..write(obj.difficulty)
      ..writeByte(6)
      ..write(obj.servings)
      ..writeByte(7)
      ..write(obj.ingredients)
      ..writeByte(8)
      ..write(obj.missingIngredients)
      ..writeByte(9)
      ..write(obj.steps)
      ..writeByte(10)
      ..write(obj.tags)
      ..writeByte(11)
      ..write(obj.savedAt);
  }
}
