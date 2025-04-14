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
  final String caseType;
  final int targetPage;
  final bool flag;

  const BottomNavBar({
    super.key,
    required this.caseId,
    required this.caseNo,
    this.isUnassigned = false,
    required this.caseType,
    this.targetPage = 0,
    this.flag = false,
  });

  @override
  BottomNavBarState createState() => BottomNavBarState();
}

class BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;
  PageController _pageController = PageController(initialPage: 0);
  late Case caseItem;
  late String caseNo;
  late String caseType;
  Map<String, dynamic> rawData = {};
  final GlobalKey<CaseInfoPageState> _caseInfoKey =
      GlobalKey<CaseInfoPageState>();

  late bool flag;

  @override
  void initState() {
    super.initState();
    flag = widget.flag;
    caseNo = widget.caseNo;
    caseType = widget.caseType;
  }

  void openPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.ease,
    );
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
      setState(() {
        caseNo = caseItem.caseNo;
        caseType = caseItem.caseType;
      });
      if (kDebugMode) {
        print("caseItem: $caseItem");
      }
    });
    if (widget.targetPage != 0 && flag == true) {
      setState(() {
        _selectedIndex = widget.targetPage;
      });
      openPage(_selectedIndex);
      flag = false;
    }
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
          caseNo,
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
                  onPressed: () async {
                    bool? result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditCaseScreen(
                          caseItem: caseItem,
                        ),
                      ),
                    );

                    if (result != null && result) {
                      await _caseInfoKey.currentState?.fetchCaseInfo();
                      await _caseInfoKey.currentState?.fetchStageList();
                    }
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
            key: _caseInfoKey,
            caseId: widget.caseId,
            caseNo: caseNo,
            onCaseItemFetched: _onCaseItemFetched,
          ),
          CaseHistoryPage(
            caseId: widget.caseId,
            caseNo: caseNo,
          ),
          TaskHistoryPage(
            caseId: widget.caseId,
            caseNo: caseNo,
            caseType: caseType,
          ),
          ViewDocsPage(
            caseId: widget.caseId,
            caseNo: caseNo,
          ),
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
