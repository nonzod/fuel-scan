// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fuel_station.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FuelStationAdapter extends TypeAdapter<FuelStation> {
  @override
  final int typeId = 0;

  @override
  FuelStation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FuelStation(
      id: fields[0] as String,
      name: fields[1] as String,
      brand: fields[2] as String,
      address: fields[3] as String,
      city: fields[4] as String,
      province: fields[5] as String,
      latitude: fields[6] as double,
      longitude: fields[7] as double,
      prices: (fields[8] as List).cast<FuelPrice>(),
      lastUpdate: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, FuelStation obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.brand)
      ..writeByte(3)
      ..write(obj.address)
      ..writeByte(4)
      ..write(obj.city)
      ..writeByte(5)
      ..write(obj.province)
      ..writeByte(6)
      ..write(obj.latitude)
      ..writeByte(7)
      ..write(obj.longitude)
      ..writeByte(8)
      ..write(obj.prices)
      ..writeByte(9)
      ..write(obj.lastUpdate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FuelStationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
