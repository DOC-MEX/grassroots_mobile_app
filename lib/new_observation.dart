//name: NewObservationPage  (new_observation.dart)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
//import 'package:http/http.dart' as http;
import 'dart:io';
import 'full_size_image_screen.dart';
import 'grassroots_request.dart';
import 'backend_request.dart';
import 'api_requests.dart';

import 'package:hive/hive.dart'; 
import 'models/observation.dart'; // Import the Observation model

class NewObservationPage extends StatefulWidget {
  final Map<String, dynamic> studyDetails;
  final String plotId;
  final Map<String, dynamic> plotDetails;
  final Function(Map<String, dynamic>) onReturn;
  final String? selectedTraitKey;

  NewObservationPage({
    required this.studyDetails,
    required this.plotId,
    required this.plotDetails,
    required this.onReturn,
    this.selectedTraitKey,
  });

  @override
  _NewObservationPageState createState() => _NewObservationPageState();
}

class _NewObservationPageState extends State<NewObservationPage> {
  Map<String, String> traits = {};
  Map<String, String> units = {};
  Map<String, String> scales = {};
  String? selectedTraitKey;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _textEditingController = TextEditingController();
  final TextEditingController _notesEditingController = TextEditingController();
  final TextEditingController _maxHeightController = TextEditingController();
  final TextEditingController _minHeightController = TextEditingController();
  DateTime? selectedDate;
  File? _image;
  String? studyID;
  int? plotNumber;
  String? _imageUrl;
  DateTime? _photoDate;
  //int? maxHeight;
  int? minHeight;
  bool _isUploading = false; // for form clearing
  bool isClearingForm = false;
  bool _isPhotoLoading = false; // Lock for photo loading
  bool submissionSuccessful = false; // Flag for successful submission
  bool _isImageUploaded = false; // Tracks if the image is uploaded
  bool _isNewImageSelected = false; // Tracks if a new image is selected
  // New Maps to store min and max limits for each trait
  Map<String, int?> minLimits = {};
  Map<String, int?> maxLimits = {};
  bool isNavigating = false;

  @override
  void initState() {
    super.initState();

    selectedTraitKey = widget.selectedTraitKey; // Initialize with passed trait key
    _extractPhenotypeDetails();
    // Attempt to retrieve the photo when the page loads
    _initRetrievePhoto();
    // Attempt to retrieve the limits when the page loads
    _initRetrieveLimits();
  }

  @override
  void dispose() {
    // Dispose of your controllers here
    _maxHeightController.dispose();
    _minHeightController.dispose();
    // Call the dispose method of the superclass at the end
    super.dispose();
  }

  String? extractDateFromImageUrl(String imageUrl) {
    RegExp regExp = RegExp(r'photo_plot_\d+_(\d{4}_\d{2}_\d{2})\.jpg$');
    final match = regExp.firstMatch(imageUrl);
    return match?.group(1); // Returns 'YYYY_MM_DD'
  }

  bool isNumericalTrait(String? traitKey) {
    // Only allow numerical traits with units "cm", "mm", "g", "m", and "mm2"
    final allowedUnits = ['cm', 'mm', 'g', 'm', 'mm2'];
    return units[traitKey] != null && allowedUnits.contains(units[traitKey]);
  }

