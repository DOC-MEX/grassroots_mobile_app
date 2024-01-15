//name: NewObservationPage  (new_observation.dart)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:typed_data';
import 'full_size_image_screen.dart';
import 'dart:convert';
import 'grassroots_request.dart';

class NewObservationPage extends StatefulWidget {
  final Map<String, dynamic> studyDetails;
  final String plotId;
  final Map<String, dynamic> plotDetails;

  NewObservationPage({
    required this.studyDetails,
    required this.plotId,
    required this.plotDetails,
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

  @override
  void initState() {
    super.initState();
    _extractPhenotypeDetails();
    // Attempt to retrieve the photo when the page loads
    _retrievePhoto();
    // Attempt to retrieve the limits when the page loads
    retrieveLimits();
  }

  @override
  void dispose() {
    // Dispose of your controllers here
    _maxHeightController.dispose();
    _minHeightController.dispose();
    // Call the dispose method of the superclass at the end
    super.dispose();
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

// Function to upload the image to the server
  Future<void> _uploadImage() async {
    try {
      var uri = Uri.parse('https://grassroots.tools/photo_receiver/upload/');
      var request = http.MultipartRequest('POST', uri);

      // Generate the new filename using plotNumber
      String newFileName = 'photo_plot_${plotNumber.toString()}.jpg'; // Assuming the image is a JPEG file

      // Attach the image file with the new filename
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        _image!.path,
        filename: newFileName,
      ));

      // Add the subfolder field
      request.fields['subfolder'] = studyID ?? 'defaultFolder';

      // Send the request
      var response = await request.send();
      // Read response
      //final responseBody = await response.stream.bytesToString();
      ///print('Response: $responseBody');

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload successful')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      //print error
      print('Error: $e');
    }
  }

  // Function to retrieve the photo from the server
  Future<void> _retrievePhoto() async {
    try {
      // Define the subfolder name and photo name based on studyID and plotNumber
      String subfolder = studyID ?? 'defaultFolder';
      String photoName = 'photo_plot_${plotNumber.toString()}.jpg';

      // Create the API URL for retrieving the photo
      var apiUrl = Uri.parse('https://grassroots.tools/photo_receiver/retrieve_photo/$subfolder/$photoName');

      // Send a GET request to retrieve the photo
      var response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        // Directly display the image from the response
        setState(() {
          _imageBytes = response.bodyBytes; // Store the image bytes
        });
      } else {
        // Photo not found, show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('plot has no photo')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      print('Error: $e');
    }
  }

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
    //print('Plot ID: ${widget.plotId}');
    print('Traits: $traits');
    print('Units: $units');
    print('Scales: $scales');
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
  }

  //////////////////////////////////////////////////////
  Future<void> retrieveLimits() async {
    try {
      String subfolder = studyID ?? 'defaultFolder'; // Use the appropriate variable to determine the subfolder

      // Create the API URL for retrieving the limits file
      var apiUrl = Uri.parse('https://grassroots.tools/photo_receiver/retrieve_limits/$subfolder');

      // Send a GET request to retrieve the file
      var response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        // Parse the JSON response
        var jsonResponse = jsonDecode(response.body);
        setState(() {
          minHeight = jsonResponse['Plant height']['min'];
          maxHeight = jsonResponse['Plant height']['max'];
        });

        // Print the values to the console
        print('Min Height: $minHeight, Max Height: $maxHeight');
      } else {
        // Handle the case where the file is not found or any other errors
        print('Failed to retrieve limits.json: ${response.statusCode}');
      }
    } catch (e) {
      print('Error retrieving limits.json: $e');
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
                      child: TextField(
                        controller: _maxHeightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Enter new max value',
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Text('Min: '),
                    Expanded(
                      child: TextField(
                        controller: _minHeightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Enter new min value',
                        ),
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
                  // Send POST request to update values
                  bool updated = await updateLimits(newMin, newMax);
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

  Future<bool> updateLimits(int newMin, int newMax) async {
    String subfolder = studyID ?? 'defaultFolder'; // Adjust as needed
    var url = Uri.parse('https://grassroots.tools/photo_receiver/update_limits/$subfolder/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Plant height': {'min': newMin, 'max': newMax}
        }),
      );

      //print('-----Response status: ${response.statusCode}');
      //print('******8Response body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating limits: $e');
      return false;
    }
  }

