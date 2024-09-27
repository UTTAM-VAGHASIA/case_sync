import 'package:flutter/material.dart';

class UnassignedCasesScreen extends StatelessWidget {
  const UnassignedCasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Unassigned Cases'),
      ),
      body: Center(
        child: Text('Unassigned Cases Screen'),
      ),
    );
  }
}
