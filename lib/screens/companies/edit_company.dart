import 'dart:convert';

import 'package:case_sync/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../utils/validator.dart';

class EditCompanyScreen extends StatefulWidget {
  final String companyId;
  final String companyName;
  final String contactPerson;
  final String contactNo;
  final String status;

  const EditCompanyScreen({
    super.key,
    required this.companyId,
    required this.companyName,
    required this.contactPerson,
    required this.contactNo,
    required this.status,
  });

  @override
  EditCompanyScreenState createState() => EditCompanyScreenState();
}

class EditCompanyScreenState extends State<EditCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactController = TextEditingController();

  late String _selectedStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _companyNameController.text = widget.companyName;
    _contactPersonController.text = widget.contactPerson;
    _contactController.text = widget.contactNo;
    _selectedStatus = widget.status;
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _contactPersonController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _editCompany() async {
    String companyName = _companyNameController.text.trim();
    String contactPerson = _contactPersonController.text.trim();
    String contact = _contactController.text.trim();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('$baseUrl/edit_company');
      var request = http.MultipartRequest('POST', url);

      request.fields['data'] = jsonEncode({
        "company_id": widget.companyId,
        "name": companyName.isNotEmpty ? companyName : widget.companyName,
        "contact_person":
            contactPerson.isNotEmpty ? contactPerson : widget.contactPerson,
        "contact_no": contact.isNotEmpty ? contact : widget.contactNo,
        "status": _selectedStatus.isNotEmpty ? _selectedStatus : widget.status,
      });

      print(request.fields['data']);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      print(responseBody);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        print(responseData['success']);
        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['response'])),
          );

          _companyNameController.clear();
          _contactPersonController.clear();
          _contactController.clear();

          // Pass true back to the previous screen
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${responseData['response']}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
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
                    'Edit\nCompany',
                    style: const TextStyle(
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
                  'Company Name',
                  'Company Name',
                  _companyNameController,
                  validator: (value) {
                    return validateTrimmedField(value, 'Company Name');
                  },
                ),
                _buildTextField(
                  'Contact Person',
                  'Contact Person',
                  _contactPersonController,
                  validator: (value) {
                    return validateTrimmedField(value, 'Contact Person');
                  },
                ),
                _buildTextField(
                  'Contact No.',
                  '+91 XXXXXXXXXX',
                  _contactController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    return validateAndTrimPhoneNumber(value);
                  },
                ),
                const SizedBox(height: 20),
                Text('Status', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  items: ['enable', 'disable']
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a status';
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.05),
                Center(
                  child: SizedBox(
                    width: screenWidth * 0.5,
                    height: 70,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _editCompany,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 22,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hintText,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
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
}
