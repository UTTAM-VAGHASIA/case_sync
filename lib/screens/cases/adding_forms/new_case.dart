import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../models/advocate.dart';
import '../../../services/shared_pref.dart';
import '../../constants/constants.dart';

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
  final TextEditingController _remarkController = TextEditingController();
  final TextEditingController _complainantAdvocateController =
      TextEditingController();
  final TextEditingController _respondentAdvocateController =
      TextEditingController();

  String _selectedSummonDateDisplay =
      DateFormat('dd/MM/yyyy').format(DateTime.now());
  String _selectedSummonDateApi =
      DateFormat('yyyy/MM/dd').format(DateTime.now());
  String _selectedFilingDateDisplay =
      DateFormat('dd/MM/yyyy').format(DateTime.now());
  String _selectedFilingDateApi =
      DateFormat('yyyy/MM/dd').format(DateTime.now());

  // String _selectedNextDateDisplay =
  //     DateFormat('dd/MM/yyyy').format(DateTime.now());
  // String _selectedNextDateApi = DateFormat('yyyy/MM/dd').format(DateTime.now());
  String? _selectedCaseType;
  String? _selectedHandler;
  String? _selectedCompany;
  String? _selectedCourtName;
  String? _selectedCityName;
  String? _selectedCaseStage;
  final List<String> _fileNames = [];
  final List<String> _filePaths = [];

  List<Map<String, String>> _caseTypeList = [];
  List<Map<String, String>> _caseStageList = [];
  List<Map<String, String>> _companyList = [];
  List<Map<String, String>> _cityList = [];
  List<Map<String, String>> _courtList = [];
  List<Map<String, String>> _advocateList = [];

  bool _isSubmitting = false;
  bool _isLoading = true;
  bool _isSummoned = false;
  bool _isFiled = false;

  // bool _isNextDateGiven = false;

  @override
  void dispose() {
    _caseNumberController.dispose();
    _caseYearController.dispose();
    _applicantController.dispose();
    _opponentController.dispose();
    _remarkController.dispose();
    _respondentAdvocateController.dispose();
    _complainantAdvocateController.dispose();
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

  Future<void> _getCaseStageCourtList(String caseTypeId) async {
    print("case type id: $caseTypeId");
    final response = await http.post(
      Uri.parse("$baseUrl/stage_court_list"),
      body: {'case_type_id': caseTypeId},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("Stage Response Data: ${data['data']}");
      if (data['success'] &&
          data['stage_list'] != null &&
          data['court_list'] != null) {
        setState(() {
          _caseStageList =
              List<Map<String, String>>.from(data['stage_list'].map((item) => {
                    "id": item['id']?.toString() ?? '',
                    "name": item['stage']?.toString() ?? '',
                  }));
          _courtList =
              List<Map<String, String>>.from(data['court_list'].map((item) => {
                    "id": item['id']?.toString() ?? '',
                    "name": item['name']?.toString() ?? '',
                  }));
        });
      } else {
        setState(() {
          print("Api Call Unsuccessful");
          _caseStageList = []; // No stages available
          _courtList = []; // No courts available
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

  Future<void> _selectSummonDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1800),
      lastDate: DateTime(2200),
    );
    if (picked != null) {
      setState(() {
        final date = DateFormat('dd/MM/yyyy').format(picked);
        final apiDate = DateFormat('yyyy/MM/dd').format(picked);
        if (_isSummoned) {
          _selectedSummonDateDisplay = date;
          _selectedSummonDateApi = apiDate;
          print('Summon Date Api: $_selectedSummonDateApi');
        }
      });

      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  Future<void> _selectFilingDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1800),
      lastDate: DateTime(2200),
    );
    if (picked != null) {
      setState(() {
        final date = DateFormat('dd/MM/yyyy').format(picked);
        final apiDate = DateFormat('yyyy/MM/dd').format(picked);
        if (_isFiled) {
          _selectedFilingDateDisplay = date;
          _selectedFilingDateApi = apiDate;
          print('Filing Date Api: $_selectedFilingDateApi');
        }
      });

      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  // Future<void> _selectNextDate(BuildContext context) async {
  //   final DateTime? picked = await showDatePicker(
  //     context: context,
  //     initialDate: DateTime.now(),
  //     firstDate: DateTime(1800),
  //     lastDate: DateTime(2200),
  //   );
  //   if (picked != null) {
  //     setState(() {
  //       final date = DateFormat('dd/MM/yyyy').format(picked);
  //       final apiDate = DateFormat('yyyy/MM/dd').format(picked);
  //       if (_isNextDateGiven) {
  //         _selectedNextDateDisplay = date;
  //         _selectedNextDateApi = apiDate;
  //         print('Next Date Api: $_selectedNextDateApi');
  //       }
  //     });
  //
  //     FocusManager.instance.primaryFocus?.unfocus();
  //   }
  // }

  Future<void> _pickDocuments() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        // Append newly selected files to the existing list.
        _fileNames.addAll(
          result.files
              .map((file) => file.name)
              .where((fileName) => !_fileNames.contains(fileName)),
        );
        _filePaths.addAll(
          result.files
              .map((file) => file.path!)
              .where((filePath) => !_filePaths.contains(filePath)),
        );
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _fileNames.removeAt(index);
      _filePaths.removeAt(index);
    });
  }

  void _clearAllFiles() {
    setState(() {
      _fileNames.clear();
      _filePaths.clear();
    });
  }

  Future<void> _submitCase() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Retrieve user details from SharedPreferences
      Advocate? user = await SharedPrefService.getUser();
      if (user == null) {
        throw Exception('User not found. Please log in again.');
      }

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
          orElse: () => {'id': ''},
        )['id'],
        "sr_date": _selectedSummonDateApi,
        "date_of_filing": _selectedFilingDateApi,
        "next_date": _selectedSummonDateApi,
        "complainant_advocate": _complainantAdvocateController.text,
        "respondent_advocate": _respondentAdvocateController.text,
        "remarks": _remarkController.text,
      });

      print("##########################################");
      print(request.fields);
      print("##########################################");

      // Add case_image file
      if (_filePaths.isNotEmpty) {
        String caseImage = _filePaths.first;
        request.files
            .add(await http.MultipartFile.fromPath('case_image', caseImage));
      }
      // Add case_docs[] files
      if (_filePaths.length > 1) {
        List<String> caseDocs =
            _filePaths.sublist(1); // Remaining files as case_docs[]
        for (String docPath in caseDocs) {
          request.files
              .add(await http.MultipartFile.fromPath('case_docs[]', docPath));
        }
      }

      // Send the request
      var response = await request.send();
      print("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%");
      print('${response.statusCode}');

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var data = json.decode(responseData);

        if (data['success']) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                  "Case with case no: ${_caseNumberController.text} Added successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text("Error: Failed to submit case: ${data['message']}"),
              backgroundColor: Colors.red,
            ),
          );
          print('Error, failed to submit case: ${data['message']}');
        }
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
                "Error: Status Code:${response.statusCode}. Failed to submit case. Try again later!"),
            backgroundColor: Colors.red,
          ),
        );
        print('Error hua hai: ${response.statusCode}');
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text("Error: An error occurred: $e"),
          backgroundColor: Colors.red,
        ),
      );
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
              HapticFeedback.mediumImpact();
              Get.back();
            },
          ),
        ),
        body: RefreshIndicator(
          color: Colors.black,
          onRefresh: () async {
            setState(() {
              _fetchDropdownData();
            });
          },
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    _buildTextField(
                        'Case Year', 'Case Year', _caseYearController,
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
                            _getCaseStageCourtList(value);
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
                    _buildDropdownField('Court Name', 'Select Court Name',
                        _courtList, _selectedCourtName, (value) {
                      setState(() {
                        _selectedCourtName = value;
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
                    _buildTextField('Complainant Advocate', 'Enter Name',
                        _complainantAdvocateController, validator: (value) {
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
                    _buildTextField('Respondent Advocate', 'Enter Name',
                        _respondentAdvocateController, validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the name';
                      }
                      return null;
                    }),
                    _buildDropdownField('City Name', 'Select City', _cityList,
                        _selectedCityName, (value) {
                      setState(() {
                        _selectedCityName = value;
                      });
                    }),
                    _buildDateField(
                      label: 'Summon Date',
                      child: Text(
                        _selectedSummonDateDisplay,
                        style: TextStyle(
                          color: _isSummoned ? Colors.black : Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          _isSummoned = true;
                          _selectSummonDate(context);
                        });
                      },
                    ),
                    _buildDateField(
                      label: 'Date of Filing',
                      child: Text(
                        _selectedFilingDateDisplay,
                        style: TextStyle(
                          color: _isFiled ? Colors.black : Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          _isFiled = true;
                          _selectFilingDate(context);
                        });
                      },
                    ),
                    _buildTextField(
                      'Remarks',
                      'Enter Remark Here',
                      _remarkController,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                    ),
                    _buildFilePickerField(
                        'Attach Documents', 'Attach Documents', _pickDocuments),
                    const SizedBox(height: 10),
                    if (_fileNames.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selected Files:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          ...List.generate(_fileNames.length, (index) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _fileNames[index],
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () {
                                      HapticFeedback.mediumImpact();
                                      _removeFile(index);
                                    }),
                              ],
                            );
                          }),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              _clearAllFiles();
                            },
                            icon: const Icon(
                              Icons.delete_sweep,
                              color: Colors.white,
                            ),
                            label: const Text('Remove All Files'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: EdgeInsets.all(8.0),
                            ),
                          ),
                        ],
                      ),
                    SizedBox(height: screenHeight * 0.05),
                    Center(
                      child: SizedBox(
                        width: screenWidth * 0.5,
                        height: 70,
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            _isSubmitting ? null : _submitCase();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: _isSubmitting
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  'Save',
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
        ),
      );
    }
  }

  Widget _buildTextField(
      String label, String hintText, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text,
      String? Function(String?)? validator,
      int? maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.black54,
            ),
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
        SizedBox(
          width: double.infinity,
          child: DropdownButtonFormField<String>(
            isExpanded: true,
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
                child: Text(
                  item['name'] ?? 'Contact Developer',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
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
            suffixIcon: const Icon(Icons.attach_file),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Row(
              children: [
                child,
                const Spacer(),
                const Icon(Icons.calendar_today, color: Colors.black),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
