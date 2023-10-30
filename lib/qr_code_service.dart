import 'package:mobile_scanner/mobile_scanner.dart';
import 'grassroots_request.dart';

class ParsedData {
  String? statusText;
  int? studyIndex;
  String? accession;
  int? observationsCount;
  String? studyName;
  List<String> parsedPhenotypeNames = [];
  List<dynamic> observations = [];
  List<String> traits = [];
  List<String> units = [];
  // Add any other necessary fields
}

class QRCodeService {
  // This will process the capture and return the detected QR code's raw value or null
  String? processDetectedQR(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      return barcodes.first.rawValue!;
    }
    return null;
  }

  // Fetch data based on the detected QR code
  Future<Map<String, dynamic>> fetchDataFromQR(String qrRawValue) async {
    try {
      final Map<String, dynamic> responseData =
          await GrassrootsRequest.sendRequest(GrassrootsRequest.getRequestString(qrRawValue));

      // Additional logic ...

      return responseData; // Return the processed or raw response data
    } catch (e) {
      print(e.toString());
      // Handle errors and return an appropriate response or throw an error
      return {"error": e.toString()};
    }
  }

  ParsedData parseResponseData(Map<String, dynamic> responseData) {
    ParsedData parsedData = ParsedData();

    parsedData.statusText = responseData['results'][0]['status_text'];

    if (parsedData.statusText == "Succeeded" || parsedData.statusText == "Partially succeeded") {
      parsedData.studyIndex = responseData['results'][0]['results'][0]['data']['study_index'];
      parsedData.accession = responseData['results'][0]['results'][0]['data']['material']['accession'];

      if (responseData['results'][0]['results'][0]['data'].containsKey('observations')) {
        parsedData.observationsCount =
            (responseData['results'][0]['results'][0]['data']['observations'] as List).length;

        parsedData.studyName = responseData['results'][0]['results'][0]['data']['study']['so:name'];

        var observations = responseData['results'][0]['results'][0]['data']['observations'];
        parsedData.observations = observations; // Store observations to parsedData
        for (var observation in observations) {
          String? variable = observation['phenotype']['variable'];
          if (variable != null && !parsedData.parsedPhenotypeNames.contains(variable)) {
            parsedData.parsedPhenotypeNames.add(variable);
          }
        }

        var phenotypesInfo = responseData['results'][0]['results'][0]['data']['phenotypes'];
        for (var phenotypeName in parsedData.parsedPhenotypeNames) {
          var phenotypeData = phenotypesInfo[phenotypeName];
          if (phenotypeData != null) {
            String? traitName = phenotypeData['definition']['trait']['so:name'];
            String? unitName = phenotypeData['definition']['unit']['so:name'];
            if (traitName != null) {
              parsedData.traits.add(traitName);
            }
            parsedData.units.add(unitName ?? 'No Unit');
          }
        }
      }
    }

    return parsedData;
  }
}
