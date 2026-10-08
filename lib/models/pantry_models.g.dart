// GENERATED CODE - manually written to match hive_generator output.
// Regenerable via `flutter pub run build_runner build --delete-conflicting-outputs`.

part of 'pantry_models.dart';

class PantryItemAdapter extends TypeAdapter<PantryItem> {
  @override
  final int typeId = 4;

  @override
  PantryItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PantryItem(
      id: fields[0] as String,
      name: fields[1] as String,
      quantity: fields[2] as String,
      category: fields[3] as String? ?? 'Other',
      dateAdded: fields[4] as DateTime,
      expiryDate: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PantryItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.dateAdded)
      ..writeByte(5)
      ..write(obj.expiryDate);
  }
}

class ShoppingItemAdapter extends TypeAdapter<ShoppingItem> {
  @override
  final int typeId = 5;

  @override
  ShoppingItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShoppingItem(
      id: fields[0] as String,
      name: fields[1] as String,
      quantity: fields[2] as String,
      checked: fields[3] as bool? ?? false,
      sourceRecipeTitle: fields[4] as String?,
      dateAdded: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ShoppingItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.checked)
      ..writeByte(4)
      ..write(obj.sourceRecipeTitle)
      ..writeByte(5)
      ..write(obj.dateAdded);
  }
}

class MealPlanEntryAdapter extends TypeAdapter<MealPlanEntry> {
  @override
  final int typeId = 6;

  @override
  MealPlanEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MealPlanEntry(
      id: fields[0] as String,
      dayOfWeek: fields[1] as int,
      mealType: fields[2] as String,
      recipe: fields[3] as Recipe,
    );
  }

  @override
  void write(BinaryWriter writer, MealPlanEntry obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dayOfWeek)
      ..writeByte(2)
      ..write(obj.mealType)
      ..writeByte(3)
      ..write(obj.recipe);
  }
}
