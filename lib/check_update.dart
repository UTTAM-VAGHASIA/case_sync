import 'dart:convert';

// import 'dart:io'; // Not strictly needed if using GetPlatform elsewhere or just for SystemNavigator

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // Import flutter_markdown
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckUpdate {
  // --- Configuration ---
  static const String githubOwner = "UT268"; // Your GitHub username/org
  static const String githubRepo = "case_sync"; // Your GitHub repo name
  static const String _githubPatKey = 'GITHUB_PAT'; // Key for --dart-define
  // --- End Configuration ---

  // --- IMPORTANT SECURITY WARNING ---
  // This code uses --dart-define to inject a GitHub PAT.
  // This PAT WILL BE EMBEDDED in your compiled app (APK/IPA).
  // It can be extracted by decompiling the app.
  // This is NOT recommended for tokens with wide permissions (like 'repo').
  // Consider using a backend proxy for better security if possible.
  // --- End Security Warning ---

  static const String githubApiUrl =
      "https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest";

  static Future<void> checkForUpdate(BuildContext context) async {
    String updateUrl = "";
    String latestVersion = "";
    bool forceUpdate = false;
    String releaseNotesBody = ""; // Variable to hold release notes

    const String githubPat =
        String.fromEnvironment(_githubPatKey, defaultValue: '');

    // Debug logging (Consider removing PAT presence log in production builds)
    if (githubPat.isNotEmpty) {
      print("GitHub PAT found via environment variable.");
    } else {
      print(
          "GitHub PAT NOT found via environment variable. Private repo access will likely fail.");
    }

    print("Checking for updates using GitHub Releases API: $githubApiUrl");

    try {
      final response = await http.get(
        Uri.parse(githubApiUrl),
        headers: {
          "Accept": "application/vnd.github.v3+json",
          if (githubPat.isNotEmpty) "Authorization": "Bearer $githubPat",
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final String tagName = data['tag_name'] ?? '';
        if (tagName.isEmpty) {
          /* ... error handling ... */ return;
        }
        print("Latest release tag: $tagName");

        // --- Extract Release Notes Body ---
        releaseNotesBody =
            data['body'] ?? 'No release notes provided.'; // Get the body
        // ---------------------------------

        latestVersion = /* ... derive latestVersion ... */
            (tagName.startsWith('v') ? tagName.substring(1) : tagName)
                .replaceAll('-force', '');
        forceUpdate = /* ... determine forceUpdate ... */
            tagName.endsWith('-force');
        final List<dynamic> assets = data['assets'] ?? [];
        String? apkDownloadUrl;
        for (var asset in assets) {
          /* ... find APK URL ... */
          final String? assetName = asset['name'];
          if (assetName != null && assetName.endsWith('.apk')) {
            apkDownloadUrl = asset['browser_download_url'];
            break;
          }
        }
        if (apkDownloadUrl == null) {
          /* ... error handling ... */ return;
        }
        updateUrl = apkDownloadUrl;

        print("Derived latest version: $latestVersion");
        print("Force update: $forceUpdate");
        print("Update URL: $updateUrl");
        // Optional: print("Release Notes: $releaseNotesBody"); // Careful if notes are long
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        print(
            "Client Error fetching update info: ${response.statusCode}. Check PAT, repo name, permissions, or internet connection.");
        print("Response body: ${response.body}");
        return;
      } else {
        print(
            "Server Error fetching update info from GitHub: ${response.statusCode}");
        print("Response body: ${response.body}");
        return;
      }
    } catch (e) {
      print("Error during update check: $e");
      return;
    }

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String currentVersion = packageInfo.version;
    print("Current app version: $currentVersion");

    // Consider using pub_semver for more robust comparison if needed:
    // final currentSemVer = Version.parse(currentVersion);
    // final latestSemVer = Version.parse(latestVersion);
    // if (latestSemVer > currentSemVer) { ... }
    if (latestVersion.isNotEmpty && currentVersion != latestVersion) {
      print("Update available. Showing dialog.");
      // --- Pass releaseNotesBody to the dialog ---
      showUpdateDialog(
          context, updateUrl, forceUpdate, latestVersion, releaseNotesBody);
      // -------------------------------------------
    } else {
      print("App is up to date or no new version found.");
    }
  }

  // Modified to accept and display release notes
  static void showUpdateDialog(
    BuildContext context,
    String updateUrl,
    bool forceUpdate,
    String latestVersion,
    String releaseNotesBody, // Added parameter for release notes
  ) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          // Use a SingleChildScrollView to prevent overflow if notes are long
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, // Align notes left
              children: [
                // --- Top Section (Icon, Title) ---
                Center(
                  // Center the top icon and title
                  child: Column(
                    children: [
                      Icon(Icons.system_update,
                          size: 50,
                          color: Colors.black), // Slightly smaller icon
                      SizedBox(height: 10),
                      Text(
                        "Update Available",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Version $latestVersion", // Show version clearly
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 15),

                // --- Release Notes Section ---
                Text(
                  "What's New:", // Section title for notes
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87),
                ),
                SizedBox(height: 8),
                // ConstrainedBox to limit the height of the markdown view
                // Adjust maxHeight as needed
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height *
                        0.3, // Limit to 30% of screen height
                  ),
                  // Use MarkdownBody to render the notes
                  child: MarkdownBody(
                    data: releaseNotesBody,
                    styleSheet: MarkdownStyleSheet(
                      // Optional: Customize markdown style
                      p: TextStyle(fontSize: 14, color: Colors.black87),
                      // Add other styles for h1, h2, list, etc. if needed
                    ),
                    selectable: true, // Allow selecting text in notes
                  ),
                ),
                SizedBox(height: 20),

                // --- Button Section ---
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
                            backgroundColor: Colors.grey[600],
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
                        onPressed: () async {
                          final Uri uri = Uri.parse(updateUrl);
                          if (!await launchUrl(uri,
                              mode: LaunchMode.externalApplication)) {
                            print('Could not launch $updateUrl');
                            // Optionally show a SnackBar error to the user
                            if (context.mounted) {
                              // Check if context is still valid
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Could not open update link.')),
                              );
                            }
                          }
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
          ),
        );
      },
    ).then((_) {
      if (forceUpdate && Navigator.canPop(context)) {
        // Check if dialog context is still valid
        // Improved check: Only exit if update is mandatory AND the dialog was dismissed (not by Update Now)
        // This logic is still imperfect for determined users, but better.
        print("Force update dialog dismissed, exiting app.");
        SystemNavigator.pop();
      }
    });
  }
}
