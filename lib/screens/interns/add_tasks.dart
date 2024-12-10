import 'package:flutter/material.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({Key? key}) : super(key: key);

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  String? _caseType;
  String? _caseNumber;
  String? _assignedTo;
  String? _assignDate;
  final _taskInstructionController = TextEditingController();

  @override
  void dispose() {
    _taskInstructionController.dispose();
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
        _assignDate = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  void _confirmTask() {
    if (_caseType == null ||
        _caseNumber == null ||
        _assignedTo == null ||
        _taskInstructionController.text.isEmpty ||
        _assignDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill out all fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    // Add task confirmation logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Task added successfully!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F3F3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Add\nTask',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            _buildDropdownField(
              label: 'Case Type',
              hint: 'Select Case Type',
              value: _caseType,
              items: ['Civil', 'Criminal', 'Corporate'],
              onChanged: (value) => setState(() => _caseType = value),
            ),
            const SizedBox(height: 20),
            _buildDropdownField(
              label: 'Case Number',
              hint: 'Select Case',
              value: _caseNumber,
              items: ['Case 001', 'Case 002', 'Case 003'],
              onChanged: (value) => setState(() => _caseNumber = value),
            ),
            const SizedBox(height: 20),
            _buildDropdownField(
              label: 'Assign to',
              hint: 'Select Intern',
              value: _assignedTo,
              items: ['John Doe', 'Jane Smith', 'Alex Brown'],
              onChanged: (value) => setState(() => _assignedTo = value),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              label: 'Task Instruction',
              hint: 'Instructions',
              controller: _taskInstructionController,
            ),
            const SizedBox(height: 20),
            _buildDateField(
              label: 'Assign Date',
              hint: _assignDate ?? 'Select Date',
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _confirmTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Confirm',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              isDense: true, // Compact appearance
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16, // Increased padding
                horizontal: 20,
              ),
              border: InputBorder.none,
            ),
            hint: Text(hint, style: const TextStyle(color: Colors.grey)),
            items: items
                .map((item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16, // Increased padding
              horizontal: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required String hint,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 16, // Increased padding
              horizontal: 20,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300), // Added border
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  hint,
                  style: const TextStyle(color: Colors.grey),
                ),
                const Icon(Icons.calendar_today, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
