import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert'; // For jsonDecode()

class ApiRequests {
  static Future<bool> uploadImage(File image, String studyID, int plotNumber) async {
    try {
      var uri = Uri.parse('https://grassroots.tools/photo_receiver/upload/');
      var request = http.MultipartRequest('POST', uri);

      String newFileName = 'photo_plot_${plotNumber.toString()}.jpg';
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        image.path,
        filename: newFileName,
      ));

      request.fields['subfolder'] = studyID;

      var response = await request.send();

      return response.statusCode == 201; // Return true if status code is 201
    } catch (e) {
      return false; // Return false in case of an error
    }
  }

  static Future<Uint8List?> retrievePhoto(String studyID, int plotNumber, BuildContext context) async {
    try {
      // Define the subfolder name and photo name based on studyID and plotNumber
      String subfolder = studyID;
      String photoName = 'photo_plot_${plotNumber.toString()}.jpg';

      // Create the API URL for retrieving the photo
      var apiUrl = Uri.parse('https://grassroots.tools/photo_receiver/retrieve_photo/$subfolder/$photoName');

      // Send a GET request to retrieve the photo
      var response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        // Return the image bytes
        return response.bodyBytes;
      } else {
        // Photo not found, show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Plot has no photo')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      print('Error: $e');
    }
    return null;
  }

  static Future<Map<String, int>?> retrieveLimits(String studyID) async {
    try {
      String subfolder = studyID;
      var apiUrl = Uri.parse('https://grassroots.tools/photo_receiver/retrieve_limits/$subfolder');
      var response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        // print max  and min to console
        print('-----Min: ${jsonResponse['Plant height']['min']}');
        print('-----Max: ${jsonResponse['Plant height']['max']}');
        return {
          'minHeight': jsonResponse['Plant height']['min'],
          'maxHeight': jsonResponse['Plant height']['max'],
        };
      } else {
        print('Failed to retrieve limits.json: ${response.statusCode}');
      }
    } catch (e) {
      print('Error retrieving limits.json: $e');
    }
    return null;
  }

  static Future<bool> updateLimits(String studyID, int newMin, int newMax) async {
    String subfolder = studyID;
    var url = Uri.parse('https://grassroots.tools/photo_receiver/update_limits/$subfolder/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Plant height': {'min': newMin, 'max': newMax}
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating limits: $e');
      return false;
    }
  }
}
