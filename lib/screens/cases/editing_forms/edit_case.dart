// import 'dart:convert';

import 'package:flutter/material.dart';

// import 'package:flutter/services.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:get/get.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';

import '../../../models/case.dart';
// import '../../../utils/constants.dart';

class EditCaseScreen extends StatefulWidget {
  final Case caseItem;

  const EditCaseScreen({super.key, required this.caseItem});

  @override
  EditCaseScreenState createState() => EditCaseScreenState();
}

class EditCaseScreenState extends State<EditCaseScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("This Functionality will be available soon!"),
      ),
    );
  }
}

// class EditCaseScreenState extends State<EditCaseScreen> {
//   final _formKey = GlobalKey<FormState>();
//
//   final TextEditingController _caseNumberController = TextEditingController();
//   final TextEditingController _caseYearController = TextEditingController();
//   final TextEditingController _applicantController = TextEditingController();
//   final TextEditingController _opponentController = TextEditingController();
//   final TextEditingController _complainantAdvocateController =
//       TextEditingController();
//   final TextEditingController _respondentAdvocateController =
//       TextEditingController();
//
//   String _selectedSummonDateDisplay = '';
//   String _selectedSummonDateApi = '';
//   String _selectedFilingDateDisplay = '';
//   String _selectedFilingDateApi = '';
//
//   String? _selectedCaseType;
//   String? _selectedHandler;
//   String? _selectedCompany;
//   String? _selectedCourtName;
//   String? _selectedCityName;
//   String? _selectedCaseStage;
//
//   List<Map<String, String>> _caseTypeList = [];
//   List<Map<String, String>> _caseStageList = [];
//   List<Map<String, String>> _companyList = [];
//   List<Map<String, String>> _cityList = [];
//   List<Map<String, String>> _courtList = [];
//   List<Map<String, String>> _advocateList = [];
//   bool _isLoading = true;
//   bool _isSummoned = false;
//   bool _isFiled = false;
//   final bool _isSubmitting = false;
//
//   @override
//   void dispose() {
//     _caseNumberController.dispose();
//     _caseYearController.dispose();
//     _applicantController.dispose();
//     _opponentController.dispose();
//     _respondentAdvocateController.dispose();
//     _complainantAdvocateController.dispose();
//     super.dispose();
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _populateInitialData();
//     _fetchDropdownData();
//   }
//
//   void _populateInitialData() {
//     _caseNumberController.text = widget.caseItem.caseNo;
//     _caseYearController.text = widget.caseItem.year;
//     _applicantController.text = widget.caseItem.applicant;
//     _opponentController.text = widget.caseItem.opponent;
//     _complainantAdvocateController.text = widget.caseItem.complainantAdvocate;
//     _respondentAdvocateController.text = widget.caseItem.respondentAdvocate;
//     _selectedSummonDateDisplay =
//         DateFormat('dd/MM/yyyy').format(widget.caseItem.srDate);
//     _selectedSummonDateApi =
//         DateFormat('yyyy/MM/dd').format(widget.caseItem.srDate);
//     _selectedFilingDateDisplay =
//         DateFormat('dd/MM/yyyy').format(widget.caseItem.dateOfFiling);
//     _selectedFilingDateApi =
//         DateFormat('yyyy/MM/dd').format(widget.caseItem.dateOfFiling);
//   }
//
//   Future<String?> _getCaseTypeList() async {
//     final response = await http.get(Uri.parse("$baseUrl/get_case_type_list"));
//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       if (data['success']) {
//         setState(() {
//           _caseTypeList = List<Map<String, String>>.from(
//             data['data'].map((item) => {
//                   "id": item['id']?.toString() ?? '',
//                   "name": item['case_type']?.toString() ?? '',
//                 }),
//           );
//         });
//
//         // Find the caseType ID based on the case type value
//         String? caseTypeId = _caseTypeList.firstWhere(
//           (item) => item['name'] == widget.caseItem.caseType,
//           orElse: () => {'id': ''},
//         )['id'];
//         return caseTypeId;
//       }
//     }
//     return null;
//   }
//
//   Future<void> _getCaseStageCourtList(String caseTypeId) async {
//     print("case type id: $caseTypeId");
//     final response = await http.post(
//       Uri.parse("$baseUrl/stage_court_list"),
//       body: {'case_type_id': caseTypeId},
//     );
//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       print("Stage Response Data: ${data['stage_list']}");
//       print("Court Response Data: ${data['court_list']}");
//       if (data['success'] &&
//           data['stage_list'] != null &&
//           data['court_list'] != null) {
//         setState(() {
//           _caseStageList =
//               List<Map<String, String>>.from(data['stage_list'].map((item) => {
//                     "id": item['id']?.toString() ?? '',
//                     "name": item['stage']?.toString() ?? '',
//                   }));
//           _courtList =
//               List<Map<String, String>>.from(data['court_list'].map((item) => {
//                     "id": item['id']?.toString() ?? '',
//                     "name": item['name']?.toString() ?? '',
//                   }));
//         });
//       } else {
//         setState(() {
//           print("Api Call Unsuccessful");
//           _caseStageList = []; // No stages available
//           _courtList = []; // No courts available
//         });
//       }
//     }
//   }
//
//   Future<void> _getAdvocateList() async {
//     final response = await http.get(Uri.parse("$baseUrl/get_advocate_list"));
//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       if (data['success']) {
//         setState(() {
//           _advocateList = List<Map<String, String>>.from(
//             data['data'].map((item) => {
//                   "id": item['id']?.toString() ?? '',
//                   "name": item['name']?.toString() ?? '',
//                 }),
//           );
//         });
//       }
//     }
//   }
//
//   Future<void> _getCompanyList() async {
//     final response = await http.get(Uri.parse("$baseUrl/get_company_list"));
//     if (response.statusCode == 200) {
//       print('Company');
//       final data = json.decode(response.body);
//       print("Company Response Data: ${data['data']}");
//       if (data['success']) {
//         setState(() {
//           _companyList = List<Map<String, String>>.from(
//             data['data'].map((item) => {
//                   "id": item['id']?.toString() ?? '',
//                   "name": item['name']?.toString() ?? '',
//                   "contact_person": item['contact_person']?.toString() ?? '',
//                   "contact_no": item['contact_no']?.toString() ?? '',
//                   "status": item['status']?.toString() ?? '',
//                   "date_time": item['date_time']?.toString() ?? '',
//                 }),
//           );
//         });
//       }
//     }
//   }
//
//   Future<void> _getCityList() async {
//     final response = await http.get(Uri.parse("$baseUrl/get_city_list"));
//     if (response.statusCode == 200) {
//       print('City');
//       final data = json.decode(response.body);
//       print("City Response Data: ${data['data']}");
//       if (data['success']) {
//         setState(() {
//           _cityList = List<Map<String, String>>.from(
//             data['data'].map((item) => {
//                   "id": item['id']?.toString() ?? '',
//                   "name": item['name']?.toString() ?? '',
//                 }),
//           );
//         });
//       }
//     }
//   }
//
//   void _prefillDropdownValues() {
//     _selectedCaseType = _caseTypeList.firstWhere(
//         (element) => element['name'] == widget.caseItem.caseType,
//         orElse: () => {'id': ''})['id'];
//     _selectedHandler = _advocateList.firstWhere(
//         (element) => element['name'] == widget.caseItem.handleBy,
//         orElse: () => {'id': ''})['id'];
//     _selectedCompany = _companyList.firstWhere(
//         (element) => element['name'] == widget.caseItem.company,
//         orElse: () => {'id': ''})['id'];
//     _selectedCourtName = widget.caseItem.courtName;
//     _selectedCityName = _cityList.firstWhere(
//         (element) => element['name'] == widget.caseItem.cityName,
//         orElse: () => {'id': ''})['id'];
//     _selectedCaseStage = _caseStageList.firstWhere(
//         (element) => element['name'] == widget.caseItem.stage,
//         orElse: () => {'id': ''})['id'];
//
//     // Ensure unique values for court list
//     final uniqueCourtNames = _courtList.map((item) => item['name']).toSet();
//     if (!uniqueCourtNames.contains(_selectedCourtName)) {
//       _selectedCourtName = null;
//     }
//
//     // Print the court list to verify uniqueness
//     print("Court List: $_courtList");
//     print("Selected Court Name: $_selectedCourtName");
//   }
//
//   @override
//   void _fetchDropdownData() async {
//     try {
//       String? id;
//       id = await _getCaseTypeList();
//       print("Type Id: $id");
//       await Future.wait([
//         _getCaseStageCourtList(id ?? ''),
//         _getCompanyList(),
//         _getCityList(),
//         _getAdvocateList(),
//       ]);
//     } catch (e) {
//       print("Error fetching dropdown data: $e");
//     } finally {
//       setState(() {
//         _isLoading = false;
//         _prefillDropdownValues(); // Prefill the dropdown values
//       });
//     }
//   }
//
//   Future<void> _selectSummonDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(1800),
//       lastDate: DateTime(2200),
//     );
//     if (picked != null) {
//       setState(() {
//         final date = DateFormat('dd/MM/yyyy').format(picked);
//         final apiDate = DateFormat('yyyy/MM/dd').format(picked);
//         if (_isSummoned) {
//           _selectedSummonDateDisplay = date;
//           _selectedSummonDateApi = apiDate;
//         }
//       });
//       FocusManager.instance.primaryFocus?.unfocus();
//     }
//   }
//
//   Future<void> _selectFilingDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(1800),
//       lastDate: DateTime(2200),
//     );
//     if (picked != null) {
//       setState(() {
//         final date = DateFormat('dd/MM/yyyy').format(picked);
//         final apiDate = DateFormat('yyyy/MM/dd').format(picked);
//         if (_isFiled) {
//           _selectedFilingDateDisplay = date;
//           _selectedFilingDateApi = apiDate;
//         }
//       });
//       FocusManager.instance.primaryFocus?.unfocus();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     double screenHeight = MediaQuery.of(context).size.height;
//     double screenWidth = MediaQuery.of(context).size.width;
//     if (_isLoading) {
//       return Scaffold(
//         body: Center(
//           child: CircularProgressIndicator(
//             color: Colors.black,
//           ),
//         ),
//       );
//     } else {
//       return Scaffold(
//         backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
//         appBar: AppBar(
//           surfaceTintColor: Colors.transparent,
//           backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
//           elevation: 0,
//           leadingWidth: 56 + 30,
//           leading: IconButton(
//             icon: SvgPicture.asset(
//               'assets/icons/back_arrow.svg',
//               width: 35,
//               height: 35,
//             ),
//             onPressed: () {
//               HapticFeedback.mediumImpact();
//               Get.back();
//             },
//           ),
//         ),
//         body: LiquidPullToRefresh(
//           backgroundColor: Colors.black,
//           color: Colors.transparent,
//           showChildOpacityTransition: false,
//           onRefresh: () async {
//             setState(() {
//               _fetchDropdownData();
//             });
//           },
//           child: SingleChildScrollView(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 30),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: <Widget>[
//                     Center(
//                       child: Text(
//                         'Edit Case',
//                         style: TextStyle(
//                           fontSize: 48,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black,
//                           height: 1.2,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                     SizedBox(height: screenHeight * 0.06),
//                     _buildTextField(
//                         'Case Number', 'Case Number', _caseNumberController,
//                         validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter the Case Number';
//                       }
//                       return null;
//                     }),
//                     _buildTextField(
//                         'Case Year', 'Case Year', _caseYearController,
//                         validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter the Case Year';
//                       }
//                       return null;
//                     }),
//                     _buildDropdownField(
//                       'Case Type',
//                       'Select Case Type',
//                       _caseTypeList,
//                       _selectedCaseType,
//                       (value) {
//                         if (value != null) {
//                           setState(() {
//                             _selectedCaseType = value;
//                             _selectedCaseStage = null;
//                             _caseStageList = [];
//                             _getCaseStageCourtList(value);
//                           });
//                         }
//                       },
//                     ),
//                     _buildDropdownField('Case Stage', 'Select Case Stage',
//                         _caseStageList, _selectedCaseStage, (value) {
//                       setState(() {
//                         _selectedCaseStage = value;
//                       });
//                     }),
//                     _buildDropdownField('Court Name', 'Select Court Name',
//                         _courtList, _selectedCourtName, (value) {
//                       setState(() {
//                         _selectedCourtName = value;
//                       });
//                     }),
//                     _buildDropdownField(
//                       'Handled By',
//                       'Select Advocate',
//                       _advocateList,
//                       _selectedHandler,
//                       (value) {
//                         setState(() {
//                           _selectedHandler = value;
//                         });
//                       },
//                     ),
//                     _buildDropdownField('Company Name', 'Select Company',
//                         _companyList, _selectedCompany, (value) {
//                       setState(() {
//                         _selectedCompany = value;
//                       });
//                     }),
//                     _buildTextField('Applicant / Appellant / Complainant',
//                         'Enter Name', _applicantController, validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter the name';
//                       }
//                       return null;
//                     }),
//                     _buildTextField('Complainant Advocate', 'Enter Name',
//                         _complainantAdvocateController, validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter the name';
//                       }
//                       return null;
//                     }),
//                     _buildTextField('Opponent / Respondent / Accused',
//                         'Enter Name', _opponentController, validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter the name';
//                       }
//                       return null;
//                     }),
//                     _buildTextField('Respondent Advocate', 'Enter Name',
//                         _respondentAdvocateController, validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter the name';
//                       }
//                       return null;
//                     }),
//                     _buildDropdownField('City Name', 'Select City', _cityList,
//                         _selectedCityName, (value) {
//                       setState(() {
//                         _selectedCityName = value;
//                       });
//                     }),
//                     _buildDateField(
//                       label: 'Summon Date',
//                       child: Text(
//                         _selectedSummonDateDisplay,
//                         style: TextStyle(
//                           color: _isSummoned ? Colors.black : Colors.black54,
//                           fontSize: 16,
//                         ),
//                       ),
//                       onTap: () {
//                         HapticFeedback.mediumImpact();
//                         setState(() {
//                           _isSummoned = true;
//                           _selectSummonDate(context);
//                         });
//                       },
//                     ),
//                     _buildDateField(
//                       label: 'Date of Filing',
//                       child: Text(
//                         _selectedFilingDateDisplay,
//                         style: TextStyle(
//                           color: _isFiled ? Colors.black : Colors.black54,
//                           fontSize: 16,
//                         ),
//                       ),
//                       onTap: () {
//                         HapticFeedback.mediumImpact();
//                         setState(() {
//                           _isFiled = true;
//                           _selectFilingDate(context);
//                         });
//                       },
//                     ),
//                     SizedBox(height: screenHeight * 0.05),
//                     Center(
//                       child: SizedBox(
//                         width: screenWidth * 0.5,
//                         height: 70,
//                         child: ElevatedButton(
//                           onPressed: () {
//                             HapticFeedback.mediumImpact();
//                             // _isSubmitting ? null : _submitCase();
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.black,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(50),
//                             ),
//                           ),
//                           child: _isSubmitting
//                               ? CircularProgressIndicator(color: Colors.white)
//                               : Text(
//                                   'Save',
//                                   style: TextStyle(
//                                     fontSize: 22,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 80),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       );
//     }
//   }
//
//   Widget _buildTextField(
//       String label, String hintText, TextEditingController controller,
//       {TextInputType keyboardType = TextInputType.text,
//       String? Function(String?)? validator}) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: <Widget>[
//         Text(label, style: const TextStyle(fontSize: 16)),
//         const SizedBox(height: 10),
//         TextFormField(
//           controller: controller,
//           keyboardType: keyboardType,
//           decoration: InputDecoration(
//             hintText: hintText,
//             hintStyle: TextStyle(
//               color: Colors.black54,
//             ),
//             contentPadding:
//                 const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),
//           ),
//           validator: validator,
//         ),
//         const SizedBox(height: 20),
//       ],
//     );
//   }
//
//   Widget _buildDropdownField(
//       String label,
//       String hintText,
//       List<Map<String, String>> items,
//       String? value,
//       Function(dynamic)? onChanged) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label, style: const TextStyle(fontSize: 16)),
//         const SizedBox(height: 10),
//         SizedBox(
//           width: double.infinity,
//           child: DropdownButtonFormField<String>(
//             isExpanded: true,
//             decoration: InputDecoration(
//               hintText: hintText,
//               contentPadding:
//                   const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//             ),
//             value: value,
//             items: items.map((item) {
//               return DropdownMenuItem<String>(
//                 value: item['id'], // Use the ID as the unique value
//                 child: Text(
//                   item['name'] ?? 'Contact Developer',
//                   overflow: TextOverflow.ellipsis,
//                   maxLines: 1,
//                 ),
//               );
//             }).toList(),
//             onChanged: onChanged,
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Please select $label';
//               }
//               return null;
//             },
//           ),
//         ),
//         const SizedBox(height: 20),
//       ],
//     );
//   }
//
//   Widget _buildDateField({
//     required String label,
//     required VoidCallback onTap,
//     required Widget child,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label, style: const TextStyle(fontSize: 16)),
//         const SizedBox(height: 10),
//         GestureDetector(
//           onTap: onTap,
//           child: Container(
//             padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
//             decoration: BoxDecoration(
//               border: Border.all(color: Colors.black),
//               borderRadius: BorderRadius.circular(20),
//               color: Colors.white,
//             ),
//             child: Row(
//               children: [
//                 child,
//                 const Spacer(),
//                 const Icon(Icons.calendar_today, color: Colors.black),
//               ],
//             ),
//           ),
//         ),
//         const SizedBox(height: 20),
//       ],
//     );
//   }
// }
