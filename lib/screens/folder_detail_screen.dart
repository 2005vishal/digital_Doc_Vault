import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import '../models/document_model.dart';
import '../services/database_helper.dart';
import '../services/google_drive_service.dart';
import 'dashboard_screen.dart';

class FolderDetailScreen extends StatefulWidget {
  final String folderName;
  final VoidCallback resetTimer;

  const FolderDetailScreen({
    super.key,
    required this.folderName,
    required this.resetTimer,
  });

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  List<DocumentModel> _documents = [];
  Set<int> _selectedIds = {};
  bool _isSelectionMode = false;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments({String query = ""}) async {
    setState(() => _isLoading = true);
    final docs = await DatabaseHelper.getDocsByFolder(widget.folderName,
        searchQuery: query);
    setState(() {
      _documents = docs;
      _isLoading = false;
    });
  }

  // 🔥 1. RENAME DOCUMENT LOGIC
  Future<void> _renameDocument(DocumentModel doc) async {
    widget.resetTimer();
    TextEditingController renameController =
        TextEditingController(text: doc.customName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rename Document"),
        content: TextField(
          controller: renameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Enter new name"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (renameController.text.isNotEmpty) {
                await DatabaseHelper.updateDocName(
                    doc.id!, renameController.text);
                Navigator.pop(context);
                _loadDocuments();
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // 🔥 2. PICK & SAVE WITH NAME PROMPT
  Future<void> _pickAndSaveFile() async {
    widget.resetTimer();
    try {
      setState(() => isPickingFileGlobal = true);
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        String defaultName = result.files.single.name.split('.').first;
        TextEditingController nameController =
            TextEditingController(text: defaultName);

        // Naam puchne ke liye Dialog
        String? finalName = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text("Save Document"),
            content: TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: "Document Name",
                hintText: "Enter a name for this file",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() => isPickingFileGlobal = false);
                  Navigator.pop(context, null);
                },
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, nameController.text),
                child: const Text("Upload"),
              ),
            ],
          ),
        );

        if (finalName != null && finalName.isNotEmpty) {
          setState(() => _isLoading = true);
          File pickedFile = File(result.files.single.path!);
          String fileName = result.files.single.name;

          final directory = await getExternalStorageDirectory() ??
              await getApplicationSupportDirectory();
          String newPath = p.join(directory.path, fileName);
          File localFile = await pickedFile.copy(newPath);

          String timestamp =
              DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

          final newDoc = DocumentModel(
            customName: finalName, // User wala naam save hoga
            docNumber:
                "DOC-${DateTime.now().millisecondsSinceEpoch.toString().substring(10)}",
            filePath: localFile.path,
            folderName: widget.folderName,
            dateAdded: timestamp,
          );

          await DatabaseHelper.insertDoc(newDoc);
          await GoogleDriveService.uploadFile(
              localFile, fileName, widget.folderName);
          _loadDocuments();
        }
      }
    } finally {
      setState(() => isPickingFileGlobal = false);
      widget.resetTimer();
    }
  }

  Future<void> _viewFile(String filePath) async {
    widget.resetTimer();
    final File file = File(filePath);
    if (await file.exists()) {
      try {
        setState(() => isPickingFileGlobal = true);
        final result = await OpenFilex.open(filePath);
        if (result.type != ResultType.done && mounted) {
          await Share.shareXFiles([XFile(filePath)]);
        }
      } catch (e) {
        debugPrint("Error: $e");
      }
    }
  }

  void _shareFile(String filePath, String fileName) async {
    widget.resetTimer();
    if (await File(filePath).exists()) {
      try {
        setState(() => isPickingFileGlobal = true);
        String ext = p.extension(filePath).toLowerCase();
        String mime = (ext == '.pdf')
            ? 'application/pdf'
            : 'image/${ext.replaceAll('.', '')}';
        await Share.shareXFiles(
            [XFile(filePath, name: fileName, mimeType: mime)]);
      } finally {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() => isPickingFileGlobal = false);
            widget.resetTimer();
          }
        });
      }
    }
  }

  Future<void> _deleteSelected() async {
    widget.resetTimer();
    bool? confirm = await showDialog(
        context: context,
        builder: (c) => AlertDialog(title: const Text("Delete?"), actions: [
              TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text("No")),
              TextButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: const Text("Yes")),
            ]));
    if (confirm == true) {
      setState(() => _isLoading = true);
      for (int id in _selectedIds) {
        final doc = _documents.firstWhere((d) => d.id == id);
        await DatabaseHelper.deleteDoc(id);
        await GoogleDriveService.deleteFileFromDrive(p.basename(doc.filePath));
      }
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
      _loadDocuments();
    }
  }

  void _toggleSelection(int id) {
    widget.resetTimer();
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode
            ? "${_selectedIds.length} Selected"
            : widget.folderName),
        backgroundColor: _isSelectionMode ? Colors.blueGrey : Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          if (_isSelectionMode)
            IconButton(
                icon: const Icon(Icons.delete), onPressed: _deleteSelected)
        ],
      ),
      body: Column(
        children: [
          if (!_isSelectionMode)
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                    hintText: "Search files...",
                    prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white),
                onChanged: (v) => _loadDocuments(query: v),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _documents.length,
                    itemBuilder: (context, index) {
                      final doc = _documents[index];
                      final isSelected = _selectedIds.contains(doc.id);
                      bool isPdf = doc.filePath.toLowerCase().endsWith('.pdf');
                      return Card(
                        elevation: isSelected ? 4 : 1,
                        color: isSelected
                            ? Colors.indigo.withOpacity(0.1)
                            : Colors.white,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                              color: isSelected
                                  ? Colors.indigo
                                  : Colors.grey.shade300),
                        ),
                        child: ListTile(
                          onLongPress: () => _toggleSelection(doc.id!),
                          onTap: _isSelectionMode
                              ? () => _toggleSelection(doc.id!)
                              : () => _viewFile(doc.filePath),
                          leading: _isSelectionMode
                              ? Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: Colors.indigo)
                              : Icon(isPdf ? Icons.picture_as_pdf : Icons.image,
                                  color: isPdf ? Colors.red : Colors.blue),
                          title: Text(doc.customName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(doc.dateAdded),
                          trailing: !_isSelectionMode
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.grey, size: 20),
                                        onPressed: () => _renameDocument(doc)),
                                    IconButton(
                                        icon: const Icon(Icons.share,
                                            color: Colors.indigo, size: 20),
                                        onPressed: () => _shareFile(
                                            doc.filePath, doc.customName)),
                                  ],
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: _pickAndSaveFile,
              backgroundColor: Colors.indigo,
              child: const Icon(Icons.add, color: Colors.white)),
    );
  }
}
