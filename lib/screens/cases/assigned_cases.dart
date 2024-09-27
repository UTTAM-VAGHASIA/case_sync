import 'package:flutter/material.dart';

class AssignedCasesScreen extends StatelessWidget {
  const AssignedCasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assigned Cases'),
      ),
      body: Center(
        child: Text('Assigned Cases Screen'),
      ),
    );
  }
}
