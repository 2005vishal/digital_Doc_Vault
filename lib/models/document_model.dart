class DocumentModel {
  final int? id;
  final String customName;
  final String docNumber;
  final String filePath;
  final String folderName;
  final String dateAdded;

  DocumentModel({
    this.id,
    required this.customName,
    required this.docNumber,
    required this.filePath,
    required this.folderName,
    required this.dateAdded,
  });

  factory DocumentModel.fromMap(Map<String, dynamic> json) => DocumentModel(
        id: json['id'],
        customName: json['custom_name'],
        docNumber: json['doc_number'],
        filePath: json['file_path'],
        folderName: json['folder_name'],
        dateAdded: json['date_added'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'custom_name': customName,
        'doc_number': docNumber,
        'file_path': filePath,
        'folder_name': folderName,
        'date_added': dateAdded,
      };
}
