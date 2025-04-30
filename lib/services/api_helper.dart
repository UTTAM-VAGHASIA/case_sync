import 'package:case_sync/utils/flavor_config.dart';

/// A helper class that provides the base URL based on the current flavor
class ApiHelper {
  /// Get the base URL for API requests
  static String get baseUrl => FlavorConfig.instance.values.baseUrl;
  
  /// Get a complete URL by appending the endpoint to the base URL
  static String getUrl(String endpoint) {
    // Remove leading slash if present to avoid double slashes
    if (endpoint.startsWith('/')) {
      endpoint = endpoint.substring(1);
    }
    
    return '$baseUrl/$endpoint';
  }
  
  /// Print the current API environment for debugging
  static void logApiEnvironment() {
    final environment = FlavorConfig.isTest() ? 'TEST' : 'PRODUCTION';
    print('API Environment: $environment');
    print('Base URL: $baseUrl');
  }
} 