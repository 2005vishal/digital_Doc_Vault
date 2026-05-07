import 'dart:io';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/document_model.dart';
import 'database_helper.dart';

class GoogleDriveService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  // 🔥 1. Login User (for  main.dart & login_screen.dart )
  static Future<bool> loginUser() async {
    try {
      final user = await _googleSignIn.signIn();
      return user != null;
    } catch (e) {
      debugPrint("Login Error: $e");
      return false;
    }
  }

  // 🔥 2. Check Login Status ( for main.dart)
  static Future<bool> isUserLoggedIn() async {
    try {
      final user = await _googleSignIn.signInSilently();
      return user != null;
    } catch (e) {
      return false;
    }
  }

  // 3. Sign Out
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      debugPrint("Google Drive Session Cleared");
    } catch (e) {
      debugPrint("Sign Out Error: $e");
    }
  }

  // 4. Get Drive API Instance
  static Future<drive.DriveApi?> _getDriveApi() async {
    final googleUser =
        await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final authClient = await _googleSignIn.authenticatedClient();
    if (authClient == null) return null;

    return drive.DriveApi(authClient);
  }

  // 5. Get or Create Folder
  static Future<String?> _getOrCreateFolder(String folderName,
      {String? parentId}) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) return null;

    try {
      String query =
          "name = '$folderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
      if (parentId != null) query += " and '$parentId' in parents";

      var response = await driveApi.files.list(q: query);
      if (response.files != null && response.files!.isNotEmpty) {
        return response.files!.first.id;
      } else {
        var folder = drive.File()
          ..name = folderName
          ..mimeType = "application/vnd.google-apps.folder";
        if (parentId != null) folder.parents = [parentId];
        var result = await driveApi.files.create(folder);
        return result.id;
      }
    } catch (e) {
      return null;
    }
  }

  // 6. Upload File
  static Future<void> uploadFile(
      File localFile, String fileName, String appFolderName) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) return;

    String? rootId = await _getOrCreateFolder("DocApp_Main_Backup");
    if (rootId == null) return;

    String? subFolderId =
        await _getOrCreateFolder(appFolderName, parentId: rootId);
    if (subFolderId == null) return;

    var driveFile = drive.File()
      ..name = fileName
      ..parents = [subFolderId];

    try {
      await driveApi.files.create(
        driveFile,
        uploadMedia: drive.Media(localFile.openRead(), localFile.lengthSync()),
      );
    } catch (e) {
      debugPrint("Upload Error: $e");
    }
  }

  // 🔥 7. Delete SINGLE File from Drive (folder_detail_screen.dart ke liye)
  static Future<void> deleteFileFromDrive(String fileName) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return;

      var response = await driveApi.files
          .list(q: "name = '$fileName' and trashed = false");
      if (response.files != null && response.files!.isNotEmpty) {
        await driveApi.files.delete(response.files!.first.id!);
        debugPrint("File deleted from Drive: $fileName");
      }
    } catch (e) {
      debugPrint("Delete File Error: $e");
    }
  }

  // 8. Delete FULL Folder from Drive
  static Future<void> deleteFolderFromDrive(String folderName) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) return;
    try {
      String? rootId = await _getOrCreateFolder("DocApp_Main_Backup");
      String query =
          "name = '$folderName' and mimeType = 'application/vnd.google-apps.folder' and '$rootId' in parents and trashed = false";
      var response = await driveApi.files.list(q: query);
      if (response.files != null && response.files!.isNotEmpty) {
        await driveApi.files.delete(response.files!.first.id!);
      }
    } catch (e) {
      debugPrint("Folder Delete Error: $e");
    }
  }

  // 9. Rename Folder on Drive
  static Future<void> renameFolderOnDrive(
      String oldName, String newName) async {
    final driveApi = await _getDriveApi();
    if (driveApi == null) return;
    try {
      String? rootId = await _getOrCreateFolder("DocApp_Main_Backup");
      String query =
          "name = '$oldName' and mimeType = 'application/vnd.google-apps.folder' and '$rootId' in parents and trashed = false";
      var response = await driveApi.files.list(q: query);
      if (response.files != null && response.files!.isNotEmpty) {
        var folderToUpdate = drive.File()..name = newName;
        await driveApi.files.update(folderToUpdate, response.files!.first.id!);
      }
    } catch (e) {
      debugPrint("Folder Rename Error: $e");
    }
  }

  // 10. Auto-Sync Logic
  static Future<List<String>> syncDataFromDrive() async {
    List<String> restoredFolders = [];
    final driveApi = await _getDriveApi();
    if (driveApi == null) return restoredFolders;

    String? rootId = await _getOrCreateFolder("DocApp_Main_Backup");
    if (rootId == null) return restoredFolders;

    try {
      var subFoldersResponse = await driveApi.files.list(
        q: "'$rootId' in parents and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
      );
      if (subFoldersResponse.files == null) return restoredFolders;

      final directory = await getExternalStorageDirectory() ??
          await getApplicationSupportDirectory();

      for (var folder in subFoldersResponse.files!) {
        restoredFolders.add(folder.name!);
        var filesResponse = await driveApi.files.list(
            q: "'${folder.id}' in parents and trashed = false",
            $fields: "files(id, name)");

        if (filesResponse.files != null) {
          for (var file in filesResponse.files!) {
            bool exists = await DatabaseHelper.checkIfFileExists(file.name!);
            if (!exists && file.id != null) {
              drive.Media media = await driveApi.files.get(file.id!,
                      downloadOptions: drive.DownloadOptions.fullMedia)
                  as drive.Media;
              List<int> dataStore = [];
              await for (var data in media.stream) {
                dataStore.addAll(data);
              }
              File localFile = File(p.join(directory.path, file.name));
              await localFile.writeAsBytes(dataStore);
              await DatabaseHelper.insertDoc(DocumentModel(
                customName: file.name!.split('.').first,
                docNumber: "Restored",
                filePath: localFile.path,
                folderName: folder.name!,
                dateAdded:
                    "Sync: ${DateTime.now().toString().substring(0, 16)}",
              ));
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Auto-Sync Error: $e");
    }
    return restoredFolders.toSet().toList();
  }
}
