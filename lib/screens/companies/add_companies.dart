import 'dart:convert';

import 'package:case_sync/screens/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../utils/snackbar_utils.dart';
import '../../utils/validator.dart';

class AddCompanyScreen extends StatefulWidget {
  const AddCompanyScreen({super.key});

  @override
  _AddCompanyScreenState createState() => _AddCompanyScreenState();
}

class _AddCompanyScreenState extends State<AddCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactController = TextEditingController();

  @override
  void dispose() {
    _companyNameController.dispose();
    _contactPersonController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _registerCompany() async {
    String companyName = _companyNameController.text.trim();
    String contactPerson = _contactPersonController.text.trim();
    String contact = _contactController.text.trim();

    _companyNameController.text = companyName;
    _contactPersonController.text = contactPerson;
    _contactController.text = contact;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final url = Uri.parse('$baseUrl/add_company');
      var request = http.MultipartRequest('POST', url);

      request.fields['data'] = jsonEncode({
        "name": companyName,
        "contact_person": contactPerson,
        "contact_no": contact,
      });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        if (responseData['success'] == true) {
          SnackBarUtils.showSuccessSnackBar(
            context,
            responseData['message'],
          );

          _companyNameController.clear();
          _contactPersonController.clear();
          _contactController.clear();

          // Pass true back to the previous screen
          Navigator.pop(context, true);
        } else {
          SnackBarUtils.showErrorSnackBar(
            context,
            'Failed: ${responseData['message']}',
          );
        }
      } else {
        SnackBarUtils.showErrorSnackBar(
          context,
          'Server error: ${response.statusCode}',
        );
      }
    } catch (error) {
      SnackBarUtils.showErrorSnackBar(
        context,
        'Error: $error',
      );
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
            HapticFeedback.mediumImpact();
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
                    'Add\nCompany',
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
                SizedBox(height: screenHeight * 0.05),
                Center(
                  child: SizedBox(
                    width: screenWidth * 0.5,
                    height: 70,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _registerCompany();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: const Text(
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
