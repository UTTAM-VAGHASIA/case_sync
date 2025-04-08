import 'dart:convert';
import 'dart:io';

import 'package:case_sync/screens/constants/constants.dart';
import 'package:case_sync/utils/dismissible_card.dart';
import 'package:case_sync/utils/snackbar_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../../services/shared_pref.dart';
import '../../../utils/file_already_exists_dialog.dart';

class DocumentCard extends StatefulWidget {
  final Map<String, dynamic> doc;
  final String caseNo;
  final VoidCallback onEditSuccess;

  const DocumentCard({
    super.key,
    required this.doc,
    required this.caseNo,
    required this.onEditSuccess,
  });

  @override
  DocumentCardState createState() => DocumentCardState();
}

class DocumentCardState extends State<DocumentCard> {
  double _progress = 0.0;
  late String fileName = "";
  late String filePath = "";
  bool isEditing = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print(widget.doc.toString());
  }

  Future<String?> _downloadFile(
      String url, String directoryPath, String fileName, bool isSharing,
      [bool isPersistent = false]) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final directory = Directory(directoryPath);
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      if (file.existsSync()) {
        if (isPersistent) {
          final result = await showCupertinoDialog<bool>(
            context: context,
            builder: (context) => FileAlreadyExistsDialog(
              title: 'File Already Exists',
              message:
                  'The file "$fileName" already exists. Do you want to open it or download again?',
              cancelButtonText: 'Open',
              confirmButtonText: 'Rewrite',
              onConfirm: () async {
                Navigator.of(context).pop(true);
              },
            ),
          );

          if (result == true) {
            // User chose to rewrite (download again)
            final response = await HttpClient()
                .getUrl(Uri.parse(url))
                .then((req) => req.close());
            final totalBytes = response.contentLength;
            int bytesDownloaded = 0;

            final sink = file.openWrite();
            await for (var chunk in response) {
              bytesDownloaded += chunk.length;
              sink.add(chunk);
              setState(() {
                _progress = bytesDownloaded / totalBytes;
              });
            }
            await sink.close();
          } else {
            // User chose to open the existing file
            if (!isSharing) {
              await OpenFile.open(filePath);
            }
            return filePath;
          }
        } else {
          if (!isSharing) {
            await OpenFile.open(filePath);
          }
          return filePath;
        }
      } else {
        // File does not exist, proceed with download
        final response = await HttpClient()
            .getUrl(Uri.parse(url))
            .then((req) => req.close());
        final totalBytes = response.contentLength;
        int bytesDownloaded = 0;

        final sink = file.openWrite();
        await for (var chunk in response) {
          bytesDownloaded += chunk.length;
          sink.add(chunk);
          setState(() {
            _progress = bytesDownloaded / totalBytes;
          });
        }
        await sink.close();
      }

      setState(() {
        _progress = 1.0;
      });

      if (!isSharing) {
        await OpenFile.open(filePath);
      }
      return filePath;
    } catch (e) {
      SnackBarUtils.showErrorSnackBar(context, 'Failed to save document.');
    }

    return null;
  }

  void _showOptions(String url) async {
    final fileName = url.split('/').last;
    final tempDir = (await getTemporaryDirectory()).path;

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Open With'),
              onTap: () async {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
                await _downloadFile(url, tempDir, fileName, false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.save_alt),
              title: const Text('Save Document'),
              onTap: () async {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
                final manageStorageStatus =
                    await Permission.manageExternalStorage.request();
                final storageStatus = await Permission.storage.request();
                if (manageStorageStatus.isGranted || storageStatus.isGranted) {
                  final saveDir = Platform.isAndroid
                      ? '/storage/emulated/0/Download/Case Sync/${widget.caseNo}'
                      : (await getApplicationDocumentsDirectory()).path;
                  final _ =
                      await _downloadFile(url, saveDir, fileName, false, true);
                } else {
                  await openAppSettings();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () async {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
                final filePath =
                    await _downloadFile(url, tempDir, fileName, true);
                if (filePath != null) {
                  await Share.shareXFiles([XFile(filePath)],
                      text: 'Here is the document!');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Link'),
              onTap: () async {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
                await Clipboard.setData(ClipboardData(text: url));
                SnackBarUtils.showSuccessSnackBar(context, 'Link copied to clipboard.');
              },
            ),
          ],
        );
      },
    );
  }

  Future<List<String>> _pickDocuments() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        // Append newly selected files to the existing list.
        fileName = result.files.first.name;
        filePath = result.files.first.path!;
      });
      return [fileName, filePath];
    } else {
      return [];
    }
  }

  Future<void> handleEdit(
      String fileType, String fileId, String addedBy) async {
    setState(() {
      isEditing = true;
    });
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    List fileDetails = await _pickDocuments();

    if (kDebugMode) {
      print("File Type: ${fileType}");
      print("File ID: ${fileId}");
      print("File Added By: ${addedBy}");
      print("File Type: ${fileDetails}");
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/edit_documents"),
      );

      request.fields['data'] = json.encode({
        'file_type': fileType,
        'file_id': fileId,
        'added_by': addedBy,
      });

      if (fileDetails[1] != null) {
        request.files
            .add(await http.MultipartFile.fromPath('document', fileDetails[1]));
      }

      print("REQUEST FIELDS: ");
      print(request.fields);
      print("REQUEST FILES: ");
      print(request.files[0].filename);

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var data = json.decode(responseData);

        if (data['success']) {
          setState(() {
            widget.onEditSuccess;
          });
          SnackBarUtils.showSuccessSnackBar(context, "Document updated successfully!");
        } else {
          SnackBarUtils.showErrorSnackBar(context, "Error: Failed to Edit Document");
          print('Error, failed to update document: ${data['message']}');
        }
      } else {
        SnackBarUtils.showErrorSnackBar(
          context,
          "Error: Status Code:${response.statusCode}. Failed to edit document. Try again later!"
        );
        print('Error hua hai: ${response.statusCode}');
      }
    } catch (e) {
      SnackBarUtils.showErrorSnackBar(context, "Error: An error occurred: $e");
      print('Error: $e');
    } finally {
      setState(() {
        isEditing = false;
      });
    }
  }

  Future<void> handleDelete(String fileId, String fileType) async {
    setState(() {
      isEditing = true;
    });
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (kDebugMode) {
      print("File Type: ${fileType}");
      print("File ID: ${fileId}");
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/delete_documents"),
      );

      request.fields['data'] = json.encode({
        'file_id': fileId,
        'file_type': fileType,
      });

      print("REQUEST FIELDS: ");
      print(request.fields);

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var data = json.decode(responseData);

        if (data['success']) {
          widget.onEditSuccess;
          SnackBarUtils.showSuccessSnackBar(context, "Document deleted successfully!");
        } else {
          SnackBarUtils.showErrorSnackBar(context, "Error: Failed to Delete Document");
          print('Error, failed to delete document: ${data['message']}');
        }
      } else {
        SnackBarUtils.showErrorSnackBar(
          context,
          "Error: Status Code:${response.statusCode}. Failed to delete document. Try again later!"
        );
        print('Error hua hai: ${response.statusCode}');
      }
    } catch (e) {
      SnackBarUtils.showErrorSnackBar(context, "Error: An error occurred: $e");
      print('Error: $e');
    } finally {
      setState(() {
        isEditing = false;
      });
    }
  }

  Widget _buildFileThumbnail(String url, String extension) {
    if (extension == 'pdf') {
      return const Icon(Icons.picture_as_pdf, size: 50, color: Colors.red);
    } else if (['jpg', 'jpeg', 'png'].contains(extension)) {
      return Image.network(url, width: 50, fit: BoxFit.fitHeight,
          errorBuilder: (_, __, ___) {
        return const Icon(
          Icons.image,
          size: 50,
          color: Colors.grey,
        );
      });
    } else {
      return const Icon(
        Icons.insert_drive_file,
        size: 50,
        color: Colors.blue,
      );
    }
  }

  String getFileNameFromUrl(String url) {
    Uri uri = Uri.parse(url);
    return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
  }

  @override
  Widget build(BuildContext context) {
    final docUrl = widget.doc['docs'];
    final fileName = docUrl.split('/').last;
    final extension = fileName.split('.').last.toLowerCase();

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        if (!isEditing) {
          _showOptions(docUrl);
        }
      },
      child: (isEditing)
          ? LinearProgressIndicator(
              color: Colors.black,
              minHeight: 80,
              borderRadius: BorderRadius.circular(12.0),
            )
          : Card(
              elevation: 0.0,
              color: Color(0xFFF3F3F3),
              margin:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
                side: BorderSide(
                  color: Colors.black,
                  width: 1,
                ),
              ),
              child: DismissibleCard(
                name: getFileNameFromUrl(widget.doc['docs']),
                onEdit: () async {
                  final advocate = await SharedPrefService.getUser();
                  final advocateId = advocate!.id;
                  handleEdit(widget.doc['file_type'], widget.doc['file_id'],
                      advocateId);
                },
                onDelete: () => handleDelete(
                    widget.doc['file_id'], widget.doc['file_type']),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFileThumbnail(docUrl, extension),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fileName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                  ),
                                ),
                                Divider(
                                  color: Colors.black,
                                ),
                                Text(
                                  'Added By: ${widget.doc['handled_by']}',
                                  style: const TextStyle(fontSize: 14.0),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Date: ${widget.doc['date_time']}',
                                  style: const TextStyle(fontSize: 14.0),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_progress > 0.0 &&
                          _progress < 1.0) // ✅ Show only if downloading
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: Colors.grey[300],
                            color: Colors.black,
                            minHeight: 4.0,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
