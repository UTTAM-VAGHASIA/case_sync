import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

import '../../../services/api_service.dart';
import '../../../utils/validator.dart';

class NewAdvocateScreen extends StatefulWidget {
  const NewAdvocateScreen({super.key});

  @override
  _NewAdvocateScreenState createState() => _NewAdvocateScreenState();
}

class _NewAdvocateScreenState extends State<NewAdvocateScreen> {
  bool _isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _registerAdvocate() async {
    if (!_formKey.currentState!.validate()) {
      return; // If the form is not valid, return early
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Trim the input values
    String name = _nameController.text.trim();
    String contact = _contactController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    try {
      Map<String, dynamic> response =
          await ApiService.registerAdvocate(name, contact, email, password);
      print("$response");

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Advocate registered successfully!')),
        );
        Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage = '${response['message']}\n${response['error']}';
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'An error occurred: $error';
      });
    }

    setState(() {
      _isLoading = false;
    });
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
            key: _formKey, // Add GlobalKey here
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Text(
                    'Register\nAdvocate',
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
                _buildTextField('Advocate Name', 'Name', _nameController),
                _buildTextField(
                    'Advocate Contact', '+91 XXXXXXXXXX', _contactController,
                    keyboardType: TextInputType.phone,
                    additionalValidator: (value) {
                  if (!RegExp(r'^[0-9]{10}$').hasMatch(value!.trim())) {
                    return 'Enter a valid 10-digit phone number';
                  }
                  return null;
                }),
                _buildTextField('Email', 'example@gmail.com', _emailController,
                    keyboardType: TextInputType.emailAddress,
                    additionalValidator: (value) {
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                }),
                _buildPasswordField(),
                SizedBox(height: screenHeight * 0.03),
                Center(
                  child: SizedBox(
                    width: screenWidth * 0.5,
                    height: 70,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _isLoading ? null : _registerAdvocate();
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
      String label, String hintText, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text,
      String? Function(String?)? additionalValidator}) {
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
      children: <Widget>[
        const Text('Password', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            hintText: "Enter Password",
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            suffixIcon: IconButton(
              icon: Icon(
                color: Colors.black,
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          validator: (value) {
            return validateAndTrimField(value, 'Password');
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
