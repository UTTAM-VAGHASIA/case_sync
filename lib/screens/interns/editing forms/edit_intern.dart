import 'dart:convert';

import 'package:case_sync/screens/constants/constants.dart';
import 'package:case_sync/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../../utils/validator.dart';

class EditInternScreen extends StatefulWidget {
  final Map<String, dynamic> intern;

  const EditInternScreen({super.key, required this.intern});

  @override
  _EditInternScreenState createState() => _EditInternScreenState();
}

class _EditInternScreenState extends State<EditInternScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();

  String? _selectedStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.intern['name'] ?? '';
    _contactNumberController.text = widget.intern['contact'] ?? '';
    _emailController.text = widget.intern['email'] ?? '';
    _selectedStatus =
        (widget.intern['status'] == null || widget.intern['status'] == '')
            ? 'enable'
            : widget.intern['status'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _editIntern() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String name = _nameController.text.trim();
    String contact = _contactNumberController.text.trim();
    String email = _emailController.text.trim();

    try {
      final url = Uri.parse('$baseUrl/edit_intern');

      var request = http.MultipartRequest('POST', url);
      request.fields['data'] = jsonEncode({
        "intern_id": widget.intern['id'],
        "name": name.isNotEmpty ? name : widget.intern['name'],
        "contact": contact.isNotEmpty ? contact : widget.intern['contact'],
        "password": widget.intern['password'],
        "email": email.isNotEmpty ? email : widget.intern['email'],
        "status": _selectedStatus,
      });

      print('data: ${request.fields['data']}');

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        if (responseData['success'] == true) {
          SnackBarUtils.showSuccessSnackBar(context, responseData['response']);
          Navigator.pop(context, true);
        } else {
          SnackBarUtils.showErrorSnackBar(context, 'Failed: ${responseData['response']}');
        }
      } else {
          SnackBarUtils.showErrorSnackBar(
              context,
              'Server error: ${response.statusCode}, ${response.reasonPhrase}');
      }
    } catch (error) {
      SnackBarUtils.showErrorSnackBar(context, 'Error: $error');
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
                    'Edit\nIntern',
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
                  'Name',
                  'Intern Name',
                  _nameController,
                  validator: (value) {
                    return validateTrimmedField(value, 'Name');
                  },
                ),
                _buildTextField(
                  'Contact Number',
                  '+91 XXXXXXXXXX',
                  _contactNumberController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    return validateAndTrimPhoneNumber(value);
                  },
                ),
                _buildTextField(
                  'Email',
                  'example@gmail.com',
                  _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    return validateEmail(value);
                  },
                ),
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
                ),
                SizedBox(height: screenHeight * 0.05),
                Center(
                  child: SizedBox(
                    width: screenWidth * 0.5,
                    height: 70,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _isLoading ? null : _editIntern();
                      },
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
