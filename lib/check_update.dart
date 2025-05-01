import 'dart:async'; // Required for Timer/Future.delayed, TimeoutException, Completer
import 'dart:convert'; // For JSON decoding
import 'dart:io'; // Required for File operations, Platform checks, HttpException, SocketException

import 'package:case_sync/utils/flavor_config.dart';
import 'package:case_sync/utils/snackbar_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Flutter framework
import 'package:flutter/services.dart'; // Required for SystemNavigator
import 'package:flutter_markdown/flutter_markdown.dart'; // Renders release notes as Markdown
import 'package:http/http.dart' as http; // For making network requests
import 'package:open_file_plus/open_file_plus.dart'; // To trigger APK install prompt
import 'package:package_info_plus/package_info_plus.dart'; // To get current app version
import 'package:path_provider/path_provider.dart'; // To get system directory paths (like cache)

/// Handles checking for application updates via GitHub Releases,
/// downloading the update package (APK), and prompting the user for installation.
class CheckUpdate {
  // --- Configuration ---
  // TODO: Replace with your actual GitHub username/org and repository name
  static const String githubOwner = "UT268"; // Your GitHub username or org
  static const String githubRepo = "case_sync"; // Your repository name
  static const String stagingBranch = "staging-versions"; // Branch for staging updates

  /// The key used with --dart-define to pass the GitHub Personal Access Token.
  /// Example build command:
  /// flutter build apk --release --dart-define=GITHUB_PAT=YOUR_TOKEN_HERE
  static const String _githubPatKey = 'GITHUB_PAT';

  /// The GitHub API endpoint for fetching the latest release information.
  static String get _githubApiUrl =>
      "https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest";
      
  /// The URL for checking staging updates
  static Future<String?> getStagingUpdateUrl() async {
    // For private repositories, we can't use raw.githubusercontent.com without authentication
    // Instead, use the GitHub API to get the file content
    return 'https://api.github.com/repos/$githubOwner/$githubRepo/contents/staging-versions/latest/version.json?ref=$stagingBranch';
  }

  // --- Security Warning ---
  // Storing PAT via --dart-define is convenient but NOT secure for production apps
  // with sensitive PATs. It can be extracted from the app package.
  // For higher security, consider using a backend proxy service to handle
  // GitHub API requests and authentication.
  // --- End Warning ---

  /// Checks for updates via GitHub Releases. Should be called early in app startup.
  ///
  /// Requires a [BuildContext] to show dialogs.
  /// Returns `true` to indicate the app can proceed with normal startup,
  /// or `false` if a mandatory update requires the app to halt (or exit).
  static Future<bool> checkForUpdate(BuildContext context) async {
    // Check if we're in staging or production flavor
    final isStaging = FlavorConfig.isTest();
    
    if (isStaging) {
      print("CheckUpdate: Using staging update check flow");
      return await _checkForStagingUpdate(context);
    } else {
      print("CheckUpdate: Using production update check flow");
      return await _checkForProductionUpdate(context);
    }
  }
  
  /// Checks for updates in staging flavor
  static Future<bool> _checkForStagingUpdate(BuildContext context) async {
    String latestVersion = "";
    bool forceUpdate = false;
    String apkUrl = "";
    
    try {
      // Get the staging version check URL
      final versionJsonUrl = await getStagingUpdateUrl();
      if (versionJsonUrl == null) {
        print("CheckUpdate: Staging version URL is null, skipping update check");
        return true;
      }
      
      print("CheckUpdate: Checking for staging updates at $versionJsonUrl");
      
      // Retrieve the GitHub PAT from dart-define environment variables
      const String githubPat = String.fromEnvironment(_githubPatKey, defaultValue: '');
      
      // Fetch the version.json file using the GitHub API
      final response = await http.get(
        Uri.parse(versionJsonUrl),
        headers: {
          "Accept": "application/vnd.github.v3+json",
          // Include Authorization header for private repositories
          if (githubPat.isNotEmpty) "Authorization": "Bearer $githubPat",
        },
      ).timeout(const Duration(seconds: 20));
      
      if (response.statusCode == 200) {
        // GitHub API returns file content in a different format
        final apiResponse = jsonDecode(response.body);
        
        // For files, GitHub API returns the content as base64 encoded
        if (apiResponse['content'] != null && apiResponse['encoding'] == 'base64') {
          // Decode the base64 content
          final String base64Content = apiResponse['content'].replaceAll('\n', '');
          final String jsonContent = utf8.decode(base64Decode(base64Content));
          
          // Parse the JSON content
          final data = jsonDecode(jsonContent);
          
          // Extract version info
          latestVersion = data['version'] ?? '';
          apkUrl = data['apk_url'] ?? '';
          forceUpdate = data['force_update'] ?? false;
          
          if (latestVersion.isEmpty || apkUrl.isEmpty) {
            print("CheckUpdate: Invalid staging version data");
            return true;
          }
          
          print("CheckUpdate: Staging release version: $latestVersion, Force update: $forceUpdate");
        } else {
          print("CheckUpdate: Unexpected GitHub API response format");
          return true;
        }
      } else {
        // Could be a 404 if the version.json doesn't exist yet
        print("CheckUpdate: Staging version check failed with status ${response.statusCode}");
        if (response.statusCode == 404) {
          print("CheckUpdate: Make sure the file exists at staging-versions/latest/version.json in your repository");
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          print("CheckUpdate: Authentication failed. Make sure your GitHub PAT has the correct permissions");
        }
        return true;
      }
    } catch (e) {
      // If the file doesn't exist or there's a network error, just continue
      print("CheckUpdate: Error checking for staging updates: $e");
      return true;
    }
    
    // Compare versions
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String currentVersion = packageInfo.version;
    print("CheckUpdate: Current app version: $currentVersion");
    
    if (latestVersion.isNotEmpty && _isNewerVersion(latestVersion, currentVersion)) {
      print("CheckUpdate: Staging update available from $currentVersion to $latestVersion");
      
      // Show the update dialog
      final shouldProceed = await _showStagingUpdateDialog(
        context,
        latestVersion,
        apkUrl,
        forceUpdate
      );
      
      return shouldProceed;
    }
    
    return true;
  }
  
