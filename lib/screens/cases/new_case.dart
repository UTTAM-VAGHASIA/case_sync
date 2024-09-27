import 'package:flutter/material.dart';

class NewCaseScreen extends StatelessWidget {
  const NewCaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Case'),
      ),
      body: Center(
        child: Text('New Case Screen'),
      ),
    );
  }
}