  Future<void> _initRetrievePhoto() async {
    var result = await ApiRequests.retrieveLastestPhoto(studyID ?? 'defaultFolder', plotNumber!);

    if (result['status'] == 'success') {
      if (mounted) {
        setState(() {
          _imageUrl = result['url'];
          // Extract and format date
          String? dateStr = extractDateFromImageUrl(_imageUrl!);
          _photoDate = dateStr != null ? DateFormat('yyyy_MM_dd').parse(dateStr) : null;
        });
      }
    } else if (result['status'] == 'not_found') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Plot has no photo')));
    } else if (result['status'] == 'error') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
    }
  }

  Future<void> _initRetrieveLimits() async {
    var limits = await ApiRequests.retrieveLimits(studyID ?? 'defaultFolder');
    if (mounted && limits != null) {
      setState(() {
        // Clear existing limits (optional, depending on your use case)
        minLimits.clear();
        maxLimits.clear();

        // Iterate through the limits map and populate minLimits and maxLimits
        limits.forEach((traitKey, traitLimits) {
          minLimits[traitKey] = traitLimits['min'];
          maxLimits[traitKey] = traitLimits['max'];
        });
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _isImageUploaded = false; // Reset the upload status
        _isNewImageSelected = true; // Indicate that a new image is selected
        _imageUrl = null;
      });
    }
  }

  // Function to pick an image from the gallery
  Future<void> _pickImageFromGallery() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _imageUrl = null;
        _isImageUploaded = false; // Reset the upload status
        _isNewImageSelected = true; // Indicate that a new image is selected
      });
    }
  }

  // function to handle the upload of image using an API request "uploadImage"
  void _handleUpload() async {
    if (_image != null && studyID != null && plotNumber != null) {
      setState(() {
        _isUploading = true; // Start of upload
      });

      bool uploadSuccess = await ApiRequests.uploadImageDate(_image!, studyID!, plotNumber!);
      if (!mounted) return; // Check if the widget is still mounted

      setState(() {
        _isUploading = false; // End of upload
        if (uploadSuccess) {
          _isImageUploaded = true; // Mark as uploaded
          _isNewImageSelected = false; // Reset new image flag
          _photoDate = DateTime.now(); // Set the current date as the photo date
        }
      });

      String message = uploadSuccess ? 'Upload successful' : 'Upload failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } else {
      // Handle null values error
    }
  }

  ////////////////////////////////////////////////////////

  void _extractPhenotypeDetails() {
    if (widget.studyDetails['results'][0]['results'][0]['data'].containsKey('phenotypes')) {
      var phenotypes = widget.studyDetails['results'][0]['results'][0]['data']['phenotypes'] as Map<String, dynamic>;
      phenotypes.forEach((key, value) {
        if (value.containsKey('definition')) {
          var definition = value['definition'];
          traits[key] = definition['trait']['so:name'];
          units[key] = definition['unit']['so:name'];
          if (definition.containsKey('scale')) {
            scales[key] = definition['scale']['so:name'];
          }
        }
      });
    }
    //print plotID
    print('extracted Plot ID: ${widget.plotId}');
    //print('Traits: $traits');
    //print('Units: $units');
    //print('Scales: $scales');

    // Extract the studyID
    try {
      studyID = widget.studyDetails['results'][0]['results'][0]['data']['_id']['\$oid'];
      //  print('Extracted Study ID: $studyID');
    } catch (e) {
      print('Error extracting Study ID: $e');
    }
    //Extract the plotNumber (['study_index'])
    try {
      plotNumber = widget.plotDetails['rows'][0]['study_index'];
      print('Extracted Plot Number: $plotNumber');
    } catch (e) {
      print('Error extracting Plot Number: $e');
    }
    ////////////////////////////////////////////////////////////////////////////
  }

  void moveToNextPlot() async {
    if (isNavigating) return; // Prevent multiple rapid navigations
    setState(() {
      isNavigating = true; // Mark navigation as in progress
    });

    var plots = widget.studyDetails['results'][0]['results'][0]['data']['plots'] as List<dynamic>;

    if (plots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No more plots available')),
      );
      setState(() {
        isNavigating = false; // Reset the navigation flag
      });
      return;
    }

    // Sort the plots by 'study_index' in ascending order
    plots.sort((a, b) {
      var indexA = a['rows']?[0]['study_index'] as int? ?? 0;
      var indexB = b['rows']?[0]['study_index'] as int? ?? 0;
      return indexA.compareTo(indexB);
    });

    Map<String, dynamic>? nextPlotDetails;
    String? nextPlotId;

    if (_isPhotoLoading) {
      print("Photo is still loading, please wait.");
      setState(() {
        isNavigating = false; // Reset the navigation flag
      });
      return;
    }

    int currentIndex = plotNumber ?? -1;

    for (var plot in plots) {
      var nextIndex = plot['rows']?[0]['study_index'] as int?;
      if (nextIndex != null &&
          nextIndex > currentIndex &&
          !(plot['rows'][0].containsKey('discard') && plot['rows'][0]['discard'])) {
        nextPlotDetails = plot;
        nextPlotId = plot['rows'][0]['_id']['\$oid'];
        break;
      }
    }

    if (nextPlotId != null && nextPlotDetails != null) {
      try {
        await Future.delayed(Duration(milliseconds: 300)); // Small delay to avoid rapid navigation

        if (!mounted) {
          setState(() {
            isNavigating = false; // Reset the navigation flag
          });
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NewObservationPage(
              studyDetails: widget.studyDetails,
              plotId: nextPlotId!,
              plotDetails: nextPlotDetails ?? {},
              onReturn: widget.onReturn,
              selectedTraitKey: selectedTraitKey, // Pass the selected trait to the next plot
            ),
          ),
        ).then((_) {
          if (!mounted) return; // Ensure the widget is still mounted
          setState(() {
            isNavigating = false; // Reset the navigation flag
          });
        });
      } catch (e) {
        print('Error navigating to the next plot: $e');
        setState(() {
          isNavigating = false; // Reset the navigation flag
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No more valid plots available')),
      );
      setState(() {
        isNavigating = false; // Reset the navigation flag
      });
    }
  }

  void moveToPreviousPlot() async {
    if (isNavigating) return; // Prevent multiple rapid navigations
    setState(() {
      isNavigating = true; // Mark navigation as in progress
    });

    var plots = widget.studyDetails['results'][0]['results'][0]['data']['plots'] as List<dynamic>;

    if (plots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No more plots available')),
      );
      setState(() {
        isNavigating = false; // Reset the navigation flag
      });
      return;
    }

    plots.sort((a, b) {
      var indexA = a['rows']?[0]['study_index'] as int? ?? 0;
      var indexB = b['rows']?[0]['study_index'] as int? ?? 0;
      return indexA.compareTo(indexB);
    });

    Map<String, dynamic>? previousPlotDetails;
    String? previousPlotId;

    if (_isPhotoLoading) {
      print("Photo is still loading, please wait.");
      setState(() {
        isNavigating = false; // Reset the navigation flag
      });
      return;
    }

    int currentIndex = plotNumber ?? -1;

    for (var plot in plots.reversed) {
      var prevIndex = plot['rows']?[0]['study_index'] as int?;
      if (prevIndex != null &&
          prevIndex < currentIndex &&
          !(plot['rows'][0].containsKey('discard') && plot['rows'][0]['discard'])) {
        previousPlotDetails = plot;
        previousPlotId = plot['rows'][0]['_id']['\$oid'];
        break;
      }
    }

    if (previousPlotId != null && previousPlotDetails != null) {
      try {
        await Future.delayed(Duration(milliseconds: 300)); // Small delay to avoid rapid navigation

        if (!mounted) {
          setState(() {
            isNavigating = false; // Reset the navigation flag
          });
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NewObservationPage(
              studyDetails: widget.studyDetails,
              plotId: previousPlotId!,
              plotDetails: previousPlotDetails ?? {},
              onReturn: widget.onReturn,
              selectedTraitKey: selectedTraitKey, // Pass the selected trait to the next plot
            ),
          ),
        ).then((_) {
          if (!mounted) return; // Ensure the widget is still mounted
          setState(() {
            isNavigating = false; // Reset the navigation flag
          });
        });
      } catch (e) {
        print('Error navigating to the previous plot: $e');
        setState(() {
          isNavigating = false; // Reset the navigation flag
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No more valid previous plots available')),
      );
      setState(() {
        isNavigating = false; // Reset the navigation flag
      });
    }
  }

