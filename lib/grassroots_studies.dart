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
          return {'name': name, 'id': id};
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
                              setState(() {
                                studyTitle = studyDetails['results'][0]['results'][0]['title'];
                                studyDescription = studyDetails['results'][0]['results'][0]['data']['so:description'];
                              });
                              print('Selected Study ID: $newValue');
                              print('Study Title: $studyTitle');
                              print('Study Description: $studyDescription');
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
                          Text(
                            'Description: ${studyDescription ?? 'Not available'}',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ],
                    ),
            ),
    );
  }
}
