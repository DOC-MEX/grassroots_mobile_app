import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'grassroots_request.dart';
import 'package:flutter/services.dart';
//import 'dart:convert';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isCameraOpen = false; // State to check if camera is open or not
  String? detectedQRString; // Variable to store detected QR code string
  String? serverResponse;
  bool isLoading = false;
  String? selectedPhenotype;
  List<String> phenotypeNames = [];
  String? currentValue;

  List<String> parsedPhenotypeNames = [];
  List<String> traits = [];
  List<String> units = [];
  String? selectedValue;
  List<dynamic> observations = [];
  dynamic selectedRawValue;

  String? studyName;

  List<Map<String, dynamic>> findRawValuesForSelectedPhenotype(String selectedPhenotype) {
    List<Map<String, dynamic>> matchingObservations = [];
    for (var observation in observations) {
      if (observation['phenotype']['variable'] == selectedPhenotype) {
        matchingObservations.add({
          'raw_value': observation['raw_value'],
          'date': observation['date'] ?? '',
        });
      }
    }
    return matchingObservations;
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width * 0.8;
    return Scaffold(
      appBar: AppBar(title: Text('QR Reader')),
      body: Stack(
        children: [
          // Welcome Text
          if (detectedQRString == null)
            Positioned(
              top: 50.0, // Adjust as needed
              left: 0,
              right: 0,
              child: Text(
                "Welcome, open the camera to start capturing QR codes",
                style: TextStyle(fontSize: 16, color: Colors.black),
                textAlign: TextAlign.center,
              ),
            ),

          Positioned(
            bottom: 10, // Adjust this value to position the button at your preferred location.
            left: 5,
            // right: 80,
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  SystemNavigator.pop();
                },
                child: Text('Exit'),
              ),
            ),
          ),

          // Loading Indicator
          if (isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),

          // Detected QR String and Dropdown
          if (detectedQRString != null && !isLoading)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min, // To avoid taking up the whole screen height
                children: [
                  if (studyName != null) // Only display if there's a study name
                    Text(
                      '$studyName',
                      style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  SizedBox(height: 10), // A spacing of 10 pixels
                  Text(
                    '$serverResponse',
                    style: TextStyle(fontSize: 12, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20), // A spacing of 20 pixels for visual separation
                  if (selectedRawValue != null) // Only display if there's a value selected
                    Text(
                      'Selected Raw Value: $selectedRawValue',
                      style: TextStyle(fontSize: 14, color: Colors.black),
                      textAlign: TextAlign.center,
                    ),

                  SizedBox(height: 20), // A spacing of 20 pixels for visual separation
                  // Determine the width here:
                  Container(
                    width: width, // You can adjust this value based on your needs
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedPhenotype, // Phenotype is the actual value now
                      hint: Text('Select phenotype'),
                      onChanged: (String? newPhenotype) {
                        setState(() {
                          selectedPhenotype = newPhenotype;
                          selectedRawValue = null; // Clear the previous raw value
                        });

                        List<Map<String, dynamic>> rawValues = findRawValuesForSelectedPhenotype(newPhenotype!);

                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            int selectedIndex = parsedPhenotypeNames.indexOf(selectedPhenotype!);
                            String displayTrait = (selectedIndex != -1) ? traits[selectedIndex] : "Unknown Trait";
                            String displayUnit = (selectedIndex != -1) ? units[selectedIndex] : "No Unit";
                            return AlertDialog(
                              title: Text(displayTrait),
                              content: (rawValues.isEmpty)
                                  ? Text('No Data Found')
                                  : SingleChildScrollView(
                                      child: Table(
                                        border: TableBorder.symmetric(
                                          inside: BorderSide(width: 1, color: Colors.black38),
                                          outside: BorderSide(width: 1, color: Colors.black38),
                                        ),
                                        columnWidths: {
                                          0: FlexColumnWidth(1),
                                          1: FlexColumnWidth(1),
                                          2: FlexColumnWidth(1),
                                        },
                                        children: [
                                          TableRow(
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                            ),
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Text('Value'),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Text('Date'),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Text('Units'),
                                              ),
                                            ],
                                          ),
                                          for (var observation in rawValues)
                                            TableRow(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.all(8.0),
                                                  child: Text('${observation['raw_value']}'),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.all(8.0),
                                                  child: Text('${observation['date']}'),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.all(8.0),
                                                  child: Text(displayUnit),
                                                ),
                                              ],
                                            )
                                        ],
                                      ),
                                    ),
                            );
                          },
                        );

                        int index = parsedPhenotypeNames.indexOf(newPhenotype!); // Getting index using phenotype
                        print('Selected display value: ${traits[index]}');
                        print('Actual value (phenotype): $newPhenotype');
                      },
                      items: List<DropdownMenuItem<String>>.generate(
                        parsedPhenotypeNames.length,
                        (index) => DropdownMenuItem<String>(
                          value: parsedPhenotypeNames[index], // Actual value
                          child: Container(
                            width: width - 20, //230.0, // Just a bit less than the outer container width
                            child: Text(
                              traits[index].toString(), // Display value
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Conditionally show camera when its state is open
          if (isCameraOpen)
            MobileScanner(
              controller: MobileScannerController(),
              onDetect: (capture) async {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                  setState(() {
                    detectedQRString = barcodes.first.rawValue!;
                    isCameraOpen = false; // Close the camera after detection
                    isLoading = true; // Show loading
                    selectedRawValue = null; // Clear the previous raw value
                    studyName = null; // Clear the previous study name
                  });
                  try {
                    final Map<String, dynamic> responseData =
                        await GrassrootsRequest.sendRequest(GrassrootsRequest.getRequestString(detectedQRString!));

                    String statusText = responseData['results'][0]['status_text'];
                    if (statusText == "Succeeded" || statusText == "Partially succeeded") {
                      int? studyIndex = responseData['results'][0]['results'][0]['data']['study_index'];
                      String? accession = responseData['results'][0]['results'][0]['data']['material']['accession'];
                      int? observationsCount =
                          (responseData['results'][0]['results'][0]['data']['observations'] as List).length;

                      String? studyName = responseData['results'][0]['results'][0]['data']['study']['so:name'];
                      print('Study Name: $studyName');
                      parsedPhenotypeNames.clear(); // Clear the list first

                      observations = responseData['results'][0]['results'][0]['data']['observations'];
                      for (var observation in observations) {
                        String? variable = observation['phenotype']['variable'];
                        if (variable != null && !parsedPhenotypeNames.contains(variable)) {
                          parsedPhenotypeNames.add(variable);
                        }
                      }

                      var phenotypesInfo = responseData['results'][0]['results'][0]['data']['phenotypes'];
                      traits.clear(); // Clear the traits list as well

                      for (var phenotypeName in parsedPhenotypeNames) {
                        var phenotypeData = phenotypesInfo[phenotypeName];
                        if (phenotypeData != null) {
                          String? traitName = phenotypeData['definition']['trait']['so:name'];
                          String? unitName = phenotypeData['definition']['unit']['so:name'];
                          if (traitName != null) {
                            traits.add(traitName);
                          }
                          units.add(unitName ?? 'No Unit');
                        }
                      }

                      print('** Traits List: $traits');
                      print('ParsedPhenotypeNames List: $parsedPhenotypeNames');

                      setState(() {
                        selectedPhenotype = null; // Resetting the selected value
                        serverResponse =
                            'Study Index: $studyIndex. \n Accession: $accession \n Number of Observations: $observationsCount';
                        phenotypeNames = parsedPhenotypeNames;
                        if (phenotypeNames.isNotEmpty) {
                          currentValue = phenotypeNames[0]; // Reset to the first value
                        } else {
                          currentValue = null;
                        }
                        this.studyName = studyName; // Updating the studyName state here
                      });
                      isLoading = false; // Hide loading indicator
                    }
                  } catch (e) {
                    // Handle any errors here
                    print(e.toString());
                    setState(() {
                      serverResponse = e.toString();
                      isLoading = false; // Set loading to false in case of error
                    });
                  }
                }
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (isCameraOpen) {
            // If camera is open, close it
            setState(() {
              isCameraOpen = false;
            });
          } else {
            // Otherwise, open the camera
            setState(() {
              isCameraOpen = true;
            });
          }
        },
        child: Icon(isCameraOpen ? Icons.close : Icons.camera),
      ),
    );
  }
}
