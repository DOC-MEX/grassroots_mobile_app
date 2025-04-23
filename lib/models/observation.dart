import 'package:grassroots_field_trials/backend_request.dart';
import 'package:grassroots_field_trials/global_variable.dart';
import 'package:grassroots_field_trials/grassroots_request.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

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

  @HiveField(6)
  String studyId;

  @HiveField(7)
  String? accession;

  Observation({
    required this.plotId,
    required this.trait,
    required this.value,
    this.notes,
    required this.date,
    required this.syncStatus,
    required this.studyId,
    this.accession,
  });

  Map<String, dynamic> toJson() {
    return {
      'plotId': plotId,
      'trait': trait,
      'value': value,
      'notes': notes,
      'date': date,
      'syncStatus': syncStatus,
      'studyId': studyId,
      'accession': accession,
    };
  }


  Future <bool> Submit () async {
    bool success_flag = false;

        try {
      // Create the JSON request
      String jsonString = backendRequests.submitObservationRequest(
        studyId: studyId,
        detectedQRCode: plotId,
        selectedTrait: trait,
        measurement: value,
        dateString: date,
        accession: accession,
        note: notes,
      );
      
      if (GrassrootsConfig.debug_flag) {
        print('Request to server: $jsonString');
      }

      if (jsonString != '{}') {
        var response = await GrassrootsRequest.sendRequest(jsonString, 'private');
        
        if (GrassrootsConfig.debug_flag) {
          print('Response from server: $response');
        }

        String? statusText = response['results']?[0]['status_text'];
        bool submissionSuccessful = (statusText != null) && (statusText == 'Succeeded');

      }
        }

    return success_flag;
  }
}
