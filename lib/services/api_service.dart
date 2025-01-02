import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/case_list.dart';

class ApiService {
  static const String baseUrl =
      'https://pragmanxt.com/case_sync/services/admin/v1/index.php/';
  static const Map<String, String> headers = {
    'User-Agent': 'Apidog/1.0.0 (https://apidog.com)',
  };

  // General method to send requests
  static Future<Map<String, dynamic>> _sendRequest(
      String endpoint, Map<String, dynamic> bodyData) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(baseUrl + endpoint),
      );
      request.fields.addAll({'data': jsonEncode(bodyData)});
      request.headers.addAll(headers);

      // Send the request and handle timeout
      http.StreamedResponse response =
          await request.send().timeout(const Duration(seconds: 10));

      // Handle response status
      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        var decodedResponse = jsonDecode(responseBody);

        if (decodedResponse['success'] == true) {
          return {
            'success': true,
            'data': decodedResponse['data'],
            'message': decodedResponse['message'],
          };
        } else {
          return {
            'success': false,
            'message': decodedResponse['message'] ?? 'Operation failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.reasonPhrase}',
        };
      }
    } catch (error) {
      return {'success': false, 'message': 'Error occurred: $error'};
    }
  }

  // Submit new case method
  static Future<Map<String, dynamic>> submitNewCase(
      Map<String, dynamic> caseData, List<String> filePaths) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${baseUrl}add_case'),
    );

    // Add case data as JSON in the 'data' field
    request.fields['data'] = jsonEncode(caseData);

    // Add multiple files to the request if any files are provided
    if (filePaths.isNotEmpty) {
      for (String filePath in filePaths) {
        request.files
            .add(await http.MultipartFile.fromPath('case_images[]', filePath));
      }
    }

    request.headers.addAll(headers);

    try {
      http.StreamedResponse response =
          await request.send().timeout(Duration(seconds: 10), onTimeout: () {
        throw Exception('Request timed out');
      });

      // Handle response
      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        var decodedResponse = jsonDecode(responseBody);

        if (decodedResponse['success'] == true) {
          return {
            'success': true,
            'message': decodedResponse['message'],
          };
        } else {
          return {
            'success': false,
            'message': decodedResponse['message'] ?? 'Operation failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.reasonPhrase}',
        };
      }
    } catch (error) {
      return {'success': false, 'message': 'Error occurred: $error'};
    }
  }

  // Login user method
  static Future<Map<String, dynamic>> loginUser(
      String email, String password) async {
    return _sendRequest(
      'login_advocate',
      {
        'user_id': email,
        'password': password,
      },
    );
  }

  // Register advocate method
  static Future<Map<String, dynamic>> registerAdvocate(
      String name, String contact, String email, String password) async {
    return _sendRequest(
      'advocate_registration',
      {
        'name': name,
        'contact': contact,
        'email': email,
        'password': password,
      },
    );
  }

  // Fetch case types
  static Future<List<String>> fetchCaseTypes() async {
    final response = await _sendRequest('get_case_types', {});
    if (response['success']) {
      return List<String>.from(response['data']);
    } else {
      throw Exception('Failed to fetch case types: ${response['message']}');
    }
  }

  // Fetch case stages
  static Future<List<String>> fetchCaseStages() async {
    final response = await _sendRequest('get_case_stages', {});
    if (response['success']) {
      return List<String>.from(response['data']);
    } else {
      throw Exception('Failed to fetch case stages: ${response['message']}');
    }
  }

  // Fetch handlers
  static Future<List<String>> fetchHandlers() async {
    final response = await _sendRequest('get_handlers', {});
    if (response['success']) {
      return List<String>.from(response['data']);
    } else {
      throw Exception('Failed to fetch handlers: ${response['message']}');
    }
  }

  // Fetch companies
  static Future<List<String>> fetchCompanies() async {
    final response = await _sendRequest('get_companies', {});
    if (response['success']) {
      return List<String>.from(response['data']);
    } else {
      throw Exception('Failed to fetch companies: ${response['message']}');
    }
  }

  // Fetch court names
  static Future<List<String>> fetchCourtNames() async {
    final response = await _sendRequest('get_court_names', {});
    if (response['success']) {
      return List<String>.from(response['data']);
    } else {
      throw Exception('Failed to fetch court names: ${response['message']}');
    }
  }

  // Fetch city names
  static Future<List<String>> fetchCityNames() async {
    final response = await _sendRequest('get_city_names', {});
    if (response['success']) {
      return List<String>.from(response['data']);
    } else {
      throw Exception('Failed to fetch city names: ${response['message']}');
    }
  }
}

class CaseApiService {
  static const String baseUrl =
      'https://pragmanxt.com/case_sync/services/admin/v1/index.php';

  static Future<List<CaseListData>> fetchCaseList() async {
    final response = await http.get(Uri.parse('$baseUrl/get_case_history'));

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['success']) {
        final List<dynamic> data = responseData['data'];
        return data.map((item) => CaseListData.fromJson(item)).toList();
      } else {
        throw Exception(
            'Failed to fetch case list: ${responseData['message']}');
      }
    } else {
      throw Exception(
          'Failed to fetch case list. Status code: ${response.statusCode}');
    }
  }
}
