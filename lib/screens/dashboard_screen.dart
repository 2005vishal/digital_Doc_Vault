import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'folder_detail_screen.dart';
import 'security_gate.dart';
import '../services/google_drive_service.dart';
import '../services/database_helper.dart';

// Global flag for session and lifecycle
bool isPickingFileGlobal = false;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  List<String> folders = [];
  final TextEditingController _folderController = TextEditingController();
  bool _isSyncing = false;
  bool _isLocking = false;

  // User Profile Variables
  String userName = "User";
  String? userProfilePic;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadFolders();
    _loadUserInfo();
    // 🔥 Smart Delay: Local load hone ke baad sync trigger karein
    Future.delayed(const Duration(seconds: 3), () => _autoSyncData());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _folderController.dispose();
    super.dispose();
  }

  // 🔥 USER INFO FIX: Build errors aur null checks handle kiye hain
  void _loadUserInfo() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      GoogleSignInAccount? user =
          googleSignIn.currentUser ?? await googleSignIn.signInSilently();

      if (user != null) {
        setState(() {
          if (user!.displayName != null && user!.displayName!.isNotEmpty) {
            userName = user!.displayName!.toString();
          } else {
            // .split() returns List, accessing .first makes it a String
            userName = user!.email.split('@').first;
          }
          userProfilePic = user!.photoUrl;
        });
      }
    } catch (e) {
      debugPrint("User Info Error: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 🔥 BIOMETRIC LOOP FIX: _isLocking flag checks if gate is already open
      if (!isPickingFileGlobal && !_isLocking) {
        _triggerSecurityLock();
      }
    }
  }

  void _triggerSecurityLock() {
    setState(() => _isLocking = true);
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted || isPickingFileGlobal) {
        setState(() => _isLocking = false);
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SecurityGate()),
      ).then((_) {
        if (mounted) setState(() => _isLocking = false);
      });
    });
  }

  // 🔥 GHOST FOLDER FIX: Drive data ko local data mein intelligently merge karein
  Future<void> _autoSyncData() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      List<String> driveFolders = await GoogleDriveService.syncDataFromDrive();

      final prefs = await SharedPreferences.getInstance();
      List<String> localFolders = prefs.getStringList('saved_folders') ?? [];

      if (driveFolders.isNotEmpty) {
        // Sirf wo folders add karein jo Drive par hain par local mein nahi (New backups)
        for (var dFolder in driveFolders) {
          if (!localFolders.contains(dFolder)) {
            localFolders.add(dFolder);
          }
        }
        setState(() {
          folders = localFolders;
        });
        await _saveFolders();
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _loadFolders() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      folders = prefs.getStringList('saved_folders') ?? [];
    });
  }

  Future<void> _saveFolders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_folders', folders);
  }

  // 🔥 SHARE LOGIC: Lock screen bypass handle kiya hai
  Future<void> _shareFolder(String folderName) async {
    setState(() => isPickingFileGlobal = true);
    final docs = await DatabaseHelper.getDocsByFolder(folderName);
    if (docs.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Folder is empty!")));
      setState(() => isPickingFileGlobal = false);
      return;
    }
    List<XFile> filesToShare = docs.map((doc) => XFile(doc.filePath)).toList();
    try {
      await Share.shareXFiles(filesToShare,
          text: 'Sharing folder: $folderName');
    } finally {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => isPickingFileGlobal = false);
      });
    }
  }

  void _showFolderDialog({int? index}) {
    if (index != null) _folderController.text = folders[index];
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(index == null ? "New Folder" : "Rename Folder"),
        content: TextField(
            controller: _folderController,
            autofocus: true,
            decoration: const InputDecoration(hintText: "Enter Name")),
        actions: [
          TextButton(
              onPressed: () {
                _folderController.clear();
                Navigator.pop(context);
              },
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              String newName = _folderController.text.trim();
              if (newName.isNotEmpty) {
                String? oldName = index != null ? folders[index] : null;
                setState(() {
                  if (index == null) {
                    if (!folders.contains(newName)) folders.add(newName);
                  } else {
                    folders[index] = newName;
                  }
                });
                await _saveFolders();

                // 🔥 RENAME SYNC: Drive par bhi badalna zaroori hai
                if (oldName != null) {
                  GoogleDriveService.renameFolderOnDrive(oldName, newName);
                }

                _folderController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 ALIGNMENT FIX: Check orientation
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("DocVault Pro",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          if (_isSyncing)
            const Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                // 🔥 NAME FIX: Use .first to avoid List error
                Text(
                  "Hi, ${userName.split(' ').first}",
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 16,
                  backgroundImage: userProfilePic != null
                      ? NetworkImage(userProfilePic!)
                      : null,
                  child:
                      userProfilePic == null ? const Icon(Icons.person) : null,
                ),
              ],
            ),
          ),
        ],
      ),
      body: folders.isEmpty
          ? const Center(child: Text("No folders found."))
          : GridView.builder(
              padding: EdgeInsets.symmetric(
                  horizontal: 20, vertical: isLandscape ? 10 : 25),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isLandscape ? 5 : 3,
                childAspectRatio: isLandscape ? 1.1 : 0.85,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: folders.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    InkWell(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => FolderDetailScreen(
                                  folderName: folders[index],
                                  resetTimer: () {}))),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.folder,
                                size: 60, color: Colors.amber),
                            const SizedBox(height: 5),
                            Text(folders[index],
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert,
                            size: 20, color: Colors.grey),
                        onSelected: (v) async {
                          if (v == 'del') {
                            String folderName = folders[index];
                            setState(() {
                              folders.removeAt(index);
                            });
                            await _saveFolders();
                            // 🔥 DELETE SYNC: Drive se bhi delete karein
                            GoogleDriveService.deleteFolderFromDrive(
                                folderName);
                          }
                          if (v == 'ren') _showFolderDialog(index: index);
                          if (v == 'share') _shareFolder(folders[index]);
                        },
                        itemBuilder: (c) => [
                          const PopupMenuItem(
                              value: 'ren', child: Text("Rename")),
                          const PopupMenuItem(
                              value: 'share', child: Text("Share")),
                          const PopupMenuItem(
                              value: 'del',
                              child: Text("Delete",
                                  style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFolderDialog(),
        backgroundColor: Colors.indigo,
        mini: isLandscape,
        child: const Icon(Icons.create_new_folder, color: Colors.white),
      ),
    );
  }
}
