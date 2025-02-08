import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/advocate.dart';

class SharedPrefService {
  static const String _userKey = 'user';

  // Save Advocate object to SharedPreferences
  static Future<void> saveUser(Advocate user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userJson = jsonEncode(user.toJson());
    await prefs.setString(_userKey, userJson);
  }

  static Future<void> saveLastRefreshed(DateTime lastRefreshed) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastRefreshed', lastRefreshed.toIso8601String());
  }

  static Future<DateTime> getLastRefreshed() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastRefreshedString = prefs.getString('lastRefreshed');
    if (lastRefreshedString != null) {
      return DateTime.parse(lastRefreshedString);
    }
    return DateTime.now();
  }

  // Get Advocate object from SharedPreferences
  static Future<Advocate?> getUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString(_userKey);

    if (userJson != null) {
      Map<String, dynamic> userMap = jsonDecode(userJson);
      return Advocate.fromJson(userMap);
    }
    return null; // Return null if user is not found
  }

  // Remove user from SharedPreferences (logout)
  static Future<void> clearUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  // Check if the user is logged in (user exists in SharedPreferences)
  static Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userKey);
  }
}
