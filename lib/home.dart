import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'grassroots_request.dart';
import 'qr_code_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final QRCodeService qrCodeService = QRCodeService();
  bool isCameraOpen = false; // State to check if camera is open or not
  String? detectedQRString; // Variable to store detected QR code string
  String? serverResponse;
  bool isLoading = false;
  String? selectedPhenotype;
  List<String> phenotypeNames = [];
  String? currentValue;

  //List<String> parsedPhenotypeNames = [];
  List<String> traits = [];
  List<String> units = [];
  String? selectedValue;
  List<dynamic> observations = [];
  dynamic selectedRawValue;

  String? studyName;
  final Uri _websiteUrl = Uri.parse('https://grassroots.tools/');

  void showTopSnackBar(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100.0, // Adjust this to position it lower on the screen
        left: MediaQuery.of(context).size.width * 0.1,
        right: MediaQuery.of(context).size.width * 0.1, // This helps constrain the width
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            color: Colors.blue,
            child: Text(
              message,
              style: TextStyle(color: Colors.white),
              maxLines: 2, // Allows text to wrap to the next line
              overflow: TextOverflow.ellipsis, // If there's still overflow, it'll end with "..."
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(Duration(seconds: 5), () {
      overlayEntry.remove();
    });
  }

  List<Map<String, dynamic>> findRawValuesForSelectedPhenotype(String selectedPhenotype) {
    List<Map<String, dynamic>> matchingObservations = [];

    for (var observation in observations) {
      if (observation['phenotype']['variable'] == selectedPhenotype) {
        //print('Matched observation for phenotype: $selectedPhenotype');
        String formattedDate = '';
        if (observation['date'] != null) {
          try {
            DateTime date = DateTime.parse(observation['date']);
            formattedDate =
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          } catch (e) {
            print('Error parsing date: $e');
          }
        }
        matchingObservations.add({
          'raw_value': observation['raw_value'],
          'date': formattedDate,
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
          if (detectedQRString == null)
            Positioned(
              top: 50.0, // Adjust as needed
              left: 3,
              right: 3,
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(fontSize: 16, color: Colors.black),
                  children: [
                    TextSpan(
                      text: "Welcome to the QR reader for Grasstools.\n\n",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: "Open the camera to start capturing QR codes.\n\n",
                      style: TextStyle(fontSize: 18),
                    ),
                    TextSpan(
                      text: "Visit ",
                      style: TextStyle(fontSize: 18),
                    ),
                    TextSpan(
                      text: "grassroots.tools",
                      style: TextStyle(
                        fontSize: 18,
                        decoration: TextDecoration.underline,
                        color: Colors.blue,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          if (!await launchUrl(_websiteUrl)) {
                            print('Could not launch $_websiteUrl');
                          }
                        },
                    ),
                    TextSpan(
                      text: " for more information.",
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
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
                        //if (parsedPhenotypeNames.contains(newPhenotype)) {
                        //NEW if!
                        setState(() {
                          selectedPhenotype = newPhenotype;
                          selectedRawValue = null; // Clear the previous raw value
                        });
                        //}

                        List<Map<String, dynamic>> rawValues = findRawValuesForSelectedPhenotype(newPhenotype!);

                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            int selectedIndex = phenotypeNames.indexOf(selectedPhenotype!);
                            String displayTrait = (selectedIndex != -1) ? traits[selectedIndex] : "Unknown Trait";
                            String displayUnit = (selectedIndex != -1) ? units[selectedIndex] : "No Unit";

                            double width = MediaQuery.of(context).size.width * 0.9; // Calculate 90% of screen width

                            return Dialog(
                              child: Container(
                                width: width,
                                padding: EdgeInsets.all(20.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(displayTrait, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                    SizedBox(height: 20),
                                    if (rawValues.isEmpty)
                                      Text('No Data Found')
                                    else
                                      SingleChildScrollView(
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
                                  ],
                                ),
                              ),
                            );
                          },
                        ); //SHOW DIALOG

                        int index = phenotypeNames.indexOf(newPhenotype); // Getting index using phenotype

                        print('Selected display value: ${traits[index]}');
                        print('Actual value (phenotype): $newPhenotype');
                      },
                      items: List<DropdownMenuItem<String>>.generate(
                        phenotypeNames.length,
                        (index) => DropdownMenuItem<String>(
                          value: phenotypeNames[index], // Actual value
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
                final detectedValue = qrCodeService.processDetectedQR(capture);
                if (detectedValue != null) {
                  setState(() {
                    detectedQRString = detectedValue;
                    isCameraOpen = false;
                    isLoading = true;
                    selectedRawValue = null;
                    studyName = null;
                    selectedPhenotype = null;
                  });

                  final Map<String, dynamic> responseData = await qrCodeService.fetchDataFromQR(detectedQRString!);

                  if (responseData.containsKey("error")) {
                    setState(() {
                      serverResponse = responseData["error"];
                      isLoading = false;
                    });
                    return;
                  }

                  final ParsedData parsedData = qrCodeService.parseResponseData(responseData);

                  // Now use the parsedData object to update your UI
                  setState(() {
                    serverResponse =
                        'Study Index: ${parsedData.studyIndex}. \n Accession: ${parsedData.accession} \n Number of Observations: ${parsedData.observationsCount}';
                    studyName = parsedData.studyName;
                    phenotypeNames.clear();
                    phenotypeNames = parsedData.parsedPhenotypeNames;
                    traits.clear();
                    traits = parsedData.traits;
                    units = parsedData.units;
                    observations.clear();
                    observations = parsedData.observations;
                    if (phenotypeNames.isNotEmpty) {
                      currentValue = phenotypeNames[0];
                    } else {
                      currentValue = null;
                    }
                  });

                  print('** Traits List: $traits');
                  print('phenotypeNames List: $phenotypeNames');

                  // If there are no observations, show the snackbar and don't show the dropdown:
                  if ((parsedData.observationsCount ?? 0) == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        duration: Duration(seconds: 5),
                        content: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.yellow),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Plot has no observations. Open the camera again to capture a new QR code",
                                style: TextStyle(fontSize: 20.0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                    setState(() {
                      isLoading = true; // Show loading spinner
                      phenotypeNames = []; // Clear the names so dropdown is not displayed
                      currentValue = null; // Clear current value
                    });
                  } else {
                    setState(() {
                      isLoading = false; // Hide loading spinner
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
