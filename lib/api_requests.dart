import 'dart:io';
import 'package:http/http.dart' as http;
//import 'package:flutter/material.dart';
//import 'dart:typed_data';
import 'dart:convert'; // For jsonDecode()
import 'package:intl/intl.dart';

class ApiRequests {
  static Future<bool> uploadImage(File image, String studyID, int plotNumber) async {
    try {
      var uri = Uri.parse('https://grassroots.tools/beta/photo_receiver/upload/');
      var request = http.MultipartRequest('POST', uri);

      String newFileName = 'photo_plot_${plotNumber.toString()}.jpg';
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        image.path,
        filename: newFileName,
      ));

      request.fields['subfolder'] = studyID;
      request.fields['plot_number'] = plotNumber.toString(); // Add plot_number to the request

      var response = await request.send();

      return response.statusCode == 201; // Return true if status code is 201
    } catch (e) {
      return false; // Return false in case of an error
    }
  }

  static Future<bool> uploadImageDate(File image, String studyID, int plotNumber) async {
    try {
      var uri = Uri.parse('https://grassroots.tools/beta/photo_receiver/upload/');

      // Include the current date in the file name
      String date = DateFormat('yyyy_MM_dd').format(DateTime.now());
      String newFileName = 'photo_plot_${plotNumber.toString()}_${date}.jpg';

      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        image.path,
        filename: newFileName,
      ));

      request.fields['subfolder'] = studyID;
      request.fields['plot_number'] = plotNumber.toString(); // Add plot_number to the request
      var response = await request.send();

      return response.statusCode == 201; // Return true if status code is 201
    } catch (e) {
      return false; // Return false in case of an error
    }
  }

  static Future<Map<String, dynamic>> retrievePhoto(String studyID, int plotNumber) async {
    try {
      String subfolder = studyID;
      String photoName = 'photo_plot_${plotNumber.toString()}.jpg';

      var apiUrl = Uri.parse('https://grassroots.tools/beta/photo_receiver/retrieve_photo/$subfolder/$photoName');
      var response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        return {'status': 'success', 'data': response.bodyBytes};
      } else {
        return {'status': 'not_found'};
      }
    } catch (e) {
      print('Error: $e');
      return {'status': 'error', 'message': 'Error: $e'};
    }
  }

  //static Future<Map<String, dynamic>> retrieveLastestPhoto(String studyID, int plotNumber) async {
//    try {
//      // Updated API URL to match the new endpoint
//      var apiUrl =
//          Uri.parse('https://grassroots.tools/beta/photo_receiver/retrieve_latest_photo/$studyID/$plotNumber/');
//      var response = await http.get(apiUrl);

//      if (response.statusCode == 200) {
//        return {'status': 'success', 'data': response.bodyBytes};
//      } else {
//        // Handle not found or other errors
//        return {'status': 'not_found'};
//      }
//    } catch (e) {
//      print('Error: $e');
//      return {'status': 'error', 'message': 'Error: $e'};
//    }
//  }

  static Future<Map<String, dynamic>> retrieveLastestPhoto(String studyID, int plotNumber) async {
    try {
      // Updated API URL to match the new endpoint
      //print path used for the API
      print('https://grassroots.tools/beta/photo_receiver/retrieve_latest_photo/$studyID/$plotNumber/');

      var apiUrl =
          Uri.parse('https://grassroots.tools/beta/photo_receiver/retrieve_latest_photo/$studyID/$plotNumber/');
      var response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        // Parse the JSON response
        var jsonResponse = json.decode(response.body);

        // Check if the status is success and extract URL
        if (jsonResponse['status'] == 'success') {
          return {
            'status': 'success',
            'url': jsonResponse['url'], // Extract and return the URL instead of bytes
          };
        } else {
          return {'status': 'not_found'};
        }
      } else {
        // Handle not found or other errors
        return {'status': 'not_found'};
      }
    } catch (e) {
      print('Error: $e');
      return {'status': 'error', 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, Map<String, int?>>?> retrieveLimits(String studyID) async {
    try {
      String subfolder = studyID;
      var apiUrl = Uri.parse('https://grassroots.tools/beta/photo_receiver/retrieve_limits/$subfolder/');
      var response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        print('JSON Response: $jsonResponse');

        // Initialize a result map
        Map<String, Map<String, int?>> limits = {};

        // Iterate over the keys in the JSON response and store limits dynamically
        jsonResponse.forEach((traitKey, traitLimits) {
          if (traitLimits['min'] != null && traitLimits['max'] != null) {
            limits[traitKey] = {
              'min': traitLimits['min'],
              'max': traitLimits['max'],
            };
            print('-----Trait: $traitKey, Min: ${traitLimits['min']}, Max: ${traitLimits['max']}');
          }
        });

        return limits;
      } else {
        print('Failed to retrieve limits.json: ${response.statusCode}');
      }
    } catch (e) {
      print('Error retrieving limits.json: $e');
    }

    return null; // Return null or an empty map if no limits are found or there's an error
  }

  static Future<bool> updateLimits(String studyID, int newMin, int newMax, String traitKey) async {
    String subfolder = studyID;
    var url = Uri.parse('https://grassroots.tools/beta/photo_receiver/update_limits/$subfolder/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          traitKey: {'min': newMin, 'max': newMax}
        }),
      );

      // Log the status code and response body for debugging
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating limits: $e');
      return false;
    }
  }
}