////////////////////////////////////////////////////////////////////
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        _textEditingController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _showEditLimitsDialog() {
    // Set the current values in the controllers
    ///////_maxHeightController.text = maxHeight?.toString() ?? '';
    /////////_minHeightController.text = minHeight?.toString() ?? '';

    _maxHeightController.text = maxLimits[selectedTraitKey]?.toString() ?? '';
    _minHeightController.text = minLimits[selectedTraitKey]?.toString() ?? '';
    //print unit
    //print('Unit: ${units[selectedTraitKey]}');
    // print trait
    //print('Trait: $selectedTraitKey');
    //print(traits[selectedTraitKey]);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          //title: Text('Edit Values for ${selectedTraitKey ?? ''}'),
          title: Text('Edit Values for ${traits[selectedTraitKey] ?? ''}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: [
                    Text('Max: '),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: TextField(
                              controller: _maxHeightController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Enter new max value',
                              ),
                            ),
                          ),
                          Text(' ${units[selectedTraitKey]}'),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Text('Min: '),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: TextField(
                              controller: _minHeightController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Enter new min value',
                              ),
                            ),
                          ),
                          Text(' ${units[selectedTraitKey]}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Update'),
              onPressed: () async {
                // Parse and validate the new max and min values
                int? newMax = int.tryParse(_maxHeightController.text);
                int? newMin = int.tryParse(_minHeightController.text);

                if (newMax != null && newMin != null && newMin < newMax) {
                  bool updated = await ApiRequests.updateLimits(
                      studyID ?? 'defaultFolder', newMin, newMax, selectedTraitKey ?? 'default_trait');

                  if (updated) {
                    setState(() {
                      maxLimits[selectedTraitKey!] = newMax;
                      minLimits[selectedTraitKey!] = newMin;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Limits updated successfully')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update limits')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invalid input')),
                  );
                }
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTraitDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedTraitKey, // This value is now maintained between plots
      hint: Text("Select a trait"),
      onChanged: _onTraitChanged,
      items: traits.keys.map<DropdownMenuItem<String>>((String key) {
        return DropdownMenuItem<String>(
          value: key,
          child: Text(traits[key] ?? 'Unknown'),
        );
      }).toList(),
      validator: (value) => value == null ? 'Please select a trait' : null,
    );
  }

  void _onTraitChanged(String? newValue) {
    setState(() {
      selectedTraitKey = newValue;
    });

    // Retrieve scale and unit for the selected trait
    String? selectedScale = scales[selectedTraitKey];
    String? selectedUnit = units[selectedTraitKey];

    // Print scale and unit for the selected trait
    print('Selected Trait: $selectedTraitKey');
    print('Scale: $selectedScale');
    print('Unit: $selectedUnit');

    // Only show snackbar if unit is 'yyyymmdd' and not clearing the form
    if (!isClearingForm && units[selectedTraitKey] == 'yyyymmdd') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 3),
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.yellow),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Select a date",
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

