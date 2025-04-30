import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum Flavor {
  production,
  staging
}

class FlavorValues {
  final String baseUrl;
  final String appName;
  final bool showTestBanner;
  
  FlavorValues({
    required this.baseUrl,
    required this.appName,
    this.showTestBanner = false,
  });
}

class FlavorConfig {
  final Flavor flavor;
  final FlavorValues values;
  static late FlavorConfig _instance;

  factory FlavorConfig({
    required Flavor flavor,
    required FlavorValues values,
  }) {
    _instance = FlavorConfig._internal(flavor, values);
    return _instance;
  }

  FlavorConfig._internal(this.flavor, this.values);

  static FlavorConfig get instance => _instance;

  static bool isProduction() => _instance.flavor == Flavor.production;
  static bool isTest() => _instance.flavor == Flavor.staging;

  static String get appSuffix {
    switch (_instance.flavor) {
      case Flavor.production:
        return '';
      case Flavor.staging:
        return '.test';
      default:
        return '';
    }
  }
  
  // Method to check for updates based on flavor
  static Future<String?> getUpdateCheckUrl() async {
    // Only for the test flavor, we use a special URL that won't show in GitHub releases
    if (isTest()) {
      // Get current version
      final packageInfo = await PackageInfo.fromPlatform();
      final version = packageInfo.version;
      
      // Return URL for test version check
      return 'https://raw.githubusercontent.com/${getRepoPath()}/test-versions/v$version/version.json';
    }
    
    // For production, null means use the normal GitHub releases
    return null;
  }
  
  // Helper to get repo path - make it public so it can be used elsewhere
  static String getRepoPath() {
    // Should match your GitHub repository path, e.g., "username/case_sync"
    return 'username/case_sync';
  }
} 