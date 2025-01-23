import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../models/advocate.dart';
import '../../services/shared_pref.dart';

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
  String? _selectedCaseStage;
  List<String> _fileNames = [];
  List<String> _filePaths = [];

  List<Map<String, String>> _caseTypeList = [];
  List<Map<String, String>> _caseStageList = [];
  List<Map<String, String>> _companyList = [];
  List<Map<String, String>> _cityList = [];
  List<Map<String, String>> _courtList = [];
  List<Map<String, String>> _advocateList = [];

  bool _isSubmitting = false;
  bool _isLoading = true;

  final String baseUrl =
      "https://pragmanxt.com/case_sync/services/admin/v1/index.php";

  @override
  void dispose() {
    _caseNumberController.dispose();
    _caseYearController.dispose();
    _applicantController.dispose();
    _opponentController.dispose();
    _summonDateController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    try {
      await Future.wait([
        _getCaseTypeList(),
        _getCompanyList(),
        _getCityList(),
        _getCourtList(),
        _getAdvocateList(),
      ]);
    } catch (e) {
      print("Error fetching dropdown data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCaseTypeList() async {
    final response = await http.get(Uri.parse("$baseUrl/get_case_type_list"));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          _caseTypeList = List<Map<String, String>>.from(
            data['data'].map((item) => {
                  "id": item['id']?.toString() ?? '',
                  "name": item['case_type']?.toString() ?? '',
                }),
          );
        });
      }
    }
  }

  Future<void> _getCaseStageList(String caseTypeId) async {
    print("case type id: $caseTypeId");
    final response = await http.post(
      Uri.parse("$baseUrl/get_stage_list"),
      body: {'case_stage': caseTypeId},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("Stage Response Data: ${data['data']}");
      if (data['success'] && data['data'] != null) {
        setState(() {
          _caseStageList = List<Map<String, String>>.from(
            data['data'].map((item) => {
                  "id": item['id']?.toString() ?? '',
                  "name": item['stage']?.toString() ?? '',
                }),
          );
        });
      } else {
        setState(() {
          print("Api Call Unsuccessful");
          _caseStageList = []; // No stages available
        });
      }
    }
  }

  Future<void> _getAdvocateList() async {
    final response = await http.get(Uri.parse("$baseUrl/get_advocate_list"));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          _advocateList = List<Map<String, String>>.from(
            data['data'].map((item) => {
                  "id": item['id']?.toString() ?? '',
                  "name": item['name']?.toString() ?? '',
                }),
          );
        });
      }
    }
  }

  Future<void> _getCompanyList() async {
    final response = await http.get(Uri.parse("$baseUrl/get_company_list"));
    if (response.statusCode == 200) {
      print('Company');
      final data = json.decode(response.body);
      print("Company Response Data: ${data['data']}");
      if (data['success']) {
        setState(() {
          _companyList = List<Map<String, String>>.from(
            data['data'].map((item) => {
                  "id": item['id']?.toString() ?? '',
                  "name": item['name']?.toString() ?? '',
                  "contact_person": item['contact_person']?.toString() ?? '',
                  "contact_no": item['contact_no']?.toString() ?? '',
                  "status": item['status']?.toString() ?? '',
                  "date_time": item['date_time']?.toString() ?? '',
                }),
          );
        });
      }
    }
  }

  Future<void> _getCityList() async {
    final response = await http.get(Uri.parse("$baseUrl/get_city_list"));
    if (response.statusCode == 200) {
      print('City');
      final data = json.decode(response.body);
      print("City Response Data: ${data['data']}");
      if (data['success']) {
        setState(() {
          _cityList = List<Map<String, String>>.from(
            data['data'].map((item) => {
                  "id": item['id']?.toString() ?? '',
                  "name": item['name']?.toString() ?? '',
                }),
          );
        });
      }
    }
  }

  Future<void> _getCourtList() async {
    final response = await http.get(Uri.parse("$baseUrl/get_court_list"));
    if (response.statusCode == 200) {
      print('Court');
      final data = json.decode(response.body);
      print("Court Response Data: ${data['data']}");
      if (data['success']) {
        setState(() {
          _courtList = List<Map<String, String>>.from(
            data['data'].map((item) => {
                  "id": item['id']?.toString() ?? '',
                  "name": item['name']?.toString() ?? '',
                }),
          );
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        _summonDateController.text =
            DateFormat('dd/MM/yyyy').format(pickedDate);
      });
    }
  }

  Future<void> _pickDocuments() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _fileNames = result.files.map((file) => file.name).toList();
        _filePaths = result.files.map((file) => file.path!).toList();
      });
    } else {
      setState(() {
        _fileNames = [];
        _filePaths = [];
      });
    }
  }

  Future<void> _submitCase() async {
    if (!_formKey.currentState!.validate()) return;

    // Ensure files are selected
    if (_filePaths.isEmpty) {
      Get.snackbar('Error', 'Please select at least one document!',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Retrieve user details from SharedPreferences
      Advocate? user = await SharedPrefService.getUser();
      if (user == null) {
        throw Exception('User not found. Please log in again.');
      }

      // Split files: first file as case_image, rest as case_docs[]
      String caseImage = _filePaths.first;
      List<String> caseDocs =
          _filePaths.length > 1 ? _filePaths.sublist(1) : [];

      // Prepare data for API
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/add_case"),
      );

      // Add fields to the request
      request.fields["data"] = json.encode({
        "case_no": _caseNumberController.text,
        "year": _caseYearController.text,
        "case_type": _caseTypeList.firstWhere(
          (element) => element['id'] == _selectedCaseType,
          orElse: () =>
              {'id': ''}, // Default to an empty string or handle appropriately
        )['id'],
        "handle_by": _advocateList.firstWhere(
          (element) => element['id'] == _selectedHandler,
          orElse: () =>
              {'id': ''}, // Default to an empty string or handle appropriately
        )['id'],
        "applicant": _applicantController.text,
        "stage": _caseStageList.firstWhere(
          (element) => element['id'] == _selectedCaseStage,
          orElse: () =>
              {'id': ''}, // Default to an empty string or handle appropriately
        )['id'],
        "added_by": user.id, // Dynamically pass the user ID
        "user_type": "advocate", // Hardcoded as per your requirement
        "company_id": _companyList.firstWhere(
          (element) => element['id'] == _selectedCompany,
          orElse: () =>
              {'id': ''}, // Default to an empty string or handle appropriately
        )['id'],
        "opp_name": _opponentController.text,
        "court_name": _selectedCourtName!,
        "city_id": _cityList.firstWhere(
          (element) => element['id'] == _selectedCityName,
          orElse: () =>
              {'id': ''}, // Default to an empty string or handle appropriately
        )['id'],
        "sr_date": _summonDateController.text,
      });

      // Add case_image file
      request.files
          .add(await http.MultipartFile.fromPath('case_image', caseImage));

      // Add case_docs[] files
      for (String docPath in caseDocs) {
        request.files
            .add(await http.MultipartFile.fromPath('case_docs[]', docPath));
      }

      print("##########################################");
      print(request.fields);
      print("##########################################");
      // Send the request
      var response = await request.send();
      print("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%");
      print('${response.statusCode}');

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var data = json.decode(responseData);

        if (data['success']) {
          Get.snackbar('Success', 'Case submitted successfully!',
              snackPosition: SnackPosition.BOTTOM);
          Get.back();
        } else {
          Get.snackbar('Error', 'Failed to submit case: ${data['message']}',
              snackPosition: SnackPosition.BOTTOM);
          print('Error, failed to submit case: ${data['message']}');
        }
      } else {
        Get.snackbar('Error: ${response.statusCode}',
            'Failed to submit case. Try again later!',
            snackPosition: SnackPosition.BOTTOM);
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred: $e',
          snackPosition: SnackPosition.BOTTOM);
      print('Error: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.black,
          ),
        ),
      );
    } else {
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
                    _caseTypeList,
                    _selectedCaseType,
                    (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCaseType = value;
                          _selectedCaseStage = null;
                          _caseStageList = [];
                          _getCaseStageList(value);
                        });
                      }
                    },
                  ),
                  _buildDropdownField('Case Stage', 'Select Case Stage',
                      _caseStageList, _selectedCaseStage, (value) {
                    setState(() {
                      _selectedCaseStage = value;
                    });
                  }),
                  _buildDropdownField(
                    'Handled By',
                    'Select Advocate',
                    _advocateList,
                    _selectedHandler,
                    (value) {
                      setState(() {
                        _selectedHandler = value;
                      });
                    },
                  ),
                  _buildDropdownField('Company Name', 'Select Company',
                      _companyList, _selectedCompany, (value) {
                    setState(() {
                      _selectedCompany = value;
                    });
                  }),
                  _buildTextField('Applicant / Appellant / Complainant',
                      'Enter Name', _applicantController, validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the name';
                    }
                    return null;
                  }),
                  _buildTextField('Opponent / Respondent / Accused',
                      'Enter Name', _opponentController, validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the name';
                    }
                    return null;
                  }),
                  _buildDropdownField('Court Name', 'Select Court Name',
                      _courtList, _selectedCourtName, (value) {
                    setState(() {
                      _selectedCourtName = value;
                    });
                  }),
                  _buildDropdownField(
                      'City Name', 'Select City', _cityList, _selectedCityName,
                      (value) {
                    setState(() {
                      _selectedCityName = value;
                    });
                  }),
                  _buildDateField(
                      'Summon Date',
                      'Select Summon Date',
                      _summonDateController,
                      () => _selectDate(context), validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select Summon Date';
                    }
                    return null;
                  }),
                  _buildFilePickerField(
                      'Attach Documents', 'Attach Documents', _pickDocuments),
                  const SizedBox(height: 10),
                  if (_fileNames.isNotEmpty)
                    ..._fileNames
                        .map((fileName) => Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Text(fileName),
                            ))
                        .toList(),
                  SizedBox(height: screenHeight * 0.05),
                  Center(
                    child: SizedBox(
                      width: screenWidth * 0.5,
                      height: 70,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitCase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: _isSubmitting
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Register',
                                style: TextStyle(
                                  fontSize: 22,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildTextField(
      String label, String hintText, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text,
      String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          validator: validator,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDropdownField(
      String label,
      String hintText,
      List<Map<String, String>> items,
      String? value,
      Function(dynamic)? onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            hintText: hintText,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          value: value,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item['id'], // Use the ID as the unique value
              child:
                  Text(item['name'] ?? 'Contact Developer'), // Display the name
            );
          }).toList(),
          onChanged: onChanged,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select $label';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDateField(String label, String hintText,
      TextEditingController controller, Function()? onTap,
      {String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hintText,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            suffixIcon: Icon(Icons.calendar_today),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          validator: validator,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFilePickerField(
      String label, String hintText, Function()? onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        TextFormField(
          readOnly: true,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: _fileNames.isEmpty
                ? hintText
                : '${_fileNames.length} file(s) selected',
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            suffixIcon: Icon(Icons.attach_file),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
