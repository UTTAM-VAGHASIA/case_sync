import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class NewInternScreen extends StatefulWidget {
  const NewInternScreen({super.key});

  @override
  _NewInternScreenState createState() => _NewInternScreenState();
}

class _NewInternScreenState extends State<NewInternScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _joiningDateController = TextEditingController();
  bool _isPasswordVisible = false; // Track password visibility

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
        _joiningDateController.text = formattedDate; // Display formatted date
      });
    }
  }

  Future<void> _registerIntern() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Collect form input
    String name = _nameController.text;
    String contact = _contactNumberController.text;
    String email = _emailController.text;
    String password = _passwordController.text;
    String startDate = _joiningDateController.text;

    try {
      // API URL
      final url = Uri.parse(
          'https://pragmanxt.com/case_sync/services/admin/v1/index.php/intern_registration');

      // Create a multipart request
      var request = http.MultipartRequest('POST', url);

      // Add fields as form data
      request.fields['data'] = jsonEncode({
        "name": name,
        "contact": contact,
        "email": email,
        "password": password,
        "start_date": startDate,
      });

      // Send the request
      final response = await request.send();

      // Handle the response
      final responseBody = await response.stream.bytesToString();

      print('Status Code: ${response.statusCode}');
      print('Response Body: $responseBody');

      if (response.statusCode == 200) {
        // Decode the response body
        final responseData = jsonDecode(responseBody);

        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'])),
          );

          // Clear the input fields
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Text(
                  'Register Intern',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(height: 30),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Name Label and Input Field
                    Text('Name', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 5),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Intern name',
                        hintStyle: TextStyle(fontWeight: FontWeight.normal),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter intern name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Contact Number Label and Input Field
                    Text('Contact number', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 5),
                    TextFormField(
                      controller: _contactNumberController,
                      decoration: InputDecoration(
                        hintText: '+91 XXXXXXXXXX',
                        hintStyle: TextStyle(fontWeight: FontWeight.normal),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter contact number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Email Label and Input Field
                    Text('Email', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 5),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'example@gmail.com',
                        hintStyle: TextStyle(fontWeight: FontWeight.normal),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Password Label and Input Field
                    Text('Password', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 5),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        hintText: 'must be 8 characters',
                        hintStyle: TextStyle(fontWeight: FontWeight.normal),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !_isPasswordVisible,
                      validator: (value) {
                        if (value == null || value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Joining Date Label and Input Field
                    Text('Joining Date', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 5),
                    TextFormField(
                      controller: _joiningDateController,
                      decoration: InputDecoration(
                        hintText: 'DD/MM/YYYY',
                        hintStyle: TextStyle(fontWeight: FontWeight.normal),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () {
                            _selectDate(context);
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter joining date';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 30),

                    // Register Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _registerIntern,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(vertical: 15),
                          textStyle: TextStyle(fontSize: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Register',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