  ////////// request for submitting observation //////////
  String createGrassrootsRequest({
    required String detectedQRCode,
    required String? selectedTrait,
    required String measurement,
    required String dateString,
    String? note,
  }) {
    final requestMap = {
      "services": [
        {
          "so:name": "Edit Field Trial Rack",
          "start_service": true,
          "parameter_set": {
            "level": "simple",
            "parameters": [
              {"param": "RO Id", "current_value": detectedQRCode, "group": "Plot"},
              {"param": "RO Append Observations", "current_value": true, "group": "Plot"},
              {
                "param": "RO Measured Variable Name",
                "current_value": [selectedTrait],
                "group": "Phenotypes"
              },
              {
                "param": "RO Phenotype Raw Value",
                "current_value": [measurement],
                "group": "Phenotypes"
              },
              {
                "param": "RO Phenotype Corrected Value",
                "current_value": [null],
                "group": "Phenotypes"
              },
              {
                "param": "RO Phenotype Start Date",
                "current_value": [dateString],
                "group": "Phenotypes"
              },
              {
                "param": "RO Phenotype End Date",
                "current_value": [null],
                "group": "Phenotypes"
              },
              {
                "param": "RO Observation Notes",
                "current_value": note != null ? [note] : [null],
                "group": "Phenotypes"
              },
            ]
          }
        }
      ]
    };

    // Convert map to a JSON string
    return jsonEncode(requestMap);
  }

////////// request for clearing cache //////////
  String clearCacheRequest(String studyID) {
    final Map<String, dynamic> request = {
      "services": [
        {
          "start_service": true,
          "so:alternateName": "field_trial-manage_study",
          "parameter_set": {
            "level": "simple",
            "parameters": [
              {"param": "ST Id", "current_value": studyID},
              {"param": "SM uuid", "current_value": studyID},
              {"param": "SM clear cached study", "current_value": true},
              {"param": "SM indexer", "current_value": "<NONE>"},
              {"param": "SM Delete study", "current_value": false},
              {"param": "SM Remove Study Plots", "current_value": false},
              {"param": "SM Generate FD Packages", "current_value": false},
              {"param": "SM Generate Handbook", "current_value": false},
              {"param": "SM Generate Phenotypes", "current_value": false},
            ]
          }
        }
      ]
    };

    return json.encode(request);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Observation'),
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

                DropdownButtonFormField<String>(
                  value: selectedTraitKey,
                  hint: Text("Select a trait"),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedTraitKey = newValue;
                      // Retrieve scale and unit for the selected trait
                      //String? selectedScale = scales[selectedTraitKey];
                      String? selectedUnit = units[selectedTraitKey];

                      // Determine the appropriate input type
                      if (selectedUnit == 'day') {
                        // _inputType = TextInputType.datetime;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            duration: Duration(seconds: 3),
                            content: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.yellow),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "Enter number of days or select a date",
                                    style: TextStyle(fontSize: 16.0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } // else {
                      //  _inputType = TextInputType.number;
                      // }
                    });

                    // Retrieve and print scale and unit for the selected trait
                    String? selectedScale = scales[selectedTraitKey];
                    String? selectedUnit = units[selectedTraitKey];
                    print('Selected Trait: $selectedTraitKey');
                    print('Scale: $selectedScale');
                    print('Unit: $selectedUnit');
                  },
                  items: traits.keys.map<DropdownMenuItem<String>>((String key) {
                    return DropdownMenuItem<String>(
                      value: key,
                      child: Text(traits[key] ?? 'Unknown'),
                    );
                  }).toList(),
                  validator: (value) => value == null ? 'Please select a trait' : null,
                ),
                SizedBox(height: 20),
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
                          if (units[selectedTraitKey] == 'yyyymmdd') {
                            try {
                              DateFormat('yyyy-MM-dd').parse(value); // Check if value is in 'yyyy-MM-dd' format
                            } catch (e) {
                              return 'Please enter a date in the format YYYY-MM-DD';
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
                ElevatedButton(
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
                        String jsonString = createGrassrootsRequest(
                          detectedQRCode: plotID,
                          selectedTrait: trait,
                          measurement: measurement,
                          dateString: dateString,
                          note: note,
                        );

                        print('---JSON Request: $jsonString');
                        // Send the request to the server and await the response
                        var response = await GrassrootsRequest.sendRequest(jsonString, 'private');

                        // Handle the response data
                        print('Response from server: $response');

                        // Optionally show a success dialog or snackbar message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Data successfully submitted')),
                        );

                        // Optionally reset other state variables if needed
                        setState(() {
                          selectedTraitKey = null;
                          selectedDate = null;
                          //clear note
                          _notesEditingController.clear();
                        });
                        // After the primary request is successful, initiate the secondary request
                        // Create the cache clear request string using the studyID
                        String cacheClearRequestJson = clearCacheRequest(studyID ?? 'defaultStudyID');
                        //print('CACHE Request: $cacheClearRequestJson');
                        // Fire-and-forget the clear cache request, no await used
                        GrassrootsRequest.sendRequest(cacheClearRequestJson, 'queen_bee_backend').then((cacheResponse) {
                          // Log the cache clear response
                          print('+++Cache clear response: $cacheResponse');
                        }).catchError((error) {
                          // Log any errors from the cache clear request
                          print('Error sending cache clear request: $error');
                        });
                      } catch (e) {
                        // Handle any errors that occur during the request
                        print('Error sending request: $e');

                        // Optionally show an error dialog or snackbar message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to submit data')),
                        );
                      } finally {
                        // Clear the form fields after processing the request
                        _formKey.currentState!.reset();
                        _textEditingController.clear();
                        _notesEditingController.clear();
                      }
                    }
                  },
                  child: Text('Submit Observation'),
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
                    onPressed: _uploadImage,
                    child: Text('Upload Image'),
                  ),
              ],
            ),
          ), //Form
        ),
      ),
    );
  }
}
