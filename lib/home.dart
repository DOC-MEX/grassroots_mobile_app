import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'welcome_message.dart';
import 'genera_details.dart';
import 'qr_code_service.dart';
import 'observation_page.dart';
import 'package:flutter/services.dart';

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
  List<String> traits = [];
  List<String> allPhenotypeNames = []; // New list for all possible phenotypes
  List<String> allTraits = [];

  List<String> units = [];
  String? currentValue;
  String? selectedValue;
  List<dynamic> observations = [];
  dynamic selectedRawValue;

  String? studyName;
  String? studyID;

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
          if (detectedQRString == null) WelcomeMessageWidget(),

          Positioned(
            bottom: 15, // Adjust this value to position the button at your preferred location.
            left: 10,
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

          // Add Observation Button (centered)
          if (detectedQRString != null)
            Positioned(
              bottom: 15,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ObservationPage(
                          studyName: studyName ?? 'No Study Name',
                          studyID: studyID ?? 'No Study ID',
                          serverResponse: serverResponse ?? 'No Response',
                          detectedQRCode: detectedQRString ?? 'No QR Code Detected',
                          phenotypeNames: phenotypeNames,
                          traits: traits,
                          allPhenotypeNames: allPhenotypeNames,
                          allTraits: allTraits,
                        ),
                      ),
                    );
                  },
                  child: Text('Add Observation'),
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
                //  Column(
                mainAxisSize: MainAxisSize.min, // To avoid taking up the whole screen height
                children: [
                  GeneralDetails(
                    studyName: studyName,
                    serverResponse: serverResponse,
                    selectedRawValue: selectedRawValue,
                  ),

                  SizedBox(height: 20), // spacing of 20 pixels for visual separation

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
                  ), // Container
                ], // CHILDREN
              ), // COLUMN
            ), // CENTER

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
                    studyID = null;
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
                    studyID = parsedData.studyID;
                    phenotypeNames.clear();
                    phenotypeNames = parsedData.parsedPhenotypeNames;
                    traits.clear();
                    traits = parsedData.traits;
                    units = parsedData.units;
                    observations.clear();
                    observations = parsedData.observations;
                    allPhenotypeNames = parsedData.allPhenotypeNames;
                    allTraits = parsedData.allTraits;
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 10.0, bottom: 5.0), // Add some right and bottom padding
        child: ElevatedButton(
          onPressed: () {
            if (isCameraOpen) {
              setState(() {
                isCameraOpen = false;
              });
            } else {
              setState(() {
                isCameraOpen = true;
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0), // Slightly rounded corners
            ),
            padding:
                EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Padding around the icon for better appearance
          ),
          child: Icon(isCameraOpen ? Icons.close : Icons.camera),
        ),
      ),
    );
  }
}
