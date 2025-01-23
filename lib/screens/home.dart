import 'package:case_sync/models/advocate.dart';
import 'package:case_sync/services/case_services.dart';
import 'package:case_sync/services/shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'appbar/notification_drawer.dart';
import 'appbar/settings_drawer.dart';
import 'cases/assigned_cases.dart';
import 'cases/case_history.dart';
import 'cases/new_case.dart';
import 'cases/unassigned_cases.dart';
import 'companies/companies.dart';
import 'interns/assigned_case_taskInfo.dart';
import 'interns/intern_list.dart';
import 'officials/new_advocate.dart';
import 'officials/new_intern.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    populateCaseData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    String getGreeting() {
      var hour = DateTime.now().hour;
      if (hour < 12) {
        return 'Good Morning';
      } else if (hour < 17) {
        return 'Good Afternoon';
      } else {
        return 'Good Evening';
      }
    }

    double cardWidth = screenWidth * 0.40;
    double cardHeight = 72;
    double fullCardWidth = screenWidth * 0.93;
    double cardIconPositionX = cardWidth * 0.08;
    double cardIconPositionY = cardHeight * 0.21;
    double cardTextPositionY = cardHeight * 0.57;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color.fromRGBO(243, 243, 243, 1),
        elevation: 0,
        leadingWidth: 56 + 30,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/notification.svg',
            width: 35,
            height: 35,
          ),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: const Color.fromRGBO(201, 201, 201, 1),
              builder: (context) => const NotificationDrawer(),
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: IconButton(
              icon: SvgPicture.asset(
                'assets/icons/settings.svg',
                width: 35,
                height: 35,
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: const Color.fromRGBO(201, 201, 201, 1),
                  builder: (context) => const SettingsDrawer(),
                );
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<Advocate?>(
                future: SharedPrefService.getUser(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(
                      color: Colors.black,
                    );
                  } else if (snapshot.hasError) {
                    return const Text('Error loading user data');
                  } else if (snapshot.hasData && snapshot.data != null) {
                    Advocate user = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getGreeting(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                            height: 0.95,
                          ),
                        ),
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: Color.fromRGBO(37, 27, 70, 1.000),
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Cases',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                          childAspectRatio: cardWidth / cardHeight,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildCard(
                              'Assigned Cases',
                              'assets/icons/assigned.svg',
                              cardWidth,
                              cardHeight,
                              cardIconPositionX,
                              cardIconPositionY,
                              cardTextPositionY,
                              AssignedCases(),
                            ),
                            _buildCard(
                              'Unassigned Cases',
                              'assets/icons/unassigned.svg',
                              cardWidth,
                              cardHeight,
                              cardIconPositionX,
                              cardIconPositionY,
                              cardTextPositionY,
                              UnassignedCases(),
                            ),
                            _buildCard(
                              'Case History',
                              'assets/icons/case_history.svg',
                              cardWidth,
                              cardHeight,
                              cardIconPositionX,
                              cardIconPositionY,
                              cardTextPositionY,
                              CaseHistoryScreen(),
                            ),
                            _buildCard(
                              'New Case',
                              'assets/icons/new_case.svg',
                              cardWidth,
                              cardHeight,
                              cardIconPositionX,
                              cardIconPositionY,
                              cardTextPositionY,
                              NewCaseScreen(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Interns',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                          childAspectRatio: cardWidth / cardHeight,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildCard(
                              'Intern List',
                              'assets/icons/intern_list.svg',
                              cardWidth,
                              cardHeight,
                              cardIconPositionX,
                              cardIconPositionY,
                              cardTextPositionY,
                              InternListScreen(),
                            ),
                            _buildCard(
                              'Tasks',
                              'assets/icons/tasks.svg',
                              cardWidth,
                              cardHeight,
                              cardIconPositionX,
                              cardIconPositionY,
                              cardTextPositionY,
                              AssignedCaseTaskinfo(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Add an Official',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                          childAspectRatio: cardWidth / cardHeight,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildCard(
                              'New Advocate',
                              'assets/icons/new_advocate.svg',
                              cardWidth,
                              cardHeight,
                              cardIconPositionX,
                              cardIconPositionY,
                              cardTextPositionY,
                              NewAdvocateScreen(),
                            ),
                            _buildCard(
                              'New Intern',
                              'assets/icons/new_intern.svg',
                              cardWidth,
                              cardHeight,
                              cardIconPositionX,
                              cardIconPositionY,
                              cardTextPositionY,
                              NewInternScreen(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Companies',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildCard(
                          'Companies',
                          'assets/icons/companies.svg',
                          fullCardWidth,
                          cardHeight,
                          cardIconPositionX,
                          cardIconPositionY,
                          cardTextPositionY,
                          CompaniesScreen(),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  } else {
                    return const Text('User not found');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    String title,
    String iconPath,
    double cardWidth,
    double cardHeight,
    double iconPositionX,
    double iconPositionY,
    double textPositionY,
    Widget destinationScreen,
  ) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Colors.white,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Using Get.to for navigation
            Get.to(() => destinationScreen);
          },
          splashColor: Colors.grey.withOpacity(0.2),
          child: SizedBox(
            width: cardWidth,
            height: cardHeight,
            child: Stack(
              children: [
                Positioned(
                  left: iconPositionX,
                  top: iconPositionY,
                  child: SvgPicture.asset(
                    iconPath,
                    width: 24,
                    height: 24,
                  ),
                ),
                Positioned(
                  top: textPositionY,
                  left: iconPositionX,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: Colors.black,
                    ),
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
