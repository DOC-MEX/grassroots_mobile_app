//name: NewObservationPage  (new_observation.dart)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
//import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:typed_data';
import 'full_size_image_screen.dart';
import 'grassroots_request.dart';
import 'qr_code_service.dart';
import 'api_requests.dart';

class NewObservationPage extends StatefulWidget {
  final Map<String, dynamic> studyDetails;
  final String plotId;
  final Map<String, dynamic> plotDetails;
  final Function(Map<String, dynamic>) onReturn;

  NewObservationPage({
    required this.studyDetails,
    required this.plotId,
    required this.plotDetails,
    required this.onReturn,
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
  Uint8List? _imageBytes;
  int? maxHeight;
  int? minHeight;
  bool _isUploading = false; // for form clearing
  bool isClearingForm = false;
  bool _isPhotoLoading = false; // Lock for photo loading
  bool submissionSuccessful = false; // Flag for successful submission

  @override
  void initState() {
    super.initState();
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

  Future<void> _initRetrievePhoto() async {
    var result = await ApiRequests.retrievePhoto(studyID ?? 'defaultFolder', plotNumber!);

    if (result['status'] == 'success') {
      if (mounted) {
        setState(() {
          _imageBytes = result['data'];
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
    if (mounted) {
      // Check if the widget is still mounted
      setState(() {
        minHeight = limits?['minHeight'];
        maxHeight = limits?['maxHeight'];
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _imageBytes = null; // Reset the retrieved image
      });
    }
  }

  // Function to pick an image from the gallery
  Future<void> _pickImageFromGallery() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _imageBytes = null; // Reset the retrieved image
      });
    }
  }

  // function to handle the upload of image using an API request "uploadImage"
  void _handleUpload() async {
    if (_image != null && studyID != null && plotNumber != null) {
      setState(() {
        _isUploading = true; // Start of upload
      });

      bool uploadSuccess = await ApiRequests.uploadImage(_image!, studyID!, plotNumber!);
      if (!mounted) return; // Check if the widget is still mounted

      setState(() {
        _isUploading = false; // End of upload
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

  void moveToNextPlot() {
    var plots = widget.studyDetails['results'][0]['results'][0]['data']['plots'] as List<dynamic>;
    Map<String, dynamic>? nextPlotDetails;
    String? nextPlotId;

    if (_isPhotoLoading) {
      print("Photo is still loading, please wait.");
      // Optionally, show a user-friendly message here
      return;
    }

    int currentIndex = plots.indexWhere((plot) => plot['rows']?[0]['study_index'] == plotNumber);

    // Check if current plot is found and not the last plot in the list
    if (currentIndex != -1 && currentIndex < plots.length - 1) {
      int nextIndex = currentIndex + 1;
      while (nextIndex < plots.length) {
        var potentialNextPlot = plots[nextIndex];
        // Check if the next plot is valid (not marked as discard and has 'rows' key)
        if (potentialNextPlot.containsKey('rows') &&
            !(potentialNextPlot['rows'][0].containsKey('discard') && potentialNextPlot['rows'][0]['discard'])) {
          nextPlotDetails = potentialNextPlot;
          //nextPlotId = nextPlotDetails?['_id']['\$oid'];
          nextPlotId = nextPlotDetails?['rows'][0]['_id']['\$oid'];
          break;
        }
        nextIndex++;
      }
    }

    // Print variables needed for the next plot
    //print('-------Next Plot ID: $nextPlotId');
    //print('------Next Plot Details: $nextPlotDetails');

    if (nextPlotId != null && nextPlotDetails != null) {
      try {
        Future.delayed(Duration(milliseconds: 500), () {
          if (!mounted) return; // Check if the widget is still in the widget tree
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => NewObservationPage(
                  studyDetails: widget.studyDetails,
                  plotId: nextPlotId!,
                  plotDetails: nextPlotDetails ?? {},
                  onReturn: widget.onReturn),
            ),
          ).then((_) {
            if (!mounted) return; // Check if the widget is still in the widget tree
          });
        });
      } catch (e) {
        print('Error navigating to the next plot: $e');
        // Optionally, you can show a snackbar or a dialog here to inform the user
      }
    } else {
      // Handle the case where there's no next plot to navigate to
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No more plots available')),
      );
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
    _maxHeightController.text = maxHeight?.toString() ?? '';
    _minHeightController.text = minHeight?.toString() ?? '';
    //print unit
    //print('Unit: ${units[selectedTraitKey]}');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Values'),
          content: SingleChildScrollView(
            // Make the dialog scrollable
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
                              //maxLength: 4, // Limit the input to 4 digits
                              decoration: InputDecoration(
                                hintText: 'Enter new max value',
                              ),
                            ),
                          ),
                          Text(' ${units[selectedTraitKey]}'), // Display the unit to the right
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
                // Parse and validate new max and min values
                int? newMax = int.tryParse(_maxHeightController.text);
                int? newMin = int.tryParse(_minHeightController.text);

                if (newMax != null && newMin != null && newMin < newMax) {
                  // Send POST request to update values using ApiRequests
                  bool updated = await ApiRequests.updateLimits(studyID ?? 'defaultFolder', newMin, newMax);
                  if (updated) {
                    setState(() {
                      maxHeight = newMax;
                      minHeight = newMin;
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
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTraitDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedTraitKey,
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

  @override
  Widget build(BuildContext context) {
    void clearForm() {
      _formKey.currentState!.reset();
      setState(() {
        selectedTraitKey = null; // Reset the dropdown
        selectedDate = null;
        _textEditingController.clear();
        _notesEditingController.clear();
        isClearingForm = false;
        // Any other controllers or variables should be reset here
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('New Observation for plot ${plotNumber ?? 'Loading...'}'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                // Conditional Button for Editing Max and Min Values
                if (selectedTraitKey == 'PH_M_cm')
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
                          if (selectedTraitKey == 'PH_M_cm' && minHeight != null && maxHeight != null) {
                            double valueAsDouble = numberValue.toDouble();
                            if (valueAsDouble < minHeight! || valueAsDouble > maxHeight!) {
                              return 'Value must be between $minHeight and $maxHeight';
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
                    selectedDate != null ? '${selectedDate!.toLocal()}'.split(' ')[0] : 'No date chosen',
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
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            // Extract form data
                            String plotID = widget.plotId; // Plot ID
                            String? trait = selectedTraitKey; // Selected trait
                            String measurement = _textEditingController.text; // Entered measurement
                            String dateString = DateFormat('yyyy-MM-dd').format(selectedDate ?? DateTime.now()); // Date
                            String? note = _notesEditingController.text.isEmpty
                                ? null
                                : _notesEditingController.text; // Notes, null if empty
                            print('Plot ID: $plotID');
                            print('Trait: $trait');
                            print('Measurement: $measurement');
                            //print('Date: $dateString');
                            print('Note: $note');
                            //Print study ID
                            print('Study ID: $studyID');
                            try {
                              // Create the JSON request
                              String jsonString = QRCodeService.submitObservationRequest(
                                studyID: studyID ?? 'defaultStudyID', // Add studyID parameter
                                detectedQRCode: plotID,
                                selectedTrait: trait,
                                measurement: measurement,
                                dateString: dateString,
                                note: note,
                              );
                              if (jsonString != '{}') {
                                // Send the request to the server and await the response
                                var response = await GrassrootsRequest.sendRequest(jsonString, 'private');

                                // Handle the response data
                                //print('Response from server: $response');
                                String? statusText = response['results']?[0]['status_text'];
                                if (statusText != null && statusText == 'Succeeded') {
                                  submissionSuccessful = true;
                                  print('Submission successful *****SET FLAG TO TRUE******');
                                  // Update the flag in the parent widget
                                  widget.onReturn({
                                    'plotId': plotID,
                                    'submissionSuccessful': submissionSuccessful,
                                  });

                                  // Optionally show a success dialog or snackbar message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Data successfully submitted',
                                        style: TextStyle(
                                          fontSize: 16.0, // Larger font size
                                        ),
                                      ),
                                    ),
                                  );
                                  // After the primary request is successful, initiate the secondary request
                                  // Create the cache clear request string using the studyID
                                  //String cacheClearRequestJson =
                                  //    QRCodeService.clearCacheRequest(studyID ?? 'defaultStudyID');
                                  //print('CACHE Request: $cacheClearRequestJson');
                                  // Fire-and-forget the clear cache request, no await used
                                  //GrassrootsRequest.sendRequest(cacheClearRequestJson, 'queen_bee_backend')
                                  //    .then((cacheResponse) {
                                  // Log the cache clear response
                                  //  print('+++Cache clear response: $cacheResponse');
                                  //}).catchError((error) {
                                  // Log any errors from the cache clear request
                                  //  print('Error sending cache clear request: $error');
                                  //});
                                }
                              } else {
                                print('NOT ALLOWED');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Submission not allowed for this study')),
                                );
                              }
                            } catch (e) {
                              // Handle any errors that occur during the request
                              print('Error sending request: $e');

                              // Optionally show an error dialog or snackbar message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.error_outline, color: Colors.red), // Error icon
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Failed to submit data',
                                          style: TextStyle(
                                            fontSize: 16.0, // Larger font size
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } finally {
                              setState(() {
                                isClearingForm = true; // Set to true right before clearing the form
                              });
                              clearForm();
                            }
                          }
                        },
                        child: Text('Submit Observation'),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Do nothing for now
                          //Navigator.of(context).pop();
                          moveToNextPlot();
                        },
                        child: Text('Move to Next Plot'),
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
                // Conditional rendering of the image with Hero for expanding
                if (_image != null)
                  GestureDetector(
                    onTap: () {
                      // When the user taps on the image, navigate to a new screen with the full-size image
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => FullSizeImageScreenFile(imageFile: _image),
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
                // Conditional rendering retrieved image (if needed)
                if (_imageBytes != null)
                  GestureDetector(
                    onTap: () {
                      // When the user taps on the image, navigate to a new screen with the full-size image
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => FullSizeImageScreenUint8List(imageBytes: _imageBytes),
                        ),
                      );
                    },
                    child: Hero(
                      tag: 'imageHero', // Unique tag for the Hero widget
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                //  Container(
                //    height: 200,
                //    width: double.infinity,
                //    child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                //  ),
                ///////////////////////////////////////////////
                ///////////////////////////////////////////
                if (_image != null)
                  ElevatedButton(
                    onPressed: _isUploading ? null : _handleUpload, // Disable button when uploading
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
