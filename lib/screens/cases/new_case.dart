import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart'; // Import intl package for date formatting

class NewCaseScreen extends StatefulWidget {
  const NewCaseScreen({super.key});

  @override
  NewCaseScreenState createState() => NewCaseScreenState();
}

class NewCaseScreenState extends State<NewCaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _joiningDateController = TextEditingController();

  String? _fileName;

  // Method to show date picker and select a date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Set the initial date
      firstDate: DateTime(2000), // Set the earliest selectable date
      lastDate: DateTime(2101), // Set the latest selectable date
    );
    if (pickedDate != null) {
      setState(() {
        // Format the selected date and display it in the TextFormField
        _joiningDateController.text =
            DateFormat('dd/MM/yyyy').format(pickedDate);
      });
    }
  }
  Future<void> _pickDocument() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        _fileName = result.files.single.name;
      });
    } else {
      setState(() {
        _fileName = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3F3F3), // Set background to #f3f3f3
      body: SafeArea(
        // Ensure content is displayed within safe area
        child: SingleChildScrollView(
          // Make the layout scrollable
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Custom back button (positioned at the top-left corner)
                IconButton(
                  icon: Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    Navigator.pop(context); // Navigate back
                  },
                  alignment: Alignment.topLeft,
                ),
                SizedBox(height: 20),
                Center(
                  child: Text(
                    'New Case',
                    style: TextStyle(
                      fontSize: 36, // Increased font size
                      fontWeight: FontWeight.bold, // Made text bold
                    ),
                    textAlign: TextAlign.center, // Center the title
                  ),
                ),

                SizedBox(height: 30), // Extra spacing after the title
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Add text label before each TextFormField

                      // Case-Number Starting
                      Text(
                        'Case Number',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 5),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Case-Number',
                          hintStyle: TextStyle(
                              fontWeight: FontWeight
                                  .normal), // Remove bold from hint text
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.grey), // Light grey border color
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the Case Number';
                          }
                          return null;
                        },
                      ),
                      // case-Number Ending

                      // Case-Year Starting
                      SizedBox(height: 20),
                      Text(
                        'Case Year',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 5),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Case-Year',
                          hintStyle: TextStyle(
                              fontWeight: FontWeight
                                  .normal), // Remove bold from hint text
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.grey), // Light grey border color
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter  Case Year';
                          }
                          return null;
                        },
                      ),
                      // Case-Year Ending

                      // Case-type Drop-down starting
                      SizedBox(height: 20),
                      Text(
                        'Case-type',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 5),
                      DropdownButtonFormField<String>(
                        // controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Select Case-type',
                          hintStyle: TextStyle(
                              fontWeight: FontWeight
                                  .normal), // Remove bold from hint text
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.grey), // Light grey border color
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        hint: Text('Select Case'),
                        items: ['Case 1', 'Case 2', 'Case 3']
                            .map((CaseType) => DropdownMenuItem<String>(
                                  value: CaseType,
                                  child: Text(CaseType),
                                ))
                            .toList(),
                        onChanged: (value) {
                          // Handle value change
                        },
                      ),
                      // Case-type-Drop-down ending

                      // Company Drop-down starting
                      SizedBox(height: 20),
                      Text(
                        'Company Name',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 5),
                      DropdownButtonFormField<String>(
                        // controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Select Company',
                          hintStyle: TextStyle(
                              fontWeight: FontWeight
                                  .normal), // Remove bold from hint text
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.grey), // Light grey border color
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        hint: Text('Select Company'),
                        items: ['Company 1', 'Company 2', 'Company 3']
                            .map((CompanyName) => DropdownMenuItem<String>(
                                  value: CompanyName,
                                  child: Text(CompanyName),
                                ))
                            .toList(),
                        onChanged: (value) {
                          // Handle value change
                        },
                      ),
                      // Company-Name-Drop-down ending

                      // Plantiff Name Starting
                      SizedBox(height: 20),
                      Text(
                        'Plantiff Name ',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 5),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Plantiff Name ',
                          hintStyle: TextStyle(
                              fontWeight: FontWeight
                                  .normal), // Remove bold from hint text
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.grey), // Light grey border color
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter Plantiff Name ';
                          }
                          return null;
                        },
                      ),
                      // Plantiff Name  Ending

                      // Court Name Drop-down starting
                      SizedBox(height: 20),
                      Text(
                        'Court Name',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 5),
                      DropdownButtonFormField<String>(
                        // controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Select Court Name ',
                          hintStyle: TextStyle(
                              fontWeight: FontWeight
                                  .normal), // Remove bold from hint text
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.grey), // Light grey border color
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        hint: Text('Select Court'),
                        items: ['Court 1', 'Court 2', 'Court 3']
                            .map((CourtName) => DropdownMenuItem<String>(
                                  value: CourtName,
                                  child: Text(CourtName),
                                ))
                            .toList(),
                        onChanged: (value) {
                          // Handle value change
                        },
                      ),
                      // Court-name-Drop-down ending

                      // City-Name Drop-down starting
                      SizedBox(height: 20),
                      Text(
                        'City Name',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 5),
                      DropdownButtonFormField<String>(
                        // controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Select City ',
                          hintStyle: TextStyle(
                              fontWeight: FontWeight
                                  .normal), // Remove bold from hint text
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.grey), // Light grey border color
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        hint: Text('Select City'),
                        items: ['Surat', 'Bardoli', 'Rajkot']
                            .map((CityName) => DropdownMenuItem<String>(
                                  value: CityName,
                                  child: Text(CityName),
                                ))
                            .toList(),
                        onChanged: (value) {
                          // Handle value change
                        },
                      ),
                      // City-name-Drop-down ending

                      // Summon Date  Starting
                      SizedBox(height: 20),
                      Text('Summon Date  ', style: TextStyle(fontSize: 16)),
                      SizedBox(height: 5),
                      TextFormField(
                        controller: _joiningDateController,
                        decoration: InputDecoration(
                          hintText: 'Summon Date  ',
                          hintStyle: TextStyle(fontWeight: FontWeight.normal),
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.calendar_today),
                            onPressed: () {
                              _selectDate(context); // Call _selectDate method
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter Summon Date';
                          }
                          return null;
                        },
                      ),
                        SizedBox(height: 20),
                      // Summon Date Ending

                      //Attach Document starting
                       Text('Attach Document ', style: TextStyle(fontSize: 16)),
                      SizedBox(height: 5),
                      TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: _fileName ?? 'Attach Document',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.attach_file),
                            onPressed: _pickDocument,
                          ),
                        ),
                      ),
                        SizedBox(height: 30),                      
                      //Attach Document ending 

                      
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Processing Data')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            textStyle: TextStyle(fontSize: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text('Register'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
