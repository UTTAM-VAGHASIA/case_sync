import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'lib/services/api_service.dart';

class NewCaseScreen extends StatefulWidget {
  const NewCaseScreen({super.key});

  @override
  NewCaseScreenState createState() => NewCaseScreenState();
}

class NewCaseScreenState extends State<NewCaseScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _caseNumberController = TextEditingController();
  final TextEditingController _caseYearController = TextEditingController();
  final TextEditingController _applicantController = TextEditingController();
  final TextEditingController _opponentController = TextEditingController();
  final TextEditingController _summonDateController = TextEditingController();

  String? _selectedCaseType;
  String? _selectedHandler;
  String? _selectedCompany;
  String? _selectedCourtName;
  String? _selectedCityName;
  String? _fileName;
  String? _filePath;

  bool _isSubmitting = false;

  // Dropdown lists from API
  List<Map<String, String>> _caseTypes = [];
  List<String> _caseStages = [];
  List<String> _handlers = [];
  List<String> _companies = [];
  List<String> _courtNames = [];
  List<String> _cityNames = [];

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    try {
      // Fetch case types
      var caseTypesResponse = await ApiService.fetchCaseTypes();

      setState(() {
        _caseTypes = caseTypesResponse;
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch case types: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Set the initial date
      firstDate: DateTime(2000), // Set the earliest selectable date
      lastDate: DateTime(2101), // Set the latest selectable date
    );
    if (pickedDate != null) {
      setState(() {
        _summonDateController.text =
            DateFormat('dd/MM/yyyy').format(pickedDate);
      });
    }
  }

  Future<void> _pickDocument() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      setState(() {
        _fileName = result.files.single.name; // Displayed file name
        _filePath = result.files.single.path; // Actual file path for upload
      });
    } else {
      setState(() {
        _fileName = null;
        _filePath = null;
      });
    }
  }

  Future<void> _submitCase() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    Map<String, dynamic> caseData = {
      'case_no': _caseNumberController.text,
      'year': _caseYearController.text,
      'case_type': _selectedCaseType,
      'handled_by': _selectedHandler,
      'applicant': _applicantController.text,
      'company_id': _selectedCompany,
      'opp_name': _opponentController.text,
      'court_name': _selectedCourtName,
      'city_id': _selectedCityName,
      'sr_date': _summonDateController.text,
    };

    var response =
        await ApiService.submitNewCase(caseData, _filePath as List<String>);

    setState(() {
      _isSubmitting = false;
    });

    if (response['success']) {
      Get.snackbar('Success', 'Case submitted successfully!',
          snackPosition: SnackPosition.BOTTOM);
      Get.back(); // Navigate back after submission
    } else {
      Get.snackbar('Error', 'Failed to submit case: ${response['message']}',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
        elevation: 0,
        leadingWidth: 56 + 30,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/back_arrow.svg',
            width: 35,
            height: 35,
          ),
          onPressed: () {
            Get.back();
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Text(
                    'New Case',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: screenHeight * 0.06),
                _buildTextField(
                    'Case Number', 'Case Number', _caseNumberController,
                    validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the Case Number';
                  }
                  return null;
                }),
                _buildTextField('Case Year', 'Case Year', _caseYearController,
                    validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the Case Year';
                  }
                  return null;
                }),
                _buildDropdownField(
                    'Case Type',
                    'Select Case Type',
                    _caseTypes.map((item) => item['case_type']!).toList(),
                    _selectedCaseType, (value) {
                  setState(() {
                    _selectedCaseType = value;
                  });
                }),
                _buildTextField('Applicant / Appellant / Complainant',
                    'Enter Name', _applicantController, validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the name';
                  }
                  return null;
                }),
                _buildTextField('Opponent / Respondent / Accused', 'Enter Name',
                    _opponentController, validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the name';
                  }
                  return null;
                }),
                SizedBox(height: screenHeight * 0.05),
                Center(
                  child: SizedBox(
                    width: screenWidth * 0.5,
                    height: 70,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitCase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isSubmitting
                          ? CircularProgressIndicator()
                          : Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, String hint, TextEditingController controller,
      {String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField(String label, String hint, List<String> items,
      String? selectedValue, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(),
        ),
        value: selectedValue,
        onChanged: onChanged,
        items: items
            .map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                ))
            .toList(),
      ),
    );
  }
}

class ApiService {
  static const String baseUrl = 'https://your-api-url.com/';
  static const Map<String, String> headers = {
    'Content-Type': 'application/json'
  };

  // Fetch case types
  static Future<List<Map<String, String>>> fetchCaseTypes() async {
    try {
      // Correct endpoint for fetching case types
      final response = await http.post(
        Uri.parse('${baseUrl}get_case_type_list'),
        headers: headers,
      );

      // Check response status
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Check if the response is successful
        if (responseData['success'] == true) {
          // Parse the data as a list of maps (id and case_type)
          final List<dynamic> data = responseData['data'];
          return data.map((item) {
            return {
              'id': item['id'].toString(),
              'case_type': item['case_type'].toString(),
            };
          }).toList();
        } else {
          throw Exception(
              'Failed to fetch case types: ${responseData['message']}');
        }
      } else {
        throw Exception('Server error: ${response.reasonPhrase}');
      }
    } catch (error) {
      throw Exception('Error occurred: $error');
    }
  }
}
