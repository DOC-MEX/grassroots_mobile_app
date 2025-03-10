import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'backend_request.dart';
import 'grassroots_request.dart';
//import 'study_details_widget.dart';
import 'new_observation.dart';
import 'table_observations.dart';
import 'global_variable.dart'; // allowedStudyIDs
import 'api_requests.dart';

class GrassrootsStudies extends StatefulWidget {
  @override
  _GrassrootsPageState createState() => _GrassrootsPageState();
}

class StringLabel {
  String name;
  String id;

  StringLabel (this.name, this.id);
}

typedef StringEntry = DropdownMenuEntry <StringLabel>;


class _GrassrootsPageState extends State<GrassrootsStudies> {
  final TextEditingController studies_controller = TextEditingController();
  bool isLoading = true;
  bool isSingleStudyLoading = false;
  List<Map<String, String>> studies = []; // Store both name and ID
  StringLabel? selectedStudyLabel;
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
  int observationCount = 0;
  Map<String, dynamic>? fetchedStudyDetails;
  Map<String, dynamic>? selectedPlot;
  String? selectedPhenotype;
  Map<String, String> traits = {};
  Map<String, String> units = {};

  Map<String, String> variableToTraitMap = {};

  @override
  void initState() {
    super.initState();
    fetchStudies(); // Updated to call the new method to fetch all studies
     _checkAndUpdateAllowedStudyIDs(); // Add this to check for new study IDs
}

Future<void> _checkAndUpdateAllowedStudyIDs() async {
  print('Initial Allowed Study IDs: $allowedStudyIDs');

  final fetchedIDs = await ApiRequests.fetchAllowedStudyIDs();

  if (fetchedIDs != null) {
    setState(() {
      // Add only new IDs to the allowedStudyIDs list
      for (String id in fetchedIDs) {
        if (!allowedStudyIDs.contains(id)) {
          allowedStudyIDs.add(id);
          print('Added new ID to Allowed Study IDs: $id');
        }
      }
    });
    print('Final Allowed Study IDs: $allowedStudyIDs');
  } else {
    print('Failed to fetch allowed study IDs.');
  }
}


