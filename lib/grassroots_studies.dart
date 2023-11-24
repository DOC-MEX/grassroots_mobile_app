import 'package:flutter/material.dart';
import 'qr_code_service.dart';

class GrassrootsStudies extends StatefulWidget {
  @override
  _GrassrootsPageState createState() => _GrassrootsPageState();
}

class _GrassrootsPageState extends State<GrassrootsStudies> {
  bool isLoading = true;
  bool isSingleStudyLoading = false;
  List<Map<String, String>> studies = []; // Store both name and ID
  String? selectedStudy;
  String? studyTitle;
  String? studyDescription;
  String? programme;
  String? address;
  String? FTrial;
  int numberOfPlots = 0;
  String? selectedPlotId;
  List<String> plotIDs = [];
  List<String> plotDisplayValues = [];
  String? selectedPlotDisplayValue;
  Map<String, dynamic>? fetchedStudyDetails;

  @override
  void initState() {
    super.initState();
    fetchStudies(); // Updated to call the new method to fetch all studies
  }

  void fetchStudies() async {
    setState(() {
      isLoading = true;
    });

    try {
      var studiesData = await QRCodeService.fetchAllStudies();
      setState(() {
        studies = studiesData;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching studies: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grassroots Studies'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: isSingleStudyLoading
                  ? Center(child: CircularProgressIndicator()) // Show loading indicator while fetching single study
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          isExpanded: true, // Ensure the dropdown is expanded
                          value: selectedStudy,
                          hint: Text("Select a study"),
                          onChanged: (newValue) async {
                            setState(() {
                              selectedStudy = newValue;
                              isSingleStudyLoading = true; // Start loading
                              // Reset plot lists
                              plotIDs.clear();
                              plotDisplayValues.clear();
                              selectedPlotId = null; // Also reset the selected plot ID
                              selectedPlotDisplayValue = null;
                            });

                            try {
                              var studyDetails = await QRCodeService.fetchSingleStudy(newValue!);

                              //setState(() {
                              //  fetchedStudyDetails = studyDetails; // Store the fetched details
                              //});

                              // Check if 'plots' exists and is not null
                              if (studyDetails['results'][0]['results'][0]['data'].containsKey('plots') &&
                                  studyDetails['results'][0]['results'][0]['data']['plots'] != null) {
                                var plots = studyDetails['results'][0]['results'][0]['data']['plots'] as List<dynamic>;
                                //List<String> tempPlotIDs = [];
                                //List<String> tempPlotDisplayValues = []; // Will hold plot indices for display
                                int nPlots = 0;

                                for (var plot in plots) {
                                  if (plot.containsKey('rows') && plot['rows'] is List && plot['rows'].isNotEmpty) {
                                    var row = plot['rows'][0];
                                    if (!(row.containsKey('discard') || row.containsKey('blank'))) {
                                      String plotID = row['_id']['\$oid'];
                                      String plotIndex = row['study_index']
                                          .toString(); // Assuming study_index is the value you want to display
                                      //tempPlotIDs.add(plotID);
                                      //tempPlotDisplayValues.add(plotIndex);
                                      plotIDs.add(plotID);
                                      plotDisplayValues.add(plotIndex);
                                      nPlots++;
                                    }
                                  }
                                }
                                // Update the state with the number of plots and their IDs
                                setState(() {
                                  numberOfPlots = nPlots;
                                  fetchedStudyDetails = studyDetails; // Store the fetched details
                                  //plotIDs = tempPlotIDs; // Update class-level variable
                                  //plotDisplayValues = tempPlotDisplayValues; // Update class-level variable
                                });

                                print('Number of Plots: $nPlots');
                                print('Plot IDs: $plotIDs');
                                print('Plot Display Values: $plotDisplayValues');
                              }

                              // Updating the state with other study details
                              setState(() {
                                studyTitle = studyDetails['results'][0]['results'][0]['title'];
                                studyDescription = studyDetails['results'][0]['results'][0]['data']['so:description'];
                                programme =
                                    studyDetails['results'][0]['results'][0]['data']['parent_program']['so:name'];
                                address = studyDetails['results'][0]['results'][0]['data']['address']['name'];
                                FTrial =
                                    studyDetails['results'][0]['results'][0]['data']['parent_field_trial']['so:name'];
                              });

                              print('Selected Study ID: $newValue');
                              print('Study Title: $studyTitle');
                              print('Study Description: $studyDescription');
                              print('Study Programme: $programme');
                            } catch (e) {
                              print('Error fetching study details: $e');
                            } finally {
                              setState(() {
                                isSingleStudyLoading = false; // Ensure loading is stopped in all cases
                              });
                            }
                          },

                          items: studies.map<DropdownMenuItem<String>>((study) {
                            return DropdownMenuItem<String>(
                              value: study['id'], // Use study ID as value
                              child: Text(
                                study['name'] ?? 'Unknown Study',
                                overflow: TextOverflow.ellipsis, // Use ellipsis for text overflow
                                softWrap: false,
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 20),
                        // Display study details
                        if (studyTitle != null) ...[
                          Text(
                            '$studyTitle',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          if (studyDescription != null && studyDescription!.isNotEmpty) ...[
                            Text(
                              'Description: $studyDescription',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 10),
                          ],
                          if (programme != null && programme!.isNotEmpty) ...[
                            Text(
                              'Programme: $programme',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                          SizedBox(height: 10),
                          if (FTrial != null && FTrial!.isNotEmpty) ...[
                            Text(
                              'Field Trial: $FTrial',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                          SizedBox(height: 10),
                          if (address != null && address!.isNotEmpty) ...[
                            Text(
                              'Address: $address',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                          SizedBox(height: 10),
                          if (numberOfPlots > 0) ...[
                            Text(
                              'Number of Plots: $numberOfPlots',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                          SizedBox(height: 20),
                          if (plotDisplayValues.isNotEmpty) ...[
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: selectedPlotId,
                              hint: Text("Select a plot"),
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedPlotId = newValue;
                                  int index = plotIDs.indexOf(newValue!);
                                  if (index != -1) {
                                    selectedPlotDisplayValue = plotDisplayValues[index];
                                    ///////////// Additional logic when a plot is selected /////
                                    /// Example: Count the number of observations in the selected plot
                                    var plots = fetchedStudyDetails!['results'][0]['results'][0]['data']['plots']
                                        as List<dynamic>;

                                    // Find the plot that matches the selectedPlotId
                                    var selectedPlot = plots.firstWhere(
                                      (plot) =>
                                          plot['rows'] != null && plot['rows'][0]['_id']['\$oid'] == selectedPlotId,
                                      orElse: () => null,
                                    );

                                    if (selectedPlot != null) {
                                      // Count the number of observations
                                      var observationCount = selectedPlot['rows'][0]['observations'] != null
                                          ? selectedPlot['rows'][0]['observations'].length
                                          : 0;

                                      print('Number of Observations in the selected plot: $observationCount');
                                    }
                                  }
                                });
                                // Additional logic when a plot is selected, if needed
                                print('Selected Plot ID: $newValue'); // Print the actual plot ID to console
                              },
                              items: List<DropdownMenuItem<String>>.generate(
                                plotDisplayValues.length,
                                (index) => DropdownMenuItem<String>(
                                  value: plotIDs[index],
                                  child: Text(plotDisplayValues[index]),
                                ),
                              ),
                            ),
                            SizedBox(height: 20), // Optional spacing
                            if (selectedPlotDisplayValue != null) ...[
                              SizedBox(height: 10),
                              Text(
                                'Selected plot: $selectedPlotDisplayValue',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ],
                        ],
                      ],
                    ),
            ),
    );
  }
}
