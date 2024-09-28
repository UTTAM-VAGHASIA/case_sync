import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../appbar/settings_drawer.dart';

class CompaniesScreen extends StatelessWidget {
  // Sample list of companies for demonstration
  final List<Map<String, String>> companies = [
    {
      'company': '#Company123',
      'name': 'Name',
      'phone': '+91 XXXXXXXXXX',
    },
    {
      'company': '#Company124',
      'name': 'Name',
      'phone': '+91 XXXXXXXXXX',
    },
    {
      'company': '#Company125',
      'name': 'Name',
      'phone': '+91 XXXXXXXXXX',
    },
    // Add more companies here
  ];

  CompaniesScreen({super.key});

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
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: IconButton(
              icon: SvgPicture.asset(
                'assets/icons/settings.svg',
                width: 35,
                height: 35,
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  scrollControlDisabledMaxHeightRatio: 5 / 6,
                  backgroundColor: Color.fromRGBO(201, 201, 201, 1),
                  builder: (context) => const SettingsDrawer(),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Title below the AppBar
          Container(
            color: Color(0xFFF3F3F3),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Companies',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                )
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16.0),
              itemCount: companies.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                companies[index]['company']!,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(companies[index]['name']!),
                              Text(companies[index]['phone']!),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}