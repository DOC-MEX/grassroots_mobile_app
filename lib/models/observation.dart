import 'package:hive/hive.dart';

part 'observation.g.dart';

@HiveType(typeId: 0)
class Observation extends HiveObject {
  @HiveField(0)
  String plotId;

  @HiveField(1)
  String trait;

  @HiveField(2)
  String value;

  @HiveField(3)
  String? notes;

  @HiveField(4)
  String date;

  @HiveField(5)
  String syncStatus;

  Observation({
    required this.plotId,
    required this.trait,
    required this.value,
    this.notes,
    required this.date,
    required this.syncStatus,
  });

  Map<String, dynamic> toJson() {
    return {
      'plotId': plotId,
      'trait': trait,
      'value': value,
      'notes': notes,
      'date': date,
      'syncStatus': syncStatus,
    };
  }
}
