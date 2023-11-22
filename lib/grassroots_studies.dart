import 'package:flutter/material.dart';
import 'dart:convert';
import 'grassroots_request.dart';

class GrassrootsStudies extends StatefulWidget {
  @override
  _GrassrootsPageState createState() => _GrassrootsPageState();
}

class _GrassrootsPageState extends State<GrassrootsStudies> {
  bool isLoading = true;
  List<Map<String, String>> studies = []; // Store both name and ID
  String? selectedStudy;

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
              child: DropdownButtonFormField<String>(
                isExpanded: true, // Add this line
                value: selectedStudy,
                hint: Text("Select a study"),
                onChanged: (newValue) {
                  setState(() {
                    selectedStudy = newValue;
                  });
                  print('Selected Study ID: $newValue');
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
            ),
    );
  }
}
