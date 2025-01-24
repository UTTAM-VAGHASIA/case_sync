import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../utils/validator.dart'; // Import validators file

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
  final _joiningDateController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _joiningDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      String formattedDate = DateFormat('dd/MM/yyyy').format(selectedDate);
      setState(() {
        _joiningDateController.text = formattedDate;
      });
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
    String startDate = _joiningDateController.text.trim();

    try {
      final url = Uri.parse(
          'https://pragmanxt.com/case_sync/services/admin/v1/index.php/intern_registration');

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
          _joiningDateController.clear();
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
              _buildDateField('Joining Date', 'DD/MM/YYYY'),
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
                      'Register',
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

  Widget _buildTextField(String label, String hintText,
      TextEditingController controller,
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

  Widget _buildDateField(String label, String hintText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        TextFormField(
          controller: _joiningDateController,
          readOnly: true,
          onTap: () {
            _selectDate(context);
          },
          decoration: InputDecoration(
            hintText: hintText,
            contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            suffixIcon: const Icon(Icons.calendar_today),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a joining date';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
