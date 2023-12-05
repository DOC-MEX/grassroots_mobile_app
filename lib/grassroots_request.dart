import 'dart:convert';
import 'package:http/http.dart' as http;

class GrassrootsRequest {
  // Updated to include a map of servers for flexibility
  static const Map<String, String> _serverUrls = {
    'public': 'https://grassroots.tools/dev/grassroots/public_backend',
    //'public': 'https://grassroots.tools/public_backend',
    'private': 'https://grassroots.tools/private_backend',
    'queen_bee_backend': 'https://grassroots.tools/queen_bee_backend'
  };

  // Assuming 'doc' and 'PASSWORDTEST' are placeholders for the real credentials
  static const String _username = 'doc';
  static const String _password = 'PASSWORDTEST';

  static Future<Map<String, dynamic>> sendRequest(String requestString, String serverKey) async {
    // Determine the URL based on the serverKey provided
    String? url = _serverUrls[serverKey];

    if (url == null) {
      throw Exception('Server key "$serverKey" does not correspond to a known server.');
    }

    // Creating a Map for headers
    Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };

    // If the server key is for the queen_bee_backend, add the Authorization header
    if (serverKey == 'queen_bee_backend') {
      String basicAuth = 'Basic ' + base64Encode(utf8.encode('$_username:$_password'));
      headers['Authorization'] = basicAuth;
    }

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: requestString,
    );

    // The rest of your method remains unchanged
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if ((data['results'] as List).isEmpty) {
        throw Exception("EmptyResults");
      }
      return data;
    } else {
      throw Exception('Failed to load data from the server with status: ${response.statusCode}');
    }
  }

  static String getRequestString(String qrCode) {
    //return '{"services": [{"so:name": "Search Field Trials","start_service": true,"parameter_set": {"level": "advanced","parameters": [{"param": "ST Id","current_value": "$qrCode"}, {"param": "Get all Plots for Study","current_value": true}, {"param": "ST Search Studies","current_value": true}]}}]}';
    return '{"services": [{"so:name": "Search Field Trials","start_service": true,"parameter_set": {"level": "advanced","parameters": [{"param": "Plot ID","current_value": "$qrCode","group": "Plots and Racks"}]}}]}';
  }
}
