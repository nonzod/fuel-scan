// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fuel_price.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FuelPriceAdapter extends TypeAdapter<FuelPrice> {
  @override
  final int typeId = 1;

  @override
  FuelPrice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FuelPrice(
      id: fields[0] as String,
      fuelType: fields[1] as String,
      price: fields[2] as double,
      isSelf: fields[3] as bool,
      updatedAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FuelPrice obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fuelType)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.isSelf)
      ..writeByte(4)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FuelPriceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
