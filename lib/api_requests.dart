import 'dart:io';
import 'package:http/http.dart' as http;
//import 'package:flutter/material.dart';
//import 'dart:typed_data';
import 'dart:convert'; // For jsonDecode()
import 'package:intl/intl.dart';

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

  static Future<bool> uploadImageDate(File image, String studyID, int plotNumber) async {
    try {
      var uri = Uri.parse('https://grassroots.tools/photo_receiver/upload/');

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

      var apiUrl = Uri.parse('https://grassroots.tools/photo_receiver/retrieve_photo/$subfolder/$photoName');
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

  static Future<Map<String, dynamic>> retrieveLastestPhoto(String studyID, int plotNumber) async {
    try {
      // Updated API URL to match the new endpoint
      var apiUrl = Uri.parse('https://grassroots.tools/photo_receiver/retrieve_latest_photo/$studyID/$plotNumber');
      var response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        return {'status': 'success', 'data': response.bodyBytes};
      } else {
        // Handle not found or other errors
        return {'status': 'not_found'};
      }
    } catch (e) {
      print('Error: $e');
      return {'status': 'error', 'message': 'Error: $e'};
    }
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
