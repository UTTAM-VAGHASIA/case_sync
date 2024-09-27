import 'package:flutter/material.dart';

class NewInternScreen extends StatelessWidget {
  const NewInternScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Intern'),
      ),
      body: Center(
        child: Text('New Intern Screen'),
      ),
    );
  }
}
