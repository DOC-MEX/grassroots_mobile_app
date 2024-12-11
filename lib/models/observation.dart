import 'package:hive/hive.dart';

part 'observation.g.dart'; // Required for Hive type adapter generation

@HiveType(typeId: 0)
class Observation extends HiveObject {
  @HiveField(0)
  String plotId;

  @HiveField(1)
  String trait;

  @HiveField(2)
  String value;

  @HiveField(3)
  String? notes; // Optional notes field

  @HiveField(4)
  String? photoPath; // Optional photo path field

  @HiveField(5)
  String date;

  @HiveField(6)
  String syncStatus; // e.g., 'pending', 'synced'

  Observation({
    required this.plotId,
    required this.trait,
    required this.value,
    this.notes, // Handle optional notes
    this.photoPath, // Handle optional photoPath
    required this.date,
    required this.syncStatus,
  });

  // Converts the Observation model into a backend-compatible JSON format
  Map<String, dynamic> toRequestJson() {
    return {
      "services": [
        {
          "so:name": "Edit Field Trial Rack",
          "start_service": true,
          "parameter_set": {
            "level": "simple",
            "parameters": [
              {"param": "RO Id", "current_value": plotId, "group": "Plot"},
              {"param": "RO Append Observations", "current_value": true, "group": "Plot"},
              {
                "param": "RO Measured Variable Name",
                "current_value": [trait],
                "group": "Phenotypes"
              },
              {
                "param": "RO Phenotype Raw Value",
                "current_value": [value],
                "group": "Phenotypes"
              },
              {
                "param": "RO Phenotype Corrected Value",
                "current_value": [null],
                "group": "Phenotypes"
              },
              {
                "param": "RO Phenotype Start Date",
                "current_value": [date],
                "group": "Phenotypes"
              },
              {
                "param": "RO Phenotype End Date",
                "current_value": [null],
                "group": "Phenotypes"
              },
              {
                "param": "RO Observation Notes",
                "current_value": notes != null ? [notes] : [null],
                "group": "Phenotypes"
              },
            ]
          }
        }
      ]
    };
  }

  // Converts the Observation model to a JSON-compatible map for local storage
  Map<String, dynamic> toJson() {
    return {
      'plotId': plotId,
      'trait': trait,
      'value': value,
      'notes': notes,
      'photoPath': photoPath,
      'date': date,
      'syncStatus': syncStatus,
    };
  }

  // Creates an Observation instance from a JSON map
  static Observation fromJson(Map<String, dynamic> json) {
    return Observation(
      plotId: json['plotId'],
      trait: json['trait'],
      value: json['value'],
      notes: json['notes'],
      photoPath: json['photoPath'],
      date: json['date'],
      syncStatus: json['syncStatus'],
    );
  }
}
