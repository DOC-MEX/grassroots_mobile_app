import 'dart:convert';
import 'package:http/http.dart' as http;

class GrassrootsRequest {
  static Future<Map<String, dynamic>> sendRequest(String requestString) async {
    final response = await http.post(
      Uri.parse('https://grassroots.tools/public_backend'),
      //Uri.parse('https://grassroots.tools/dev/grassroots/public_backend'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: requestString,
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);

      if ((data['results'] as List).isEmpty) {
        //return "EmptyResults";
        throw Exception("EmptyResults");
      }

      // Check if status_text is either 'Succeeded' or 'Partially succeeded'
      //String statusText = data['results'][0]['status_text'];
      //if (statusText == "Succeeded" || statusText == "Partially succeeded") {
      // Extract the study_index value
      //  int? studyIndex = data['results'][0]['results'][0]['data']['study_index'];
      // String? accession = data['results'][0]['results'][0]['data']['material']['accession'];
      // Count the number of observations
      //  int? observationsCount = (data['results'][0]['results'][0]['data']['observations'] as List).length;
      //  List<String> phenotypeNames = [];
      //  List observations = data['results'][0]['results'][0]['data']['observations'];

      //  for (var observation in observations) {
      //    String? variable = observation['phenotype']['variable'];
      //    if (variable != null && !phenotypeNames.contains(variable)) {
      //      phenotypeNames.add(variable);
      //    }
      //  }

      //  if (studyIndex != null && accession != null && observationsCount != null) {
      //    return 'Study Index: $studyIndex. \n Accession: $accession \n Number of Observations: $observationsCount \n Phenotype Names: $phenotypeNames';
      //  } else {
      //    return 'Study index not found in response';
      //  }
      //}
      //return statusText;
      return data;
    } else {
      // If the server did not return a 200 OK response,
      //throw Exception('Failed to load data from the server');
      //return 'Failed to load data from the server';
      throw Exception('Failed to load data from the server with status: ${response.statusCode}');
    }
  }

  static String getRequestString(String qrCode) {
    //return '{"services": [{"so:name": "Search Field Trials","start_service": true,"parameter_set": {"level": "advanced","parameters": [{"param": "ST Id","current_value": "$qrCode"}, {"param": "Get all Plots for Study","current_value": true}, {"param": "ST Search Studies","current_value": true}]}}]}';
    return '{"services": [{"so:name": "Search Field Trials","start_service": true,"parameter_set": {"level": "advanced","parameters": [{"param": "Plot ID","current_value": "$qrCode","group": "Plots and Racks"}]}}]}';
  }
}
