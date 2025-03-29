import 'package:case_sync/models/case.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

import '../editing_forms/edit_case.dart';
import 'case_history_page.dart';
import 'case_info_page.dart';
import 'task_history_page.dart';
import 'view_docs_page.dart';

class BottomNavBar extends StatefulWidget {
  final String caseId;
  final String caseNo;
  final bool isUnassigned;

  const BottomNavBar({
    super.key,
    required this.caseId,
    required this.caseNo,
    this.isUnassigned = false,
  });

  @override
  BottomNavBarState createState() => BottomNavBarState();
}

class BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;
  late PageController _pageController;
  late Case caseItem;
  Map<String, dynamic> rawData = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.ease,
    );

    ScaffoldMessenger.of(context).clearSnackBars();
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });

    ScaffoldMessenger.of(context).clearSnackBars();
  }

  void _onCaseItemFetched(Map<String, dynamic> fetchedCaseItem) {
    setState(() {
      rawData = fetchedCaseItem;
      caseItem = Case.fromJson(rawData);
      if (kDebugMode) {
        print("caseItem: $caseItem");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0.0),
          child: Divider(
            thickness: 2,
            height: 0,
          ),
        ),
        backgroundColor: const Color(0xFFF3F3F3),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/back_arrow.svg'),
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.caseNo,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 27,
          ),
        ),
        actions: _selectedIndex == 0
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: Colors.black),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditCaseScreen(
                          caseItem: caseItem,
                        ),
                      ),
                    );
                  },
                ),
                Padding(
                  padding: EdgeInsets.only(right: 10),
                ),
              ]
            : null,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          CaseInfoPage(
            caseId: widget.caseId,
            caseNo: widget.caseNo,
            onCaseItemFetched: _onCaseItemFetched,
          ),
          CaseHistoryPage(
            caseId: widget.caseId,
            caseNo: widget.caseNo,
          ),
          TaskHistoryPage(
            caseId: widget.caseId,
            caseNo: widget.caseNo,
          ),
          ViewDocsPage(caseId: widget.caseId, caseNo: widget.caseNo),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFF3F3F3),
        showUnselectedLabels: false,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.info), label: "Case Info"),
          BottomNavigationBarItem(
              icon: Icon(Icons.history), label: "Case History"),
          BottomNavigationBarItem(
              icon: Icon(Icons.task), label: "Task History"),
          BottomNavigationBarItem(icon: Icon(Icons.file_copy), label: "Docs"),
        ],
      ),
    );
  }
}
