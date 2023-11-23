import 'package:flutter/material.dart';
import 'dart:convert';
import 'grassroots_request.dart';

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
  List<String> plotIDList = [];

  @override
  void initState() {
    super.initState();
    fetchAllStudies();
  }

  void fetchAllStudies() async {
    String requestString = jsonEncode({
      "services": [
        {
          "so:name": "Search Field Trials",
          "start_service": true,
          "parameter_set": {
            "level": "simple",
            "parameters": [
              {"param": "FT Keyword Search", "current_value": ""},
              {"param": "FT Study Facet", "current_value": true},
              {"param": "FT Results Page Number", "current_value": 0},
              {"param": "FT Results Page Size", "current_value": 500}
            ]
          }
        }
      ]
    });

    try {
      var response = await GrassrootsRequest.sendRequest(requestString, 'public');
      setState(() {
        studies = response['results'][0]['results'].map<Map<String, String>>((study) {
          // Ensure that both 'name' and 'id' are non-null and are Strings
          String name = study['title'] as String? ?? 'Unknown Study';
          String id = study['data']['_id']['\$oid'] as String? ?? 'Unknown ID';
          String parent_programme = study['data']['parent_program']['so:name'] as String? ?? 'Unknown Programme';
          String address_name = study['data']['address']['name'] as String? ?? 'Unknown Address';
          String field_trial = study['data']['parent_field_trial']['so:name'] as String? ?? 'Unknown Field Trial';
          return {
            'name': name,
            'id': id,
            'parent_programme': parent_programme,
            'address_name': address_name,
            'field_trial': field_trial
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching studies: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> fetchSingleStudy(String studyId) async {
    String requestString = jsonEncode({
      "services": [
        {
          "so:name": "Search Field Trials",
          "start_service": true,
          "parameter_set": {
            "level": "advanced",
            "parameters": [
              {"param": "ST Id", "current_value": studyId},
              {"param": "Get all Plots for Study", "current_value": true},
              {"param": "ST Search Studies", "current_value": true}
            ]
          }
        }
      ]
    });

    var response = await GrassrootsRequest.sendRequest(requestString, 'public');
    return response;
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
                            });

                            try {
                              var studyDetails = await fetchSingleStudy(newValue!);

                              // Check if 'plots' exists and is not null
                              if (studyDetails['results'][0]['results'][0]['data'].containsKey('plots') &&
                                  studyDetails['results'][0]['results'][0]['data']['plots'] != null) {
                                var plots = studyDetails['results'][0]['results'][0]['data']['plots'] as List<dynamic>;
                                List<String> plotIDs = [];
                                int nPlots = 0;

                                for (var plot in plots) {
                                  if (plot['rows'] != null && plot['rows'].isNotEmpty) {
                                    var row = plot['rows'][0];
                                    if (!(row.containsKey('discard') || row.containsKey('blank'))) {
                                      String plotID = row['_id']['\$oid'];
                                      plotIDs.add(plotID);
                                      nPlots++;
                                    }
                                  }
                                }

                                // Update the state with the number of plots and their IDs
                                setState(() {
                                  numberOfPlots = nPlots;
                                  plotIDList = plotIDs;
                                });

                                print('Number of Plots: $nPlots');
                                print('Plot IDs: $plotIDs');
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
                        ],
                      ],
                    ),
            ),
    );
  }
}