  /// Shows a dialog for staging updates
  static Future<bool> _showStagingUpdateDialog(
    BuildContext context, 
    String version, 
    String apkUrl,
    bool forceUpdate
  ) async {
    final completer = Completer<bool>();
    
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (context) => WillPopScope(
        onWillPop: () async => !forceUpdate,
        child: AlertDialog(
          title: Text(forceUpdate ? 'Required Update' : 'Update Available'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A new version (v$version) is available.',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                if (forceUpdate)
                  const Text(
                    'This update is required to continue using the app.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  )
              ],
            ),
          ),
          actions: [
            if (!forceUpdate)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  completer.complete(true);
                },
                child: const Text('Later'),
              ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Start the download process
                  await _downloadAndInstallUpdate(
                    context,
                    apkUrl,
                    'Staging',
                  );
                  
                  if (!completer.isCompleted) {
                    completer.complete(!forceUpdate);
                  }
                } catch (e) {
                  print("CheckUpdate: Error during staging update: $e");
                  if (!completer.isCompleted) {
                    completer.complete(!forceUpdate);
                  }
                }
              },
              child: const Text('Update Now'),
            ),
          ],
        ),
      ),
    );
    
    return completer.future;
  }
  
  /// Checks for updates using the production GitHub releases
  static Future<bool> _checkForProductionUpdate(BuildContext context) async {
    String? assetApiUrl;
    String latestVersion = "";
    bool forceUpdate = false;
    String releaseNotesBody = "No release notes available.";

    // Retrieve the GitHub PAT from dart-define environment variables
    const String githubPat =
        String.fromEnvironment(_githubPatKey, defaultValue: '');

    // --- PAT Handling & Logging ---
    if (githubPat.isEmpty && !_isPublicRepo()) {
      // Heuristic check if repo is likely private
      if (!kReleaseMode) {
        SnackBarUtils.showErrorSnackBar(
          context,
          "GitHub PAT not found. Update check may fail due to missing authentication.",
        );
      }
      return true; // Fail open - allow app to run
    } else if (githubPat.isNotEmpty) {
      if (!kReleaseMode) {
        SnackBarUtils.showInfoSnackBar(
          context,
          "GitHub PAT found. Using for API requests.",
        );
      }
    }

    print("CheckUpdate: Checking for updates at $_githubApiUrl");

    // --- Fetch Latest Release Info ---
    try {
      final response = await http.get(
        Uri.parse(_githubApiUrl),
        headers: {
          "Accept": "application/vnd.github.v3+json",
          // Only include the Authorization header if a PAT is available
          if (githubPat.isNotEmpty) "Authorization": "Bearer $githubPat",
        },
      ).timeout(
          const Duration(seconds: 20)); // Network timeout for the API call

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Extract tag name (required)
        final String tagName = data['tag_name'] ?? '';
        if (tagName.isEmpty) {
          SnackBarUtils.showErrorSnackBar(
            context,
            "Error: Cannot determine latest version. Tag name missing in response.",
          );
          return true; // Proceed with app startup if tag is missing
        }
        print("CheckUpdate: Latest release tag found: $tagName");

        // Extract release notes
        releaseNotesBody = data['body'] ?? 'No release notes available.';

        // Extract and clean version number from tag (e.g., "v1.2.3-beta" -> "1.2.3")
        latestVersion =
            (tagName.startsWith('v') ? tagName.substring(1) : tagName)
                    .split('-')[
                0]; // Remove 'v' prefix and suffixes like '-beta', '-force'

        // Determine if update is mandatory (simple check for suffix)
        forceUpdate = tagName.toLowerCase().endsWith('-force');

        // Find the APK asset URL within the release assets
        final List<dynamic> assets = data['assets'] ?? [];
        for (var asset in assets) {
          final String? assetName = asset['name'];
          // Ensure the asset has a name and ends with '.apk' (case-insensitive)
          if (assetName != null && assetName.toLowerCase().endsWith('.apk')) {
            // Use 'url' for the API asset endpoint, not 'browser_download_url' directly here
            // as we need headers (like Authorization) for the download request.
            assetApiUrl = asset['url'];
            print(
                "CheckUpdate: Found APK asset: $assetName, API URL: $assetApiUrl");
            break; // Found the first APK, stop searching
          }
        }

        // Handle case where no APK asset was found in the release
        if (assetApiUrl == null) {
          SnackBarUtils.showErrorSnackBar(
            context,
            "Error: No APK found in latest release. Cannot perform update.",
          );
          return true; // Proceed with app startup if APK is missing
        }

        print(
            "CheckUpdate: Derived Version: $latestVersion, Force Update: $forceUpdate");
      } else {
        // Handle non-200 HTTP status codes from GitHub API
        print(
            "CheckUpdate: Error fetching update info. Status: ${response.statusCode}, Body: ${response.body}");
        // Provide hints for common errors
        if (response.statusCode == 401) {
          print(
              "CheckUpdate: Hint: GitHub API returned 401 Unauthorized. Check if the GitHub PAT is valid and has the necessary scope (e.g., 'repo' for private repositories).");
        } else if (response.statusCode == 403) {
          print(
              "CheckUpdate: Hint: GitHub API returned 403 Forbidden. This might be due to API rate limiting or the PAT missing required permissions.");
        } else if (response.statusCode == 404) {
          print(
              "CheckUpdate: Hint: GitHub API returned 404 Not Found. Check if the 'githubOwner' ($githubOwner) and 'githubRepo' ($githubRepo) are correct.");
        }
        return true; // Proceed with app startup on API errors (fail open)
      }
    } catch (e) {
      // Handle network exceptions (timeouts, socket errors, etc.)
      print("CheckUpdate: Exception during update check: $e");
      if (e is TimeoutException) {
        print(
            "CheckUpdate: Hint: Network connection timed out while fetching release info.");
      } else if (e is SocketException) {
        print(
            "CheckUpdate: Hint: Network connection error (e.g., no internet, DNS issue).");
      } else if (e is FormatException) {
        print(
            "CheckUpdate: Hint: Failed to parse JSON response from GitHub API.");
      }
      return true; // Proceed with app startup on exceptions (fail open)
    }

    // --- Compare Versions ---
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String currentVersion = packageInfo.version;
    print("CheckUpdate: Current app version: $currentVersion");

    // Use the helper function to compare versions
    if (latestVersion.isNotEmpty &&
        _isNewerVersion(latestVersion, currentVersion)) {
      print(
          "CheckUpdate: Update available (Current: $currentVersion -> Latest: $latestVersion). Showing update dialog.");

      // Show the update dialog and wait for it to be dismissed.
      // The dialog handles the download and install initiation.
      await showUpdateDialog(
        context,
        assetApiUrl, // Known to be non-null if we reached here
        forceUpdate,
        latestVersion,
        releaseNotesBody,
        githubPat, // Pass PAT for authenticated download if needed
      );

      // --- Handle Mandatory Update ---
      // If the update is mandatory, the dialog's PopScope or the user action
      // might have already exited the app.
      // If we reach here after the dialog is dismissed (e.g., user pressed "Later"),
      // we block further app startup *only* if the update was mandatory.
      if (forceUpdate) {
        print(
            "CheckUpdate: Mandatory update flow finished. Preventing further app startup.");
        // Optionally, ensure exit if somehow the dialog didn't handle it
        // SystemNavigator.pop();
        return false; // Block startup
      } else {
        print(
            "CheckUpdate: Optional update dialog dismissed. Proceeding with app startup.");
        return true; // Allow startup for optional updates or if update was installed
      }
    } else {
      // No newer version found or versions couldn't be compared reliably
      print(
          "CheckUpdate: App is up to date (Current: $currentVersion, Latest: $latestVersion) or no valid newer version identified.");
      return true; // Proceed with normal app startup
    }
  }

  /// Simple version comparison. Returns true if `latestVersion` is newer than `currentVersion`.
  /// Assumes versions like "1.2.3". Not fully SemVer compliant.
  /// Consider using the `pub_semver` package for robust Semantic Versioning comparison.
  static bool _isNewerVersion(String latestVersion, String currentVersion) {
    try {
      // Split versions into components
      List<int> latestParts = latestVersion.split('.').map(int.parse).toList();
      List<int> currentParts =
          currentVersion.split('.').map(int.parse).toList();

      // Compare parts numerically
      int len = latestParts.length > currentParts.length
          ? latestParts.length
          : currentParts.length;
      for (int i = 0; i < len; i++) {
        int latestPart = (i < latestParts.length)
            ? latestParts[i]
            : 0; // Pad with 0 if shorter
        int currentPart = (i < currentParts.length)
            ? currentParts[i]
            : 0; // Pad with 0 if shorter

        if (latestPart > currentPart) return true;
        if (latestPart < currentPart) return false;
      }
      // Versions are identical
      return false;
    } catch (e) {
      // Error parsing version strings (e.g., non-numeric parts)
      print(
          "CheckUpdate: Error comparing versions '$latestVersion' and '$currentVersion': $e");
      // Fallback: Treat parse errors as not newer to avoid unnecessary update prompts.
      return false;
    }
  }

  /// Heuristic check if the repo *might* be public.
  /// This is only used for a console warning message if PAT is missing.
  /// It's generally safer to assume a repository is private if you intend to use a PAT.
  static bool _isPublicRepo() {
    // Basic heuristic: Assume private by default if PAT usage is intended.
    // You could add specific owner/repo names known to be public if desired.
    // Example: if (githubOwner == 'flutter' && githubRepo == 'flutter') return true;
    return false; // Default to assuming private for the warning logic
  }

  // =========================================================================
  // ================== UI: showUpdateDialog (Modern B&W) ====================
  // =========================================================================

  /// Displays the update dialog with download/install functionality (Modern B&W Theme).
  static Future<void> showUpdateDialog(
    BuildContext context,
    String assetApiUrl,
    bool forceUpdate,
    String latestVersion,
    String releaseNotesBody,
    String githubPat, // PAT needed for downloading the asset
  ) async {
    // State variables managed by StatefulBuilder for dialog UI updates
    double? downloadProgress; // Null=indeterminate, 0.0-1.0=determinate
    bool isDownloading = false;
    String? downloadError;
    String? downloadedFilePath;

    // Use await to pause execution until the dialog is dismissed
    await showDialog<void>(
      context: context,
      // Prevent dismissing by tapping outside if update is forced or download in progress
      barrierDismissible: !forceUpdate && !isDownloading,
      builder: (BuildContext dialogContext) {
        // StatefulBuilder allows the dialog's content to rebuild when state changes
        return StatefulBuilder(
          builder: (stfContext, stfSetState) {
            // Helper to safely update dialog state only if it's still mounted
            void setDialogState(Function() fn) {
              if (stfContext.mounted) {
                stfSetState(fn);
              }
            }

            // --- Theme Colors (Derived for B&W aesthetic) ---
            final Color surfaceColor =
                Theme.of(stfContext).colorScheme.surface; // Dialog background
            final Color onSurfaceColor = Theme.of(stfContext)
                .colorScheme
                .onSurface; // Primary text/icons
            final Color onSurfaceVariantColor =
                onSurfaceColor.withValues(alpha: 0.65); // Secondary/muted text
            final Color disabledColor =
                Colors.grey.shade300; // Disabled elements background
            final Color disabledTextColor =
                onSurfaceColor.withValues(alpha: 0.4); // Disabled text
            final Color primaryButtonColor =
                Colors.black87; // Primary button background
            final Color buttonTextColor =
                Colors.white; // Text on primary button
            final Color progressBackgroundColor =
                Colors.grey.shade200; // Progress bar background
            final Color progressIndicatorColor =
                Colors.black87; // Progress bar indicator

            // --- Dialog Structure ---
            return PopScope(
              // Handle back button press / system pop gesture
              canPop: !forceUpdate && !isDownloading,
              // Allow pop only if not forced and not downloading
              onPopInvokedWithResult: (didPop, _) {
                if (didPop) return; // Already popped (e.g., by "Later" button)

                // If pop was attempted but prevented (e.g., back button on forced update)
                if (forceUpdate &&
                    !isDownloading &&
                    downloadedFilePath == null) {
                  // If update is mandatory, not downloading, not finished, and user tried to dismiss
                  print(
                      "CheckUpdate: Mandatory update dialog dismissed via back button/gesture. Exiting app.");
                  SystemNavigator.pop(); // Exit the application
                }
                // If pop was attempted but prevented because download was in progress, do nothing.
                // If pop was allowed (!forceUpdate && !isDownloading), Navigator.pop() will be called below.
                else if (!isDownloading && !forceUpdate) {
                  // Should have been handled by canPop=true, but as a safeguard:
                  if (Navigator.of(dialogContext).canPop()) {
                    Navigator.of(dialogContext).pop();
                  }
                }
              },
              child: AlertDialog(
                backgroundColor: surfaceColor,
                elevation: 6.0,
                // Moderate elevation
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0) // Rounded corners
                    ),
                titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 12.0),
                contentPadding:
                    const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 16.0),
                actionsPadding:
                    const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 16.0),
                // Provide space for actions

                // --- Dialog Title ---
                title: Center(
                  child: Column(
                    children: [
                      Icon(Icons.system_update_alt,
                          size: 40,
                          color: onSurfaceColor.withValues(alpha: 0.8)),
                      SizedBox(height: 16),
                      Text("Update Available",
                          textAlign: TextAlign.center,
                          style: Theme.of(stfContext)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                  color: onSurfaceColor,
                                  fontWeight: FontWeight.w600)),
                      SizedBox(height: 6),
                      Text("Version $latestVersion",
                          textAlign: TextAlign.center,
                          style: Theme.of(stfContext)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  color: onSurfaceVariantColor,
                                  fontWeight: FontWeight.normal)),
                    ],
                  ),
                ),

                // --- Dialog Content ---
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- What's New Section ---
                    Divider(height: 24, thickness: 1, color: Colors.grey[300]),
                    Text("What's New:",
                        style: Theme.of(stfContext)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: onSurfaceColor)),
                    SizedBox(height: 10),
                    
                    // --- Release Notes (Markdown) in a fixed-height scrollable container ---
                    Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      height: MediaQuery.of(stfContext).size.height * 0.2, // Fixed height
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Material(
                            // Required for selectable text background/gestures
                            color: surfaceColor,
                            child: MarkdownBody(
                              data: releaseNotesBody.isEmpty
                                  ? "*No release notes provided.*"
                                  : releaseNotesBody,
                              selectable: true, // Allow text selection
                              styleSheet: MarkdownStyleSheet.fromTheme(
                                      Theme.of(stfContext))
                                  .copyWith(
                                p: Theme.of(stfContext)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        fontSize: 14,
                                        color: onSurfaceColor.withValues(
                                            alpha: 0.85),
                                        height: 1.4),
                                listBullet: Theme.of(stfContext)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: onSurfaceColor.withValues(
                                            alpha: 0.85)),
                                // Add styles for h1, h2, code, etc. if needed for your markdown
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // --- Download/Install Status Section ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      margin: const EdgeInsets.only(top: 8.0),
                      child: AnimatedSwitcher(
                        // Smoothly transition between states
                        duration: const Duration(milliseconds: 300),
                        child: _buildStatusSection(
                          // Use helper widget
                          stfContext,
                          isDownloading,
                          downloadProgress,
                          downloadError,
                          downloadedFilePath,
                          () => _installApk(downloadedFilePath!, stfContext),
                          // Install action callback
                          // Pass theme colors:
                          onSurfaceColor,
                          onSurfaceVariantColor,
                          progressBackgroundColor,
                          progressIndicatorColor,
                          primaryButtonColor,
                          buttonTextColor,
                          disabledTextColor, // Pass disabled text color
                        ),
                      ),
                    ),
                  ],
                ),

                // --- Dialog Action Buttons ---
                actions: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    // Align buttons to the right
                    children: [
                      // "Later" button: Shows only if update is optional AND not downloading/finished/errored
                      if (!forceUpdate &&
                          !isDownloading &&
                          downloadedFilePath == null &&
                          downloadError == null)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              // Dismiss dialog
                              style: TextButton.styleFrom(
                                foregroundColor: onSurfaceVariantColor,
                                // Muted color for secondary action
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 10.0),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0)),
                              ),
                              child: Text("Later"),
                            ),
                          ),
                        ),

                      // Main action button: "Update Now" / "Retry" / "Downloading..." / (Disabled "Downloaded")
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDownloading ||
                                    downloadedFilePath != null
                                ? disabledColor // Greyed out if downloading or complete
                                : primaryButtonColor,
                            // Dark primary color
                            foregroundColor: isDownloading ||
                                    downloadedFilePath != null
                                ? disabledTextColor // Muted text when disabled
                                : buttonTextColor,
                            // White text on primary button
                            disabledBackgroundColor: disabledColor,
                            // Explicit disabled background
                            disabledForegroundColor: disabledTextColor,
                            // Explicit disabled text color
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 12.0),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  12.0), // Match dialog/other elements
                            ),
                          ),
                          // Disable button while downloading or if download is complete
                          // (the "Install Now" button in the status section takes over)
                          onPressed: isDownloading || downloadedFilePath != null
                              ? null // Button is disabled
                              : () {
                                  // Action: Start or Retry Download
                                  _startDownload(
                                    stfContext,
                                    // Pass context for potential UI feedback (though not used currently)
                                    setDialogState,
                                    // Crucial: Function to update the dialog's UI state
                                    assetApiUrl,
                                    latestVersion,
                                    githubPat,
                                    // Callbacks to update dialog state variables:
                                    onProgress: (progress) => setDialogState(
                                        () => downloadProgress = progress),
                                    onError: (error) => setDialogState(
                                        () => downloadError = error),
                                    onComplete: (path) => setDialogState(
                                        () => downloadedFilePath = path),
                                    onDownloadingStateChange: (downloading) =>
                                        setDialogState(
                                            () => isDownloading = downloading),
                                  );
                                },
                          // Dynamically set button text based on state
                          child: Text(
                            isDownloading
                                ? "Downloading..."
                                : downloadError != null
                                    ? "Retry Download"
                                    : downloadedFilePath != null
                                        ? "Downloaded" // Button inactive; Install button shown elsewhere
                                        : "Update Now",
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    ); // showDialog Completes Here

    // --- Post-Dialog Logic ---
    // Handled by the return value of checkForUpdate based on forceUpdate flag
    // and whether the dialog was dismissed or resulted in an exit.
  }

  // =========================================================================
  // ============= UI HELPER: _buildStatusSection (Modern B&W) ===============
  // =========================================================================

  /// Builds the dynamic section showing download progress, errors, or the install button.
  /// Includes the `Expanded` widget within the error state's `Row`.
  static Widget _buildStatusSection(
    BuildContext context,
    bool isDownloading,
    double? downloadProgress,
    String? downloadError,
    String? downloadedFilePath,
    VoidCallback onInstallPressed,
    // Theme colors passed from showUpdateDialog:
    Color onSurfaceColor,
    Color onSurfaceVariantColor,
    Color progressBackgroundColor,
    Color progressIndicatorColor,
    Color primaryButtonColor,
    Color buttonTextColor,
    Color disabledTextColor, // Added for consistency
  ) {
    // Unique keys help AnimatedSwitcher differentiate between states
    if (isDownloading) {
      // --- Downloading State ---
      return Container(
        key: ValueKey('downloading'),
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            Text(
                downloadError ==
                        null // Show specific retry message if applicable
                    ? "Downloading update..."
                    : downloadError.startsWith("Download failed. Retrying")
                        ? downloadError // Show the retry message set by _startDownload
                        : "Downloading update...", // Default text
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: onSurfaceVariantColor // Muted color for status text
                    )),
            SizedBox.shrink(),
            LinearProgressIndicator(
              value: downloadProgress,
              // Null value shows indeterminate animation
              backgroundColor: progressBackgroundColor,
              valueColor: AlwaysStoppedAnimation<Color>(progressIndicatorColor),
              minHeight: 6,
              // Make the bar slightly thicker
              borderRadius: BorderRadius.circular(3), // Rounded ends
            ),
            SizedBox.shrink(),
            // Show percentage only if progress is determinate
            if (downloadProgress != null)
              Text("${(downloadProgress * 100).toStringAsFixed(0)}%",
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: onSurfaceVariantColor)),
            SizedBox.shrink(),
          ],
        ),
      );
    } else if (downloadedFilePath != null) {
      // --- Download Complete State ---
      return Center(
        // Center the content for this state
        key: ValueKey('complete'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            children: [
              Icon(Icons.check_circle_outline,
                  color: progressIndicatorColor,
                  size: 32), // Clear success icon
              SizedBox(height: 8),
              Text("Download complete!",
                  style: TextStyle(
                      color: onSurfaceColor, fontWeight: FontWeight.w500)),
              SizedBox(height: 16),
              // "Install Now" button appears here when download finishes
              ElevatedButton.icon(
                icon: Icon(Icons.install_mobile,
                    size: 18, color: buttonTextColor),
                label: Text("Install Now"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryButtonColor,
                  // Use primary color for install action
                  foregroundColor: buttonTextColor,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                  textStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12.0)), // Consistent shape
                ),
                onPressed: onInstallPressed, // Trigger the _installApk function
              ),
            ],
          ),
        ),
      );
    } else if (downloadError != null) {
      // --- Error State ---
      return Container(
        key: ValueKey('error'),
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        // More padding for error block
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          // Subtle background to highlight the error area
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          // Layout icon and text horizontally
          crossAxisAlignment: CrossAxisAlignment.start,
          // Align icon and text top
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0, top: 2.0),
              child: Icon(Icons.error_outline,
                  color: onSurfaceColor.withValues(alpha: 0.7),
                  size: 20), // Muted error icon
            ),
            // Use Expanded to allow error text to take remaining width and wrap
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Download Failed",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: onSurfaceColor,
                          // Standard text color, icon indicates error
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  // The actual error message from _startDownload
                  Text(downloadError,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: onSurfaceVariantColor,
                          // Muted color for details
                          height: 1.3 // Improve line spacing for readability
                          )),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // --- Idle State (before download starts) ---
      // No status needs to be shown initially
      return SizedBox.shrink(key: ValueKey('idle'));
    }
  }

  // =========================================================================
  // ==================== Core Logic: Download & Install =====================
  // =========================================================================

  /// Handles the APK download process from GitHub Releases asset URL.
  /// Includes retries, progress reporting, and state updates via callbacks.
  static Future<void> _startDownload(
    BuildContext context,
    // Keep for potential future use (e.g., Snackbars)
    StateSetter setState, // Function to update the dialog's UI state
    String assetApiUrl,
    // The API URL for the asset (requires auth header for private)
    String latestVersion, // Used for filename generation
    String githubPat, // The GitHub PAT for authentication
    // Callbacks to update state variables in the dialog:
    {
    required Function(double?)
        onProgress, // Reports download progress (null=indeterminate)
    required Function(String) onError, // Reports error messages
    required Function(String) onComplete, // Reports success with file path
    required Function(bool)
        onDownloadingStateChange, // Reports if download is active
  }) async {
    // --- Initial State Setup ---
    onDownloadingStateChange(true); // Signal download start
    onError(''); // Clear any previous error messages
    onProgress(null); // Set progress to indeterminate initially
    setState(() {}); // Update dialog UI immediately to show "Downloading..."

    // --- Permissions (Android Specific - handled by open_file_plus/installer) ---
    // Modern Android versions handle install permissions via the installer prompt.
    // `requestLegacyExternalStorage` might be needed for older Android versions
    // if saving outside cache, but saving to cache is generally preferred.

    // --- Prepare for Download ---
    File? downloadedFile; // Holds the file object
    String targetFilePath = ''; // Path where the APK will be saved

    try {
      final directory =
          await getApplicationCacheDirectory(); // Use app's cache directory
      String apkFileName = "app-update-v$latestVersion.apk"; // Default filename

      // Attempt to create a more specific filename (optional)
      try {
        final uri = Uri.parse(assetApiUrl);
        // Example: Extract filename from the end of the API URL path if it ends with .apk
        if (uri.pathSegments.isNotEmpty &&
            uri.pathSegments.last.toLowerCase().endsWith('.apk')) {
          // Basic sanitization: Replace characters not suitable for filenames
          apkFileName =
              uri.pathSegments.last.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
        }
      } catch (e) {
        print(
            "CheckUpdate: Warning - Could not parse filename from asset URL ($assetApiUrl): $e. Using default: $apkFileName");
      }

      targetFilePath = '${directory.path}/$apkFileName';
      downloadedFile = File(targetFilePath);

      print("CheckUpdate: Target download path: $targetFilePath");
    } catch (e) {
      print(
          "CheckUpdate: Error getting cache directory or creating file object: $e");
      onError("Failed to prepare download location.");
      onDownloadingStateChange(false);
      setState(() {}); // Update UI
      return;
    }

    // --- Download Retry Loop ---
    const int maxRetries = 2; // Number of retries (total 3 attempts)
    const Duration retryDelay = Duration(seconds: 5); // Delay between retries

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      http.Client? client; // Create a new client for each attempt
      IOSink? sink; // File writer stream

      try {
        // --- Pre-Attempt Cleanup & UI Update ---
        if (attempt > 0) {
          // If retrying, delete potentially incomplete file from previous attempt
          if (await downloadedFile.exists()) {
            print(
                "CheckUpdate: Deleting potentially partial file before retry: $targetFilePath");
            try {
              await downloadedFile.delete();
            } catch (e) {
              print(
                  "CheckUpdate: Warning - Failed to delete partial file before retry: $e");
            }
          }
          // Update UI to show retry attempt message
          print(
              "CheckUpdate: Download attempt ${attempt + 1} failed. Retrying in $retryDelay...");
          onError(
              "Download failed. Retrying (${attempt + 1}/${maxRetries + 1})...");
          onProgress(null); // Reset progress visually for retry
          setState(() {}); // Update dialog UI
          await Future.delayed(retryDelay); // Wait before next attempt
          onError(''); // Clear retry message before starting new attempt
          setState(() {});
        } else {
          // First attempt, ensure progress is indeterminate and no error message
          onError('');
          onProgress(null);
          setState(() {});
        }

        print(
            "CheckUpdate: Starting download attempt ${attempt + 1}/${maxRetries + 1}...");

        // --- Make HTTP Request ---
        client = http.Client();
        final request = http.Request('GET', Uri.parse(assetApiUrl));
        // Crucial headers for GitHub asset download:
        request.headers['Accept'] =
            'application/octet-stream'; // Request binary file data
        if (githubPat.isNotEmpty) {
          request.headers['Authorization'] =
              'Bearer $githubPat'; // Authentication for private repos
        }

        // Send the request and get the streamed response
        final response = await client.send(request).timeout(
              const Duration(seconds: 30),
              // Timeout for establishing connection & getting headers
              onTimeout: () => throw TimeoutException(
                  'Connection timed out while initiating download.'),
            );

        // --- Handle Response ---
        if (response.statusCode == 200) {
          // Success: Start streaming the download
          final totalBytes =
              response.contentLength ?? -1; // Get total size if available
          int receivedBytes = 0;
          sink = downloadedFile.openWrite(); // Open file sink
          final completer =
              Completer<void>(); // To signal stream completion/error
          late StreamSubscription<List<int>>
              subscription; // To manage the stream listener

          // Download stream timeout (long duration for inactivity between chunks)
          const Duration streamTimeoutDuration = Duration(minutes: 3);
          Timer? inactivityTimer;

          void resetInactivityTimer() {
            inactivityTimer?.cancel();
            inactivityTimer = Timer(streamTimeoutDuration, () {
              print(
                  "CheckUpdate: Download stream timed out due to inactivity.");
              subscription.cancel(); // Cancel the stream subscription
              if (!completer.isCompleted) {
                completer.completeError(TimeoutException(
                    'Download timed out due to inactivity (no data received for ${streamTimeoutDuration.inSeconds} seconds).'));
              }
            });
          }

          subscription = response.stream.listen(
            (chunk) {
              if (completer.isCompleted)
                return; // Avoid processing after completion/error
              try {
                resetInactivityTimer(); // Reset timer on receiving data
                sink?.add(chunk); // Write chunk to file
                receivedBytes += chunk.length;
                if (totalBytes > 0) {
                  // Calculate and report determinate progress
                  final progress = (receivedBytes / totalBytes).clamp(0.0, 1.0);
                  onProgress(progress);
                } else {
                  // Total size unknown, report indeterminate progress
                  onProgress(null);
                }
                setState(() {}); // Update UI with progress
              } catch (e) {
                // Error during chunk processing or writing
                if (!completer.isCompleted) completer.completeError(e);
              }
            },
            onDone: () {
              // Stream finished successfully
              inactivityTimer?.cancel();
              if (!completer.isCompleted) completer.complete();
            },
            onError: (e) {
              // Error occurred in the stream itself
              inactivityTimer?.cancel();
              if (!completer.isCompleted) completer.completeError(e);
            },
            cancelOnError: true, // Cancel subscription automatically on error
          );

          // Wait for the stream completer to finish (or timeout)
          await completer.future; // Throws if completer finishes with an error

          // --- Download Completion ---
          await sink.flush();
          await sink.close(); // Ensure file is fully written and closed
          sink = null; // Clear sink variable

          print(
              "CheckUpdate: Download successful: $targetFilePath ($receivedBytes bytes)");
          onError(''); // Clear any lingering error/retry messages
          onComplete(targetFilePath); // Signal success with the file path
          onDownloadingStateChange(false); // Signal download end
          setState(() {}); // Update UI to show "Complete" / "Install"
          client.close(); // Close the client
          return; // Exit retry loop successfully
        } else {
          // Handle non-200 status codes for this download attempt
          final body = await response.stream
              .bytesToString()
              .catchError((_) => "<Failed to read response body>");
          client.close(); // Close client before throwing
          // Throw specific error for non-200 status
          throw HttpException(
              'Download attempt ${attempt + 1} failed with Status ${response.statusCode}. '
              '${response.reasonPhrase ?? ""}. Body: ${body.substring(0, body.length > 500 ? 500 : body.length)}',
              // Limit body length in error
              uri: Uri.parse(assetApiUrl));
        }
      } catch (e) {
        // --- Handle Exceptions During Download Attempt ---
        print("CheckUpdate: Download exception (Attempt ${attempt + 1}): $e");
        await sink?.close().catchError(
            (_) {}); // Attempt to close sink on error, ignore errors
        sink = null;
        client?.close(); // Ensure client is closed

        // Check if this was the last attempt
        if (attempt == maxRetries) {
          // Final attempt failed, report definitive error
          String errorMsg =
              "Download failed after ${maxRetries + 1} attempts.\n";
          if (e is TimeoutException) {
            errorMsg +=
                "Reason: ${e.message ?? 'Timed out'}. Check network connection.";
          } else if (e is SocketException) {
            errorMsg +=
                "Reason: Network error (${e.osError?.message ?? e.message}). Check connection.";
          } else if (e is HttpException) {
            // Try to provide a cleaner message from HttpException
            String httpError = e.message;
            // Avoid showing giant HTML bodies or JSON structures in the UI
            if (httpError.contains('<html>')) {
              httpError = httpError.substring(0, httpError.indexOf('<html>'));
            }
            if (httpError.contains('{')) {
              httpError = httpError.substring(0, httpError.indexOf('{'));
            }
            errorMsg += "Reason: Server error (${httpError.trim()}).";
          } else {
            errorMsg +=
                "Reason: Unexpected error (${e.runtimeType}). See logs for details.";
            // Consider logging the full e.toString() for debugging
            print("CheckUpdate: Full error details: ${e.toString()}");
          }

          onError(errorMsg); // Set final error message
          onDownloadingStateChange(false); // Signal download end (failed)
          setState(() {}); // Update UI to show final error

          // Attempt to clean up the potentially corrupted file on final failure
          try {
            if (await downloadedFile.exists()) {
              await downloadedFile.delete();
              print(
                  "CheckUpdate: Cleaned up failed download file: $targetFilePath");
            }
          } catch (deleteError) {
            print(
                "CheckUpdate: Warning - Failed to delete file after final download error: $deleteError");
          }
          return; // Exit function after final failure
        }
        // else: Not the last attempt, loop will continue after delay (handled at loop start)
      } finally {
        // Ensure resources are released even if unexpected errors occur
        await sink?.close().catchError((_) {});
        client?.close();
      }
    } // --- End Retry Loop ---
  }

  /// Triggers the native Android APK installation prompt using open_file_plus.
  static Future<void> _installApk(String filePath, BuildContext context) async {
    print("CheckUpdate: Attempting to open APK for installation: $filePath");

    // Check if file exists before attempting to open
    final file = File(filePath);
    if (!await file.exists()) {
      print("CheckUpdate: Error - APK file not found at path: $filePath");
      if (context.mounted) {
        SnackBarUtils.showErrorSnackBar(
          context,
          'Installation Error: Downloaded file not found.',
        );
      }
      return;
    }

    // Use open_file_plus to request the system installer
    final result = await OpenFile.open(filePath,
        type: "application/vnd.android.package-archive");

    switch (result.type) {
      case ResultType.done:
        print(
            "CheckUpdate: System installation prompt opened successfully for: $filePath");
        // Optional: You might want to close the update dialog or exit the app here,
        // depending on whether the update was mandatory and your desired UX.
        // Example: If mandatory, you might exit after triggering install.
        // if (forceUpdate && context.mounted) SystemNavigator.pop();
        break;
      case ResultType.noAppToOpen:
        print(
            "CheckUpdate: Error opening installer - No application found to handle APK files.");
        if (context.mounted) {
          SnackBarUtils.showErrorSnackBar(
            context,
            'Could not start installation: No app found to open APK files.',
          );
        }
        break;
      case ResultType.permissionDenied:
        print(
            "CheckUpdate: Error opening installer - Permission denied. User may need to grant install permission.");
        if (context.mounted) {
          SnackBarUtils.showErrorSnackBar(
            context,
            'Installation permission denied. Please allow installation from this app in settings.',
          );
        }
        // Consider guiding the user to settings if possible/necessary
        break;
      case ResultType.error:
      default:
        print(
            "CheckUpdate: Error opening installer: ${result.type} - ${result.message}");
        if (context.mounted) {
          SnackBarUtils.showErrorSnackBar(
            context,
            'Error opening installer: ${result.message}',
          );
        }
        break;
    }
  }

  /// Download and install an APK update
  static Future<void> _downloadAndInstallUpdate(
    BuildContext context,
    String url,
    String updateType, // 'Staging' or 'Production'
  ) async {
    // Create a stateful download progress indicator
    final downloadProgress = ValueNotifier<double>(0.0);
    final downloadState = ValueNotifier<String>("Preparing...");
    
    // Show the download progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('Downloading $updateType Update'),
        content: ValueListenableBuilder(
          valueListenable: downloadProgress,
          builder: (context, value, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: value),
                const SizedBox(height: 16),
                ValueListenableBuilder(
                  valueListenable: downloadState,
                  builder: (context, state, _) => Text(state),
                ),
              ],
            );
          },
        ),
      ),
    );
    
    try {
      // Important user warning for staging updates
      if (updateType == 'Staging') {
        print("CheckUpdate: Installing STAGING update. Make sure you're running the STAGING version of the app!");
        print("CheckUpdate: Staging app ID: com.casesync.app.test, Production app ID: com.casesync.app");
        
        // Get the application ID of the current app
        final packageInfo = await PackageInfo.fromPlatform();
        final String appId = packageInfo.packageName;
        
        print("CheckUpdate: Current app ID: $appId");
        
        // Show warning if trying to install a staging APK on a production app
        if (appId == "com.casesync.app" && !appId.contains(".test")) {
          // Close the download dialog
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          
            // Show warning dialog
            await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("Installation Error"),
                content: const Text(
                  "You are trying to install a STAGING update on the PRODUCTION app. "
                  "This will not work.\n\n"
                  "Please install the correct version of the app for testing."
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text("OK"),
                  )
                ],
              ),
            );
          }
          return;
        }
      }
      
      // Get the temporary directory for storing the APK
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/app_update.apk';
      final file = File(filePath);
      
      // Create the file
      if (await file.exists()) {
        await file.delete();
      }
      await file.create();
      
      // Start the download
      downloadState.value = "Connecting...";
      
      // Retrieve the GitHub PAT from dart-define environment variables
      const String githubPat = String.fromEnvironment(_githubPatKey, defaultValue: '');
      
      // First, get the metadata from GitHub API
      final client = http.Client();
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Accept": "application/vnd.github.v3+json",
          // Include Authorization header for private repositories
          if (githubPat.isNotEmpty) "Authorization": "Bearer $githubPat",
        },
      );
      
      if (response.statusCode != 200) {
        throw HttpException(
          'API request failed with status code: ${response.statusCode}',
          uri: Uri.parse(url)
        );
      }
      
      // Parse the API response to get the download URL
      final apiResponse = jsonDecode(response.body);
      
      if (apiResponse['content'] != null && apiResponse['encoding'] == 'base64') {
        // For smaller files, GitHub API includes the content directly as base64
        downloadState.value = "Decoding...";
        
        // Decode the base64 content
        final String base64Content = apiResponse['content'].replaceAll('\n', '');
        final List<int> bytes = base64Decode(base64Content);
        
        // Write bytes directly to file
        await file.writeAsBytes(bytes);
        print("CheckUpdate: Downloaded APK size: ${bytes.length} bytes (from base64)");
        
        // Update dialog to show installing
        downloadState.value = "Installing...";
        
        // Install the APK
        final result = await OpenFile.open(
          filePath,
          type: "application/vnd.android.package-archive"
        );
        
        // Close the dialog
        Navigator.of(context, rootNavigator: true).pop();
        
        // Handle install issues
        if (result.type != ResultType.done) {
          print("CheckUpdate: Installation error: ${result.type} - ${result.message}");
          SnackBarUtils.showErrorSnackBar(
            context, 
            "Failed to install APK: ${result.message}"
          );
        }
      } else if (apiResponse['download_url'] != null) {
        // For larger files, GitHub API gives a download_url
        final String downloadUrl = apiResponse['download_url'];
        
        // Now download the actual file
        downloadState.value = "Downloading...";
        
        final request = http.Request('GET', Uri.parse(downloadUrl));
        if (githubPat.isNotEmpty) {
          request.headers["Authorization"] = "Bearer $githubPat";
        }
        
        final downloadResponse = await client.send(request);
        
        if (downloadResponse.statusCode != 200) {
          throw HttpException(
            'Download failed with status code: ${downloadResponse.statusCode}',
            uri: Uri.parse(downloadUrl)
          );
        }
        
        final contentLength = downloadResponse.contentLength ?? 0;
        int receivedBytes = 0;
        
        final sink = file.openWrite();
        
        await downloadResponse.stream.forEach((chunk) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          
          if (contentLength > 0) {
            downloadProgress.value = receivedBytes / contentLength;
            
            // Update state with percentage
            final percent = (downloadProgress.value * 100).toStringAsFixed(1);
            downloadState.value = "Downloading... $percent%";
          }
        });
        
        await sink.flush();
        await sink.close();
        
        // Update dialog to show installing
        downloadState.value = "Installing...";
        
        // Print downloaded file size for debugging
        final fileSize = await file.length();
        print("CheckUpdate: Downloaded APK size: $fileSize bytes");
        
        // Install the APK
        final result = await OpenFile.open(
          filePath,
          type: "application/vnd.android.package-archive"
        );
        
        // Close the dialog
        Navigator.of(context, rootNavigator: true).pop();
        
        // Handle install issues
        if (result.type != ResultType.done) {
          print("CheckUpdate: Installation error: ${result.type} - ${result.message}");
          SnackBarUtils.showErrorSnackBar(
            context, 
            "Failed to install APK: ${result.message}"
          );
        }
      } else {
        throw Exception("GitHub API response did not contain expected content or download_url");
      }
    } catch (e) {
      // Close the dialog on error
      print("CheckUpdate: Download error: $e");
      
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        
        SnackBarUtils.showErrorSnackBar(
          context,
          "Error downloading update: $e",
        );
      }
    }
  }
} // End of CheckUpdate class