Future<void> _submitObservation() async {
  if (_formKey.currentState!.validate()) {
    String plotID = widget.plotId; // Plot ID
    String? trait = selectedTraitKey; // Selected trait
    String measurement = _textEditingController.text; // Entered measurement
    String dateString = DateFormat('yyyy-MM-dd').format(selectedDate ?? DateTime.now()); // Date
    String? note = _notesEditingController.text.isEmpty ? null : _notesEditingController.text; // Notes

    print('Plot ID: $plotID');
    print('Trait: $trait');
    print('Measurement: $measurement');
    print('Note: $note');
    print('Study ID: $studyID');

    try {
      // Create the JSON request
      String jsonString = backendRequests.submitObservationRequest(
        studyID: studyID ?? 'defaultStudyID',
        detectedQRCode: plotID,
        selectedTrait: trait,
        measurement: measurement,
        dateString: dateString,
        note: note,
      );
      
      print('Request to server: $jsonString');

      if (jsonString != '{}') {
        var response = await GrassrootsRequest.sendRequest(jsonString, 'private');
        
        print('Response from server: $response');

        String? statusText = response['results']?[0]['status_text'];
        submissionSuccessful = statusText != null && statusText == 'Succeeded';

        if (submissionSuccessful) {
          print('Submission successful *****SET FLAG TO TRUE******');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Data successfully submitted',
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          );
        } else {
          print('Submission failed: $statusText');
          throw Exception('Failed to submit observation');
        }
      } else {
        print('NOT ALLOWED');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission not allowed for this study')),
        );
      }
    } catch (e) {
      // Original error handling print
      print('Error sending request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Failed to submit data',
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
            ],
          ),
        ),
      );
    } finally {
      // Save locally
      final observation = Observation(
        plotId: plotID,
        trait: trait ?? 'Unknown',
        value: measurement,
        notes: note,
        photoPath: _image?.path,
        date: dateString,
        syncStatus: submissionSuccessful ? 'synced' : 'pending',
      );

      
      print('Saving locally: ${observation.toJson()}');
      await _saveObservationLocally(observation);

      // Pass the result back to the parent
      widget.onReturn({
        'plotId': plotID,
        'submissionSuccessful': submissionSuccessful,
      });

      _clearForm(); // Clears the form after saving and returning data
    }
  }
}

Future<void> _saveObservationLocally(Observation observation) async {
  try {
    // Open the Hive box
    var box = await Hive.openBox<Observation>('observations');

    // Save the observation to the box
    await box.add(observation);

    // Debug print to confirm the observation was saved
    print('Observation saved locally: ${observation.toJson()}');
  } catch (e) {
    // Handle any errors that occur during the save process
    print('Error saving observation locally: $e');
  }
}


