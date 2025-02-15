import 'package:case_sync/models/case_list.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditCaseScreen extends StatefulWidget {
  final CaseListData caseItem;

  const EditCaseScreen({super.key, required this.caseItem});

  @override
  EditCaseScreenState createState() => EditCaseScreenState();
}

class EditCaseScreenState extends State<EditCaseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _caseNumberController;
  late TextEditingController _applicantController;
  late TextEditingController _opponentController;
  late String _selectedCaseType;
  late String _selectedCourtName;
  late String _selectedNextDate;

  @override
  void initState() {
    super.initState();
    _caseNumberController = TextEditingController(text: widget.caseItem.caseNo);
    _applicantController =
        TextEditingController(text: widget.caseItem.applicant);
    _opponentController = TextEditingController(text: widget.caseItem.opponent);
    _selectedCaseType = widget.caseItem.caseType;
    _selectedCourtName = widget.caseItem.courtName;
    _selectedNextDate =
        DateFormat('dd/MM/yyyy').format(widget.caseItem.nextDate);
  }

  @override
  void dispose() {
    _caseNumberController.dispose();
    _applicantController.dispose();
    _opponentController.dispose();
    super.dispose();
  }

  Future<void> _selectNextDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.caseItem.nextDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != widget.caseItem.nextDate) {
      setState(() {
        _selectedNextDate = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _submitEdit() {
    if (_formKey.currentState!.validate()) {
      // Handle case update logic here
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Case')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _caseNumberController,
                decoration: InputDecoration(labelText: 'Case Number'),
                validator: (value) =>
                    value!.isEmpty ? 'Enter case number' : null,
              ),
              TextFormField(
                controller: _applicantController,
                decoration: InputDecoration(labelText: 'Applicant'),
                validator: (value) =>
                    value!.isEmpty ? 'Enter applicant name' : null,
              ),
              TextFormField(
                controller: _opponentController,
                decoration: InputDecoration(labelText: 'Opponent'),
                validator: (value) =>
                    value!.isEmpty ? 'Enter opponent name' : null,
              ),
              ListTile(
                title: Text('Next Hearing Date: $_selectedNextDate'),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectNextDate(context),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitEdit,
                child: Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
