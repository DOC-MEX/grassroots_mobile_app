import 'dart:io';
import 'package:http/http.dart' as http;

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
}
