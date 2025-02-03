import 'dart:convert';

import 'package:case_sync/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;

import '../../../utils/validator.dart';

class EditAdvocateScreen extends StatefulWidget {
  final Map<String, dynamic> advocate;
  const EditAdvocateScreen({
    super.key,
    required this.advocate,
  });

  @override
  _EditAdvocateScreenState createState() => _EditAdvocateScreenState();
}

class _EditAdvocateScreenState extends State<EditAdvocateScreen> {
  final bool _isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  late String _selectedStatus;
  bool _isLoading = false;
  final String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    print("Advocate Details received from other page: ${widget.advocate}");
    _nameController.text = widget.advocate['name'] ?? '';
    _contactController.text = widget.advocate['contact'] ?? '';
    _emailController.text = widget.advocate['email'] ?? '';
    _selectedStatus = widget.advocate['status'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _editAdvocate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String name = _nameController.text.trim();
    String contact = _contactController.text.trim();
    String email = _emailController.text.trim();

    try {
      final url = Uri.parse('$baseUrl/edit_advocate');

      var request = http.MultipartRequest('POST', url);
      request.fields['data'] = jsonEncode({
        "advocate_id": widget.advocate['id'],
        "name": name.isNotEmpty ? name : widget.advocate['name'],
        "contact": contact.isNotEmpty ? contact : widget.advocate['contact'],
        "email": email.isNotEmpty ? email : widget.advocate['email'],
        "password": widget.advocate['password'],
        "status": _selectedStatus,
      });

      print('Advocate details: ${request.fields['data']}');

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['response'])),
          );
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
        leadingWidth: 56 + 30,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/back_arrow.svg',
            width: 35,
            height: 35,
          ),
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
                    'Edit\nAdvocate',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                _buildTextField(
                  'Name',
                  'Advocate Name',
                  _nameController,
                  validator: (value) {
                    return validateTrimmedField(value, 'Name');
                  },
                ),
                _buildTextField(
                  'Contact Number',
                  '+91 XXXXXXXXXX',
                  _contactController,
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a status';
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.06),
                Center(
                  child: SizedBox(
                    width: screenWidth * 0.5,
                    height: 70,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _isLoading ? null : _editAdvocate();
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
                SizedBox(height: screenHeight * 0.05),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
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