void _clearForm() {
    _formKey.currentState!.reset();
    setState(() {
      selectedDate = null;
      _textEditingController.clear();
      _notesEditingController.clear();
      _image = null;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Reset the image state
            setState(() {
              _image = null;
              _imageUrl = null;
            });

            // Pop the current route
            Navigator.of(context).pop();
          },
        ),
        //title: Text('New Observation for plot ${plotNumber ?? 'Loading...'}'),
        title: Text('Plot ${plotNumber ?? 'Loading...'}'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                // Conditional Button for Editing Max and Min Values
                //if (selectedTraitKey == 'PH_M_cm' || selectedTraitKey == 'FLeafLLng_M_cm')
                if (isNumericalTrait(selectedTraitKey))
                  ElevatedButton(
                    onPressed: _showEditLimitsDialog,
                    child: Text('Edit max and min'),
                  ),
                SizedBox(height: 10), // Spacing after the button
                //////////////////////////
                // FIRST  DROPDOWN MENU
                //////////////////////////
                _buildTraitDropdown(),
                //////////////////////////
                // END OF FIRST  DROPDOWN MENU
                SizedBox(height: 20),
                // OBSERVATION FIELD (with validations)
                //////////////////////////
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end, // Align the TextFormField and Text vertically
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _textEditingController,
                        readOnly: units[selectedTraitKey] == 'yyyymmdd', // Make field read-only when unit is 'yyyymmdd'
                        keyboardType: units[selectedTraitKey] == 'day' ? TextInputType.number : TextInputType.datetime,
                        decoration: InputDecoration(
                          labelText: units[selectedTraitKey] == 'yyyymmdd' ? 'Select date' : 'Enter value',
                          hintText: units[selectedTraitKey] == 'yyyymmdd' ? 'Select a date' : 'Enter value',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a value';
                          }

                          // Handling 'yyyymmdd' as a special case
                          if (units[selectedTraitKey] == 'yyyymmdd') {
                            try {
                              DateFormat('yyyy-MM-dd').parse(value); // Check if value is in 'yyyy-MM-dd' format
                            } catch (e) {
                              return 'Please enter a date in the format YYYY-MM-DD';
                            }
                            return null; // No validation error for date
                          }
                          // For other units, validate as number
                          final num? numberValue = num.tryParse(value);
                          if (numberValue == null) {
                            return 'Please enter a valid number';
                          }

                          // Validation for Plant Height
                          //if (selectedTraitKey == 'PH_M_cm' && minHeight != null && maxHeight != null) {
                          //  double valueAsDouble = numberValue.toDouble();
                          //  if (valueAsDouble < minHeight! || valueAsDouble > maxHeight!) {
                          //    return 'Value must be between $minHeight and $maxHeight';
                          //  }
                          //}
                          // Generalized min/max validation for any trait in minLimits and maxLimits
                          if (minLimits[selectedTraitKey] != null && maxLimits[selectedTraitKey] != null) {
                            if (numberValue < minLimits[selectedTraitKey]! || numberValue > maxLimits[selectedTraitKey]!) {
                              return 'Value must be between ${minLimits[selectedTraitKey]} and ${maxLimits[selectedTraitKey]}';
                            }
                          }

                          if (units[selectedTraitKey] == '%') {
                            final num? numberValue = num.tryParse(value);
                            if (numberValue == null) {
                              return 'Please enter a valid number';
                            }
                            if (numberValue < 0 || numberValue > 100) {
                              return 'Value must be between 0 and 100';
                            }
                          }
                          if (units[selectedTraitKey] == 'day') {
                            final int? intValue = int.tryParse(value);
                            if (intValue == null || intValue <= 0) {
                              return 'Please enter a positive integer';
                            }
                          }
                          // Additional validation based on selected trait...
                          return null;
                        },
                        onTap: units[selectedTraitKey] == 'yyyymmdd'
                            ? () => _selectDate(context)
                            : null, // Open date picker if unit is 'yyyymmdd'
                      ),
                    ),
                    // Conditionally display the unit next to the TextFormField
                    if (units[selectedTraitKey] != null && units[selectedTraitKey]!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          units[selectedTraitKey] ?? '', // Display the unit
                          style: TextStyle(fontSize: 16), // Adjust styling as needed
                        ),
                      ),
                    // Display the date picker icon only for 'yyyymmdd' unit
                    if (units[selectedTraitKey] == 'yyyymmdd')
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context),
                          iconSize: 30,
                        ),
                      ),
                  ],
                ),

                //////////// Date Picker  //////////////
                SizedBox(height: 20),
                ListTile(
                  title: Text("Observation date (current date is default)"),
                  subtitle: Text(
                    selectedDate != null ? '${selectedDate!.toLocal()}'.split(' ')[0] : 'Press to choose different date',
                  ),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2000), // Adjust the range as needed
                      lastDate: DateTime(2101),
                    );
                    if (picked != null && picked != selectedDate)
                      setState(() {
                        selectedDate = picked;
                      });
                  },
                ),
                //////////// Date Picker  //////////////
                SizedBox(height: 20),
                ///// Note field /////
                TextFormField(
                  controller: _notesEditingController,
                  decoration: InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'Enter any additional notes here',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                  //maxLines: 1, // Allow multiline input
                  validator: (value) {
                    // Optional: Add validation logic if needed
                    if (value!.length > 500) {
                      return 'Note too long. Please limit to 500 characters.';
                    }
                    return null; // No validation error
                  },
                ),
                //////
                SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Submit Observation button (occupies exactly half the width)
                    Expanded(
                      flex: 1, // Adjusted to occupy half of the width
                      child: ElevatedButton(
                        onPressed: _submitObservation,
                        child: Text(
                          'Submit Observation',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    SizedBox(width: 10), // Add some spacing between the submit button and the arrows

// Arrow buttons container (Previous and Next)
                    Expanded(
                      flex: 1, // The arrow buttons will occupy the remaining half of the row
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Spread out the arrow buttons
                            children: [
                              // Left Arrow button (Previous plot)
                              Column(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      moveToPreviousPlot(); // Function to go to the previous plot
                                      print('Previous Plot');
                                    },
                                    icon: Icon(Icons.arrow_back),
                                    iconSize: 40.0, // Increase the size of the arrow icon
                                    tooltip: 'Previous Plot',
                                  ),
                                  Text(
                                    'Previous Plot', // Explanatory text
                                    style: TextStyle(fontSize: 12), // Smaller font size
                                  ),
                                ],
                              ),

                              // Right Arrow button (Next plot)
                              Column(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      moveToNextPlot(); // Function to go to the next plot
                                    },
                                    icon: Icon(Icons.arrow_forward),
                                    iconSize: 40.0, // Increase the size of the arrow icon
                                    tooltip: 'Next Plot',
                                  ),
                                  Text(
                                    'Next Plot', // Explanatory text
                                    style: TextStyle(fontSize: 12), // Smaller font size
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                ////////////////////////////////////////////////////////
                SizedBox(height: 20),
                // put take picture button and select from gallery button in the same row

                ////////////////////////////////////////////////////////
                // Conditional rendering of the image and the upload button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _pickImage();
                        },
                        child: Text('Take a picture'),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _pickImageFromGallery,
                        child: Text(
                          'Select from gallery',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                // Conditional rendering retrieved image (if needed) or newly uploaded image
                if (_imageUrl != null || _image != null)
                  Column(
                    children: [
                      if (_photoDate != null) // Check if _photoDate is not null
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0), // Add some space between the date and the photo
                          child: Text(
                            'Photo from ${DateFormat('d MMMM, yyyy').format(_photoDate!)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (_imageUrl != null)
                        GestureDetector(
                          onTap: () {
                            // When the user taps on the image, navigate to a new screen with the full-size image
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    FullSizeImageScreen(imageUrl: _imageUrl, plotNumber: plotNumber, photoDate: _photoDate),
                              ),
                            );
                          },
                          child: Hero(
                            tag: 'imageHero', // Unique tag for the Hero widget
                            child: Container(
                              height: 200,
                              width: double.infinity,
                              child: Image.network(_imageUrl!, fit: BoxFit.cover),
                            ),
                          ),
                        ),
                      if (_image != null)
                        GestureDetector(
                          onTap: () {
                            // When the user taps on the image, navigate to a new screen with the full-size image
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => FullSizeImageScreenFile(imageFile: _image, plotNumber: plotNumber),
                              ),
                            );
                          },
                          child: Hero(
                            tag: 'imageHero', // Unique tag for the Hero widget
                            child: Container(
                              height: 200,
                              width: double.infinity,
                              child: Image.file(_image!, fit: BoxFit.cover),
                            ),
                          ),
                        ),
                    ],
                  ),

                ///////////////////////////////////////////////
                ///////////////////////////////////////////
                if (_image != null)
                  ElevatedButton(
                    onPressed: (_isUploading || _isImageUploaded)
                        ? null
                        : _handleUpload, // Disable button when uploading or after upload
                    child: _isUploading
                        ? CircularProgressIndicator() // Show loading indicator
                        : Text('Upload Image'),
                  ),
              ],
            ),
          ), //Form
        ),
      ),
    );
  }
}
