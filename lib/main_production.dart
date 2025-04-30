import 'package:case_sync/theme_data/app_theme.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'screens/splash_screen.dart';
import 'utils/flavor_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set flavor configuration
  FlavorConfig(
    flavor: Flavor.production,
    values: FlavorValues(
      baseUrl: 'https://pragmanxt.com/case_sync_pro/services/admin/v1/index.php',
      appName: 'Advocates',
      showTestBanner: false,
    ),
  );
  
  runApp(
    DevicePreview(
      enabled: (!kReleaseMode && !GetPlatform.isIOS && !GetPlatform.isAndroid),
      builder: (context) => const CaseSyncApp(),
    ),
  );
}

class CaseSyncApp extends StatelessWidget {
  const CaseSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      debugShowCheckedModeBanner: false,
      title: FlavorConfig.instance.values.appName,
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
} 