import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../services/api_service.dart';

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
        _getCaseStageList("initial_stage"),
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
            data['data'].map(
                (item) => {"id": item['id'], "case_type": item['case_type']}),
          );
        });
      }
    }
  }

  Future<void> _getCaseStageList(String caseStage) async {
    final response = await http.post(
      Uri.parse("$baseUrl/get_stage_list"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"case_stage": caseStage}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          _caseStageList = List<Map<String, String>>.from(
            data['data']
                .map((item) => {"id": item['id'], "stage": item['stage']}),
          );
        });
      }
    }
  }

  Future<void> _getCompanyList() async {
    final response = await http.get(Uri.parse("$baseUrl/get_company_list"));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          _companyList = List<Map<String, String>>.from(
            data['data']
                .map((item) => {"id": item['id'], "name": item['name']}),
          );
        });
      }
    }
  }

  Future<void> _getCityList() async {
    final response = await http.get(Uri.parse("$baseUrl/get_city_list"));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          _cityList = List<Map<String, String>>.from(
            data['data']
                .map((item) => {"id": item['id'], "name": item['name']}),
          );
        });
      }
    }
  }

  Future<void> _getCourtList() async {
    final response = await http.get(Uri.parse("$baseUrl/get_court_list"));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          _courtList = List<Map<String, String>>.from(
            data['data']
                .map((item) => {"id": item['id'], "name": item['name']}),
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

    var response = await ApiService.submitNewCase(caseData, _filePaths);

    setState(() {
      _isSubmitting = false;
    });

    if (response['success']) {
      Get.snackbar('Success', 'Case submitted successfully!',
          snackPosition: SnackPosition.BOTTOM);
      Get.back();
    } else {
      Get.snackbar('Error', 'Failed to submit case: ${response['message']}',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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
                    _caseTypeList.map((e) => e['case_type']!).toList(),
                    _selectedCaseType, (value) {
                  setState(() {
                    _selectedCaseType = value;
                  });
                }),
                _buildDropdownField(
                    'Case Stage',
                    'Select Case Stage',
                    _caseStageList.map((e) => e['stage']!).toList(),
                    _selectedCaseStage, (value) {
                  setState(() {
                    _selectedCaseStage = value;
                  });
                }),
                _buildDropdownField(
                    'Handled By',
                    'Select Handler',
                    ['Advocate 1', 'Advocate 2', 'Advocate 3'],
                    _selectedHandler, (value) {
                  setState(() {
                    _selectedHandler = value;
                  });
                }),
                _buildDropdownField(
                    'Company Name',
                    'Select Company',
                    _companyList.map((e) => e['name']!).toList(),
                    _selectedCompany, (value) {
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
                _buildTextField('Opponent / Respondent / Accused', 'Enter Name',
                    _opponentController, validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the name';
                  }
                  return null;
                }),
                _buildDropdownField(
                    'Court Name',
                    'Select Court Name',
                    _courtList.map((e) => e['name']!).toList(),
                    _selectedCourtName, (value) {
                  setState(() {
                    _selectedCourtName = value;
                  });
                }),
                _buildDropdownField(
                    'City Name',
                    'Select City',
                    _cityList.map((e) => e['name']!).toList(),
                    _selectedCityName, (value) {
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

  Widget _buildDropdownField(String label, String hintText, List<String> items,
      String? value, Function(dynamic)? onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
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
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
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
