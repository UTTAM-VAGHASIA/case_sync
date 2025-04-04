import 'dart:io';

import 'package:case_sync/check_update.dart';
import 'package:case_sync/theme_data/app_theme.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'screens/splash_screen.dart';

void main() async {
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => CaseSyncApp(),
    ),
  );
}

class CaseSyncApp extends StatelessWidget {
  const CaseSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (GetPlatform.isAndroid || Platform.isAndroid) {
        CheckUpdate.checkForUpdate(context);
      }
    });
    return GetMaterialApp(
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}
