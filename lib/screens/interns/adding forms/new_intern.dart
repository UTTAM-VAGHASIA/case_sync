import 'dart:convert';

import 'package:case_sync/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../utils/validator.dart';

class NewInternScreen extends StatefulWidget {
  const NewInternScreen({super.key});

  @override
  _NewInternScreenState createState() => _NewInternScreenState();
}

class _NewInternScreenState extends State<NewInternScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _joiningDateDisplay = DateFormat('dd/MM/yyyy').format(DateTime.now());
  String _joiningDateApi = DateFormat('dd/MM/yyyy').format(DateTime.now());
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isSelected = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _isSelected = true;
        final date = "${picked.day}/${picked.month}/${picked.year}";
        final apiDate =
            "${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}";

        _joiningDateDisplay = date;
        _joiningDateApi = apiDate;
        print(_joiningDateApi);
      });

      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  Future<void> _registerIntern() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String name = _nameController.text.trim();
    String contact = _contactNumberController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String startDate = _joiningDateApi;

    try {
      final url = Uri.parse('$baseUrl/intern_registration');

      var request = http.MultipartRequest('POST', url);
      request.fields['data'] = jsonEncode({
        "name": name,
        "contact": contact,
        "email": email,
        "password": password,
        "start_date": startDate,
      });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody);
        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Intern registered successfully!')),
          );

          _formKey.currentState?.reset();
          _nameController.clear();
          _contactNumberController.clear();
          _emailController.clear();
          _passwordController.clear();

          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${responseData['message']}')),
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
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/back_arrow.svg', width: 35),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Register Intern',
                  style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 30),
              _buildTextField('Name', 'Intern name', _nameController),
              _buildTextField(
                'Contact number',
                '+91 XXXXXXXXXX',
                _contactNumberController,
                keyboardType: TextInputType.phone,
                additionalValidator: validatePhoneNumber,
              ),
              _buildTextField(
                'Email',
                'example@gmail.com',
                _emailController,
                keyboardType: TextInputType.emailAddress,
                additionalValidator: validateEmail,
              ),
              _buildPasswordField(),
              _buildDateField(
                  label: 'Joining Date',
                  onTap: () {
                    _selectDate(context);
                  },
                  child: Text(
                    _joiningDateDisplay,
                    style: TextStyle(
                        color: _isSelected ? Colors.black : Colors.grey,
                        fontSize: 16),
                  )),
              const SizedBox(height: 30),
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: 70,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _registerIntern,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Save',
                            style: TextStyle(fontSize: 22, color: Colors.white),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, String hintText, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text,
      String? Function(String?)? additionalValidator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          validator: (value) {
            String? result = validateAndTrimField(value, label);
            if (result != null) return result;
            if (additionalValidator != null) return additionalValidator(value);
            return null;
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Password', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            hintText: "must be 8 characters",
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          validator: validatePassword,
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
      ],
    );
  }
}
