import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiResponse {
  // Method to handle login and return the response body or error message
  static Future<Map<String, dynamic>> loginUser(String email, String password) async {
    var headers = {
      'User-Agent': 'Apidog/1.0.0 (https://apidog.com)',
    };
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://pragmanxt.com/case_sync/services/v1/index.php/login_advocate'),
    );

    // Add the required fields in the request body
    request.fields.addAll({
      'data': jsonEncode({
        'user_id': email,
        'password': password,
      })
    });

    request.headers.addAll(headers);

    // Send the request and wait for the response
    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      String responseBody = await response.stream.bytesToString();
      var decodedResponse = jsonDecode(responseBody);

      // Check the success field
      if (decodedResponse['success'] == true) {
        return {'success': true, 'data': decodedResponse['data'], 'message': decodedResponse['message']};
      } else {
        return {'success': false, 'message': decodedResponse['message'] ?? 'Login failed'};
      }
    } else {
      return {'success': false, 'message': 'Server error: ${response.reasonPhrase}'};
    }
  }
}
