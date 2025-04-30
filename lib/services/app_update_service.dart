import 'dart:convert';
import 'dart:io';

import 'package:case_sync/utils/flavor_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file_plus/open_file_plus.dart';

class AppUpdateService extends GetxService {
  final updateAvailable = false.obs;
  final updateVersion = ''.obs;
  final updateUrl = ''.obs;
  final isForceUpdate = false.obs;
  final isDownloading = false.obs;
  final downloadProgress = 0.0.obs;

  Future<AppUpdateService> init() async {
    // Check for updates on app start
    await checkForUpdates();
    return this;
  }

  Future<void> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      // Get the appropriate update check URL based on flavor
      final updateCheckUrl = await FlavorConfig.getUpdateCheckUrl();
      String? versionJsonUrl;
      
      if (FlavorConfig.isTest()) {
        // For test flavor, use the URL from FlavorConfig
        versionJsonUrl = updateCheckUrl;
      } else {
        // For production, use the standard GitHub releases path
        versionJsonUrl = 'https://api.github.com/repos/${FlavorConfig.getRepoPath()}/releases/latest';
      }
      
      if (versionJsonUrl == null) return;
      
      final response = await http.get(Uri.parse(versionJsonUrl));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        String latestVersion;
        String apkUrl;
        bool forceUpdate = false;
        
        if (FlavorConfig.isTest()) {
          // Parse test version.json format
          latestVersion = data['version'];
          apkUrl = data['apk_url'];
          forceUpdate = data['force_update'] ?? false;
        } else {
          // Parse GitHub releases format
          latestVersion = data['tag_name'].toString().replaceFirst('v', '');
          
          // Find the APK asset
          final assets = data['assets'] as List;
          final apkAsset = assets.firstWhere(
            (asset) => asset['name'].toString().endsWith('.apk'),
            orElse: () => null,
          );
          
          if (apkAsset != null) {
            apkUrl = apkAsset['browser_download_url'];
          } else {
            return; // No APK found in the release
          }
        }
        
        // Compare versions
        if (_isNewerVersion(latestVersion, currentVersion)) {
          updateAvailable.value = true;
          updateVersion.value = latestVersion;
          updateUrl.value = apkUrl;
          isForceUpdate.value = forceUpdate;
          
          // Show update dialog for force updates
          if (forceUpdate) {
            _showForceUpdateDialog();
          }
        }
      }
    } catch (e) {
      print('Error checking for updates: $e');
    }
  }
  
  Future<void> downloadAndInstallUpdate() async {
    if (!updateAvailable.value || updateUrl.value.isEmpty) return;
    
    try {
      isDownloading.value = true;
      downloadProgress.value = 0.0;
      
      final apkUrl = updateUrl.value;
      final uri = Uri.parse(apkUrl);
      
      // Get temporary directory to save the APK
      final directory = await getExternalStorageDirectory() ?? await getTemporaryDirectory();
      final filePath = '${directory.path}/app_update.apk';
      final file = File(filePath);
      
      // Create the file
      if (await file.exists()) {
        await file.delete();
      }
      await file.create();
      
      // Download with progress
      final client = http.Client();
      final request = http.Request('GET', uri);
      final response = await client.send(request);
      
      final contentLength = response.contentLength ?? 0;
      int receivedBytes = 0;
      
      final sink = file.openWrite();
      
      await response.stream.forEach((chunk) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        
        if (contentLength > 0) {
          downloadProgress.value = receivedBytes / contentLength;
        }
      });
      
      await sink.flush();
      await sink.close();
      
      // Install APK
      final result = await OpenFile.open(filePath);
      
      if (result.type != ResultType.done) {
        throw Exception('Failed to open APK: ${result.message}');
      }
      
      isDownloading.value = false;
    } catch (e) {
      isDownloading.value = false;
      print('Error downloading update: $e');
      Get.snackbar(
        'Update Failed',
        'Failed to download or install the update. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  void _showForceUpdateDialog() {
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false, // Prevent dialog dismiss on back press
        child: AlertDialog(
          title: const Text('Update Required'),
          content: const Text(
            'A new version is available. You need to update the app to continue using it.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                downloadAndInstallUpdate();
              },
              child: const Text('Update Now'),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }
  
  bool _isNewerVersion(String newVersion, String currentVersion) {
    final List<int> newParts = newVersion.split('.').map(int.parse).toList();
    final List<int> currentParts = currentVersion.split('.').map(int.parse).toList();
    
    // Make sure both lists have the same length
    while (newParts.length < currentParts.length) {
      newParts.add(0);
    }
    while (currentParts.length < newParts.length) {
      currentParts.add(0);
    }
    
    // Compare version parts
    for (int i = 0; i < newParts.length; i++) {
      if (newParts[i] > currentParts[i]) {
        return true;
      } else if (newParts[i] < currentParts[i]) {
        return false;
      }
    }
    
    return false; // Versions are equal
  }
} 