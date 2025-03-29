import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckUpdate {
  static const String apiUrl =
      "https://yourserver.com/version-check"; // API URL (to be added later)
  static const String versionInfoUrl =
      "https://drive.google.com/uc?export=download&id=1YkXxnidd8yfvjrMMo8fHjl2Ti6P03yFt"; // Google Drive JSON file ID

  static Future<Map<String, dynamic>?> getDriveFileVersion() async {
    try {
      final response = await http.get(Uri.parse(versionInfoUrl));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error fetching version info from Google Drive: $e");
    }
    return null;
  }

  static Future<void> checkForUpdate(BuildContext context) async {
    String updateUrl = "";
    String latestVersion = "";
    bool forceUpdate = false;

    try {
      final response =
          await http.get(Uri.parse(apiUrl)).timeout(Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        latestVersion = data["latest_version"];
        updateUrl = data["update_url"] ?? "";
        forceUpdate = data["force_update"] ?? false;
      }
    } catch (e) {
      print("API not available, checking Google Drive version.");
      final driveData = await getDriveFileVersion();
      if (driveData != null) {
        latestVersion = driveData["latest_version"] ?? "";
        updateUrl = driveData["update_url"] ?? "";
        forceUpdate = driveData["force_update"] ?? false;
      }
    }

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String currentVersion = packageInfo.version;

    print("Current version: $currentVersion");
    print("Latest version: $latestVersion");

    if (latestVersion.isNotEmpty && currentVersion != latestVersion) {
      showUpdateDialog(context, updateUrl, forceUpdate);
    }
  }

  static void showUpdateDialog(
      BuildContext context, String updateUrl, bool forceUpdate) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.system_update, size: 60, color: Colors.black),
              SizedBox(height: 10),
              Text(
                "Update Available",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "A new version of the app is available.\nPlease update to continue.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!forceUpdate)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text("Later"),
                      ),
                    ),
                  if (!forceUpdate) SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        launchUrl(Uri.parse(updateUrl));
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text("Update Now"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ).then((_) {
      if (forceUpdate) {
        SystemNavigator.pop(); // Close app if update is mandatory
      }
    });
  }
}