  void fetchStudies() async {
    setState(() {
      isLoading = true;
    });

    try {
      var studiesData = await backendRequests.fetchAllStudies();
      if (mounted) {
        setState(() {
          studies = studiesData;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching studies: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

//////////////////////////////////////////////////////////
// SIMPLE Function to find and process observations
  void processSelectedPhenotype() {
    // Check if both selectedPlot and selectedPhenotype are available
    if (selectedPlot != null && selectedPhenotype != null) {
      List<dynamic> observations = selectedPlot!['rows'][0]['observations'];

      // List to store the raw values
      List<double> rawValues = [];

      // Iterate over observations
      for (var observation in observations) {
        if (observation['phenotype'] != null && observation['phenotype']['variable'] == selectedPhenotype) {
          // If it matches the selected phenotype, extract the raw value
          double rawValue = observation['raw_value']?.toDouble() ?? 0.0;
          rawValues.add(rawValue);
        }
      }

      // For now, let's just print it
      print('Raw values for $selectedPhenotype: $rawValues');
    }
  }

  //////////////////////////////////////////////////////////
  List<Map<String, dynamic>> findRawValuesForSelectedPhenotype() {
    List<Map<String, dynamic>> matchingObservations = [];
    List<dynamic> observations = selectedPlot!['rows'][0]['observations'];

    for (var observation in observations) {
      if (observation['phenotype'] != null && observation['phenotype']['variable'] == selectedPhenotype) {
        //print('Matched observation for phenotype: $selectedPhenotype');
        String formattedDate = '';
        if (observation['date'] != null) {
          try {
            DateTime date = DateTime.parse(observation['date']);
            formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          } catch (e) {
            print('Error parsing date: $e');
          }
        }
        matchingObservations.add({
          'raw_value': observation['raw_value'],
          'date': formattedDate,
          'notes': observation['notes'] ?? '',
        });
      }
    }
    return matchingObservations;
  }

//////////////////////////////////////////////////////////
// Function to show the study details dialog
  void _showStudyDetailsDialog(BuildContext context) {

    print ('study!');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          surfaceTintColor: Colors.transparent,
          backgroundColor:Theme.of(context).colorScheme.surface, // Color(0xffff0000), //
          title: Text(
            studyTitle!,
            style: TextStyle (color: Theme.of(context).colorScheme.primary),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text.rich (
                  TextSpan (
                    children: [
                      TextSpan(
                        text: 'Description: ',
                        style: TextStyle (fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                        ),
                      TextSpan(
                        text: '${studyDescription ?? 'Not available'}',
                        style: TextStyle (color: Theme.of(context).colorScheme.primary)
                      ),
                    ],
                  )
                ),

                Text.rich (
                  TextSpan (
                    children: [
                      TextSpan(
                        text: 'Programme: ',
                        style: TextStyle (fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                        ),
                      TextSpan(
                        text: '${programme ?? 'Not available'}',
                        style: TextStyle (color: Theme.of(context).colorScheme.primary)
                      ),
                    ],
                  )
                ),

                Text.rich (
                  TextSpan (
                    children: [
                      TextSpan(
                        text: 'Address: ',
                        style: TextStyle (fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                        ),
                      TextSpan(
                        text: '${address ?? 'Not available'}',
                        style: TextStyle (color: Theme.of(context).colorScheme.primary)
                      ),
                    ],
                  )
                ),

                Text.rich (
                  TextSpan (
                    children: [
                      TextSpan(
                        text: 'Field Trial: ',
                        style: TextStyle (fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                        ),
                      TextSpan(
                        text: '${FTrial ?? 'Not available'}',
                        style: TextStyle (color: Theme.of(context).colorScheme.primary)
                      ),
                    ],
                  )
                ),

                Text.rich (
                  TextSpan (
                    children: [
                      TextSpan(
                        text: 'Number of Plots: ',
                        style: TextStyle (fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                        ),
                      TextSpan(
                        text: '${numberOfPlots ?? 'Not available'}',
                        style: TextStyle (color: Theme.of(context).colorScheme.primary)
                      ),
                    ],
                  )
                ),

                // Other details...
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: ButtonStyle(
                shape: WidgetStateProperty.all (RoundedRectangleBorder(
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary, 
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(10)
                )
              )),
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );

    print ('end study');
  }

 Future<void> onNewObservationReturn(Map<String, dynamic> resultData) async {
  if (resultData.isNotEmpty) {
    if (resultData.containsKey('submissionSuccessful') && resultData['submissionSuccessful']) {
      print('*****REFRESHING STUDY DETAILS AFTER SUCCESSFUL OBSERVATION');
      try {
        String? study_id = selectedStudyLabel?.id;
        String cacheClearRequestJson = backendRequests.clearCacheRequest(study_id!);
        await GrassrootsRequest.sendRequest(cacheClearRequestJson, 'queen_bee_backend');
        print('Cache cleared successfully');

        var studyDetails = await backendRequests.fetchSingleStudy(study_id!);
        if (mounted) {
          setState(() {
            fetchedStudyDetails = studyDetails;

            if (resultData.containsKey('plotId')) {
              selectedPlotId = resultData['plotId'];

              plotIDs.clear();
              plotDisplayValues.clear();
              observationCount = 0;

              var plots = studyDetails['results'][0]['results'][0]['data']['plots'] as List<dynamic>;
              selectedPlot = plots.firstWhere(
                (plot) => plot['rows'] != null && plot['rows'][0]['_id']['\$oid'] == selectedPlotId,
                orElse: () => null,
              );

              if (studyDetails['results'][0]['results'][0]['data'].containsKey('plots') &&
                  studyDetails['results'][0]['results'][0]['data']['plots'] != null) {
                for (var plot in plots) {
                  if (plot.containsKey('rows') && plot['rows'] is List && plot['rows'].isNotEmpty) {
                    var row = plot['rows'][0];
                    if (!(row.containsKey('discard') || row.containsKey('blank'))) {
                      String plotID = row['_id']['\$oid'];
                      String plotIndex = row['study_index'].toString();
                      plotIDs.add(plotID);
                      plotDisplayValues.add(plotIndex);
                    }
                  }
                }

                // Reorganize plot IDs and display values
                var combinedList = List<MapEntry<String, String>>.generate(
                  plotIDs.length,
                  (index) => MapEntry(plotIDs[index], plotDisplayValues[index]),
                );
                combinedList.sort((a, b) => int.parse(a.value).compareTo(int.parse(b.value)));
                plotIDs = combinedList.map((e) => e.key).toList();
                plotDisplayValues = combinedList.map((e) => e.value).toList();

                // Update selected plot details
                int index = plotIDs.indexOf(selectedPlotId!);
                if (index != -1) {
                  selectedPlotDisplayValue = plotDisplayValues[index];

                  var observations = selectedPlot!['rows'][0]['observations'];
                  var count = observations.length;
                  observationCount = count;

                  // Rebuild the variableToTraitMap
                  variableToTraitMap.clear();
                  for (var observation in observations) {
                    if (observation.containsKey('phenotype') &&
                        observation['phenotype'].containsKey('variable')) {
                      String variable = observation['phenotype']['variable'];
                      print('Variable: $variable, Exists in traits: ${traits.containsKey(variable)}');
                      if (traits.containsKey(variable)) {
                        String traitName = traits[variable]!;
                        variableToTraitMap[variable] = traitName;
                      }
                    }
                  }
                  print('Updated Variable to Trait Map: $variableToTraitMap');
                }
              }
              selectedPhenotype = null; // Reset the selected phenotype after an update
            }
          });

          // Print the new observation count
          print('New observation count: $observationCount');
        }
      } catch (e) {
        print('Error in fetching study details: $e');
        // Optionally handle the error here, e.g., showing a snackbar message
      }
    }
  }
}


List <StringEntry> GetStudiesAsList () {
  List <StringEntry> l = [];
  

  for (final e in studies) {
    var study = e;
    var id = study ['id'];

    if (id != null) {
      StringLabel sl = StringLabel (study['name'] ?? 'Unknown Study', id);

      StringEntry se = StringEntry(
        label: study['name'] ?? 'Unknown Study', 
        value: sl,
        style: ButtonStyle (
          foregroundColor: WidgetStateProperty.all(Theme.of(context).primaryColor),
        ),
      );
      
      l.add (se);            
    }

  }

  
  return l;
}

GetStudyDetails (selected_study_id) async {
  Map<String, dynamic> study_details = {};

  try {
    // Fetch the study details
      study_details = await backendRequests.fetchSingleStudy(selected_study_id!);
  } catch (e) {
    print (">>>>> Couldn't get study $selected_study_id");
  }

  print ("returning\n$study_details");
  return study_details;
}


////////////////////// MAIN BUILD ////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    //print("*******GrassrootsStudies build() called******");
    //print('Selected Study: $selectedStudy');
    //print('Selected Plot ID: $selectedPlotId');
    //print('Selected Phenotype: $selectedPhenotype');
    //print('Number of Plots: $numberOfPlots');



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
                  //wrap the column in a singlechildscrollview
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //________ Dropdown to select a study.  1st DROPDOWN MENU______
                          DropdownMenu (
                            requestFocusOnTap: true,
                            dropdownMenuEntries: GetStudiesAsList (),
                            controller: studies_controller,
                            enableFilter: true,
                            label: const Text ("Search for a study..."),
                            helperText: "Select a Study to view or edit",
                            trailingIcon: Icon (
                              Icons.arrow_drop_down,
                              color: Theme.of(context).primaryColor,
                            ),
                            textStyle: TextStyle (color: Theme.of(context).primaryColor),
                            inputDecorationTheme: InputDecorationTheme (
                              labelStyle: TextStyle (color: Theme.of(context).primaryColor),
                              helperStyle: TextStyle (color: Theme.of(context).primaryColor),
                            ),

                            /*
                            inputDecorationTheme: InputDecorationTheme(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                              constraints: BoxConstraints.tight(const 
                              Size.fromHeight(40)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            */

                            menuHeight: 500,
                            menuStyle: MenuStyle (
                              backgroundColor: WidgetStateProperty.all(Theme.of(context).canvasColor),
                            ),
                            
                            onSelected: (StringLabel? study_label) async {

                              if (study_label != null) {
                                print ("****** selected study: ${study_label.id}, ${study_label.name}");                                
                              }
                              
                              setState(() {
                                selectedStudyLabel = study_label;
                                isSingleStudyLoading = true; // Start loading the study details
                              // Reset plot lists
                                plotIDs.clear();
                                plotDisplayValues.clear();
                                selectedPlotId = null; // Also reset the selected plot ID
                                selectedPlotDisplayValue = null;
                                observationCount = 0;
                              });
                              
                              try {
                                // Fetch the study details

                                if (selectedStudyLabel != null) {

                                  String? id = selectedStudyLabel?.id;
                                  String? name = selectedStudyLabel?.name;

                                  print ("****** selectedStudy: ${id}, ${name}");


                                  //id = null;

                                  if (id != null) {
                                    print ("Getting study details for $id");
                                    var studyDetails= await backendRequests.fetchSingleStudy(id); //GetStudyDetails(selectedStudy!);

                                    //studyDetails = {};
                                    if (studyDetails.isNotEmpty) {
                                      print ("GetStudyDetails () returned:\n$studyDetails");

                                      // Check if 'plots' exists and is not null
                                      var study_json = studyDetails['results'][0]['results'][0]['data'];
                                      if (study_json.containsKey('plots') && study_json['plots'] != null) {
                                        var plots = study_json['plots'] as List<dynamic>;
                                        int nPlots = 0;

                                        for (var plot in plots) {
                                          if (plot.containsKey('rows') && plot['rows'] is List && plot['rows'].isNotEmpty) {
                                            var row = plot['rows'][0];
                                            if (!(row.containsKey('discard') || row.containsKey('blank'))) {
                                              String plotID = row['_id']['\$oid'];
                                              String plotIndex =
                                                  row['study_index'].toString(); // Assuming study_index is the value to display
                                              plotIDs.add(plotID);
                                              plotDisplayValues.add(plotIndex);
                                              nPlots++;
                                            }
                                          }
                                        }

                                        print ("nPlots $nPlots");

                                        // Create the traits dictionary
                                        if (study_json.containsKey('phenotypes')) {
                                          var phenotypes = study_json['phenotypes'] as Map<String, dynamic>;

                                          phenotypes.forEach((key, value) {
                                            if (value.containsKey('definition')) {
                                              var definition = value['definition'];
                                              String variableName = definition['variable']['so:name'];
                                              String traitName = definition['trait']['so:name'];
                                              traits[variableName] = traitName;
                                              units[variableName] = definition['unit']['so:name'];
                                            }
                                          });
                                          print('Dictionary of traits: $traits');
                                          print('Dictionary of units: $units');
                                        }

                                        // REORGANIZE THE PLOT IDS AND PLOT DISPLAY VALUES
                                        // Step 1: Combine plotIDs and plotDisplayValues into a list of MapEntry
                                        var combinedList = List<MapEntry<String, String>>.generate(
                                          plotIDs.length,
                                          (index) => MapEntry(plotIDs[index], plotDisplayValues[index]),
                                        );

                                        // Step 2: Sort based on plotDisplayValues
                                        combinedList.sort((a, b) => int.parse(a.value).compareTo(int.parse(b.value)));
                                        // Step 3: Extract back into separate lists
                                        plotIDs = combinedList.map((e) => e.key).toList();
                                        plotDisplayValues = combinedList.map((e) => e.value).toList();

                                        // Update the state with the number of plots and their IDs
                                        setState(() {
                                          numberOfPlots = nPlots;
                                          fetchedStudyDetails = studyDetails; // Store the fetched details
                                        });

                                        print('Number of Plots: $nPlots');
                                        print('Plot IDs: $plotIDs');
                                        print('Plot Display Values: $plotDisplayValues');
                                      } else {
                                        print (">>>>>> failed to get study info");
                                      }

                                      // Update the state with other study details
                                      setState(() {
                                        studyTitle = studyDetails['results'][0]['results'][0]['title'];
                                        studyDescription = study_json ['so:description'];
                                        programme = study_json['parent_program']['so:name'];
                                        address = study_json['address']['name'];
                                        FTrial = study_json['parent_field_trial']['so:name'];
                                      });

                                      print('Selected Study ID: ${selectedStudyLabel?.id}');
                                      print('Study Title: $studyTitle');
                                      print('Study Description: $studyDescription');
                                      print('Study Programme: $programme');

                                    } else {
                                      print ("empty study for $id");
                                    }

                                  } else {
                                      print ("study id is null");
                                  }

                                } else {
                                   print ("****** selectedStudy is NULL");
                                }

 
                              } catch (e) {
                                print('**Error fetching study details: $e');
                              } finally {
                                setState(() {
                                  isSingleStudyLoading = false; // Ensure loading is stopped in all cases
                                });
                              }
                            },
                          ),

                          // End of dropdown to select a study.   END  OF 1st DROPDOWN MENU______
                          SizedBox(height: 20),
                          // __________MODAL FOR DISPLAYING STUDY DETAILS______
                          if (selectedStudyLabel != null) ...[
                            // Button to open the details dialog

                            ElevatedButton(
                              onPressed: () => _showStudyDetailsDialog(context),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 3, horizontal: 20),
                              ),
                              child: Text(
                                'View Study Details',
                                textAlign: TextAlign.center,
                              ),
                            ),

                            // TextButton(
                            //   onPressed: () => _showStudyDetailsDialog(context),
                            //   child: Text('View Study Details'),
                            // ),
                            SizedBox(height: 20),
                            // __________BUTTON TO ADD NEW OBSERVATION__________
                            //if (selectedPlotId?.isNotEmpty == true)
                            ElevatedButton(
                              onPressed: selectedPlotId == null
                                  ? null
                                  : () {
                                      // Use Navigator to push NewObservationPage with the required details
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => NewObservationPage(
                                            studyDetails: fetchedStudyDetails!,
                                            plotId: selectedPlotId!,
                                            plotDetails: selectedPlot ?? {},
                                            onReturn: onNewObservationReturn,
                                          ),
                                        ),
                                      );
                                    },
                              child: Text('Add New Observation or image'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).canvasColor,
                                textStyle: TextStyle (color: Theme.of(context).primaryColor),
                              ),
                            ),
                            SizedBox(height: 20),

                            // Dropdown to select a plot.  ______2nd DROPDOWN MENU______

                            if (plotDisplayValues.isNotEmpty) ...[
                              DropdownMenu (
                                dropdownMenuEntries:  List<DropdownMenuEntry<String>>.generate (
                                  plotDisplayValues.length,
                                  (index) => DropdownMenuEntry<String>(
                                    value: plotIDs[index],
                                    label: plotDisplayValues[index]),
                                  ),
                                
                                enableFilter: true,
                                textStyle: TextStyle (color: Theme.of(context).primaryColor),
                                label: const Text ("Search for a plot..."),
                                helperText: "Select a plot to view or edit",
                                trailingIcon: Icon (
                                  Icons.arrow_drop_down,
                                  color: Theme.of(context).primaryColor,
                                ),
                                inputDecorationTheme: InputDecorationTheme (
                                  labelStyle: TextStyle (color: Theme.of(context).primaryColor),
                                  helperStyle: TextStyle (color: Theme.of(context).primaryColor),
                                ),

                                /*
                                inputDecorationTheme: InputDecorationTheme(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                  constraints: BoxConstraints.tight(const 
                                  Size.fromHeight(40)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                */

                                menuHeight: 300,
                                menuStyle: MenuStyle (
                                  backgroundColor: WidgetStateProperty.all(Theme.of(context).canvasColor),
                                ),

                                onSelected: (String? plot_entry) async {
                                  setState(() {
                                    selectedPlotId = plot_entry;
                                    int index = plotIDs.indexOf(plot_entry!);
                                    if (index != -1) {
                                      selectedPlotDisplayValue = plotDisplayValues[index];
                                      selectedPhenotype = null;
                                      ///////////// Additional logic when a plot is selected /////
                                      /// Example: Count the number of observations in the selected plot
                                      var plots =
                                          fetchedStudyDetails!['results'][0]['results'][0]['data']['plots'] as List<dynamic>;

                                      // Find the plot that matches the selectedPlotId
                                      selectedPlot = plots.firstWhere(
                                        (plot) => plot['rows'] != null && plot['rows'][0]['_id']['\$oid'] == selectedPlotId,
                                        orElse: () => null,
                                      );

                                      if (selectedPlot != null) {
                                        // Since we've checked for null, it's safe to use '!'
                                        var observations = selectedPlot!['rows'][0]['observations'];
                                        if (observations != null) {
                                          var count = observations.length;
                                          observationCount = count;
                                          //  **********lists for phenotypes dropdown menu********
                                          variableToTraitMap.clear();

                                          for (var observation in observations) {
                                            if (observation.containsKey('phenotype') &&
                                                observation['phenotype'].containsKey('variable')) {
                                              String variable = observation['phenotype']['variable'];

                                              print('Variable: $variable, Exists in traits: ${traits.containsKey(variable)}');
                                              // Check if the trait exists for this variable and create a DropdownMenuItem
                                              if (traits.containsKey(variable)) {
                                                String traitName = traits[variable]!;
                                                variableToTraitMap[variable] = traitName;
                                              }
                                            }
                                          }

                                          print('Variable to Trait Map: $variableToTraitMap');
                                        } else {
                                          observationCount = 0;
                                        }
                                      }
                                    }
                                  });
                                  // Additional logic when a plot is selected, if needed
                                  print('Selected Plot ID: $plot_entry'); // Print the actual plot ID to console

                                },

                                
                              )
                            
                            ], // end if (plotDisplayValues is not empty)

                            // Plots dropdown
                            /*
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
                                      selectedPhenotype = null;
                                      ///////////// Additional logic when a plot is selected /////
                                      /// Example: Count the number of observations in the selected plot
                                      var plots =
                                          fetchedStudyDetails!['results'][0]['results'][0]['data']['plots'] as List<dynamic>;

                                      // Find the plot that matches the selectedPlotId
                                      selectedPlot = plots.firstWhere(
                                        (plot) => plot['rows'] != null && plot['rows'][0]['_id']['\$oid'] == selectedPlotId,
                                        orElse: () => null,
                                      );

                                      if (selectedPlot != null) {
                                        // Since we've checked for null, it's safe to use '!'
                                        var observations = selectedPlot!['rows'][0]['observations'];
                                        if (observations != null) {
                                          var count = observations.length;
                                          observationCount = count;
                                          //  **********lists for phenotypes dropdown menu********
                                          variableToTraitMap.clear();

                                          for (var observation in observations) {
                                            if (observation.containsKey('phenotype') &&
                                                observation['phenotype'].containsKey('variable')) {
                                              String variable = observation['phenotype']['variable'];

                                              print('Variable: $variable, Exists in traits: ${traits.containsKey(variable)}');
                                              // Check if the trait exists for this variable and create a DropdownMenuItem
                                              if (traits.containsKey(variable)) {
                                                String traitName = traits[variable]!;
                                                variableToTraitMap[variable] = traitName;
                                              }
                                            }
                                          }

                                          print('Variable to Trait Map: $variableToTraitMap');
                                        } else {
                                          observationCount = 0;
                                        }
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
                                  'Selected plot index: $selectedPlotDisplayValue',
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(height: 10),
                                Text('Number of observations: $observationCount'),
                              ],
                            ], // end if (plotDisplayValues is not empty)

                            // enf if (plotDisplayValues is not empty) SELECTED PLOT DROPDOWN
                            */
                            SizedBox(height: 20),
                            if (observationCount > 0) ...[
                              DropdownMenu (
                                dropdownMenuEntries: variableToTraitMap.entries.map((entry) {
                                  return DropdownMenuEntry <String>(
                                    value: entry.key, // The variable name as the value
                                    label: entry.value, // The trait name as the display text
                                  );
                                }).toList(),
                                
                                initialSelection: selectedPhenotype,
                                enableFilter: true,
                                textStyle: TextStyle (color: Theme.of(context).primaryColor),
                                label: const Text ("Select Phenotype..."),
                                helperText: "Select a Phenotype to view or edit",
                                trailingIcon: Icon (
                                  Icons.arrow_drop_down,
                                  color: Theme.of(context).primaryColor,
                                ),
                                inputDecorationTheme: InputDecorationTheme (
                                  labelStyle: TextStyle (color: Theme.of(context).primaryColor),
                                  helperStyle: TextStyle (color: Theme.of(context).primaryColor),
                                ),

                                onSelected: (String? newValue) {
                                  setState(() {
                                    selectedPhenotype = newValue;
                                  });
                                  //processSelectedPhenotype();
                                  List<Map<String, dynamic>> rawValues = findRawValuesForSelectedPhenotype();
                                  // Display the dialog with the ObservationTable
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      // find selectedphenotype in units and assign it to displayUnit
                                      String displayUnit = 'Some Unit'; //
                                      if (units.containsKey(selectedPhenotype)) {
                                        displayUnit = units[selectedPhenotype]!;
                                      }
                                      // find selectedphenotype in traits and assign it to displayTrait
                                      String displayTrait = 'Some trait';
                                      if (traits.containsKey(selectedPhenotype)) {
                                        displayTrait = traits[selectedPhenotype]!;
                                      }

                                      return Dialog(
                                        child: SingleChildScrollView(
                                          child: Container(
                                            padding: EdgeInsets.all(20.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(displayTrait, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                                SizedBox(height: 10),
                                                Text('Unit: $displayUnit', style: TextStyle(fontSize: 15)),
                                                SizedBox(height: 20),
                                                if (rawValues.isEmpty)
                                                  Text('No Data Found')
                                                else
                                                  ObservationTable(rawValues: rawValues),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ); // End of showDialog
                                },

                                menuHeight: 300,
                                menuStyle: MenuStyle (
                                  backgroundColor: WidgetStateProperty.all(Theme.of(context).canvasColor),
                                ),
                              
                              ),

/*
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: selectedPhenotype,
                                hint: Text("Select phenotype"),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedPhenotype = newValue;
                                  });
                                  //processSelectedPhenotype();
                                  List<Map<String, dynamic>> rawValues = findRawValuesForSelectedPhenotype();
                                  // Display the dialog with the ObservationTable
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      // find selectedphenotype in units and assign it to displayUnit
                                      String displayUnit = 'Some Unit'; //
                                      if (units.containsKey(selectedPhenotype)) {
                                        displayUnit = units[selectedPhenotype]!;
                                      }
                                      // find selectedphenotype in traits and assign it to displayTrait
                                      String displayTrait = 'Some trait';
                                      if (traits.containsKey(selectedPhenotype)) {
                                        displayTrait = traits[selectedPhenotype]!;
                                      }

                                      return Dialog(
                                        child: SingleChildScrollView(
                                          child: Container(
                                            padding: EdgeInsets.all(20.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(displayTrait, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                                SizedBox(height: 10),
                                                Text('Unit: $displayUnit', style: TextStyle(fontSize: 15)),
                                                SizedBox(height: 20),
                                                if (rawValues.isEmpty)
                                                  Text('No Data Found')
                                                else
                                                  ObservationTable(rawValues: rawValues),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ); // End of showDialog
                                },
                                items: variableToTraitMap.entries.map((entry) {
                                  return DropdownMenuItem<String>(
                                    value: entry.key, // The variable name as the value
                                    child: Text(
                                      entry.value, // The trait name as the display text
                                      overflow: TextOverflow.ellipsis, // Use ellipsis for text overflow
                                      softWrap: false, // Prevents text wrapping onto the next line
                                    ),
                                  );
                                }).toList(),
                              ),
*/
                              SizedBox(height: 20),
                            ],
                          ], // IF studyTitle is not null
                        ],
                      ),
                    ),
            ),
    );
  }
}