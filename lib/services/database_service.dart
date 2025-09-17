import 'package:firebase_database/firebase_database.dart';
import '../models/file_item.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  late final FirebaseDatabase _database;
  late final DatabaseReference _filesRef;

  void initialize() {
    try {
      _database = FirebaseDatabase.instance;
      _filesRef = _database.ref().child('files');
      print('Firebase Database initialized successfully');
    } catch (e) {
      print('Error initializing Firebase Database: $e');
      throw 'Failed to initialize Firebase Database. Please check your configuration.';
    }
  }

  Future<void> saveFileMetadata(FileItem fileItem) async {
    try {
      // Firebase paths cannot contain '.', '#', '$', '[', or ']'
      // Replace these characters with underscores
      final sanitizedLoanNumber = fileItem.loanNumber.replaceAll(RegExp(r'[.#$\[\]]'), '_');
      final sanitizedFileName = fileItem.name.replaceAll(RegExp(r'[.#$\[\]]'), '_');
      final fileKey = '${sanitizedLoanNumber}_$sanitizedFileName';

      await _filesRef.child(fileKey).set(fileItem.toJson());
      print('✅ Saved file metadata: $fileKey');
    } catch (e) {
      print('❌ Error saving file metadata: $e');
      // Don't throw error - just log it, so S3 operations can continue
    }
  }

  Future<List<FileItem>> getFilesByLoanNumber(String loanNumber) async {
    try {
      final query = _filesRef.orderByChild('loanNumber').equalTo(loanNumber);
      final snapshot = await query.get();

      if (!snapshot.exists) {
        return [];
      }

      final List<FileItem> files = [];
      final data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        if (value is Map<dynamic, dynamic>) {
          try {
            final fileItem = FileItem.fromJson(Map<String, dynamic>.from(value));
            files.add(fileItem);
          } catch (e) {
            print('Error parsing file item: $e');
          }
        }
      });

      files.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
      return files;
    } catch (e) {
      print('Error getting files by loan number: $e');
      throw 'Failed to retrieve files';
    }
  }

  Future<List<FileItem>> getAllFiles() async {
    try {
      final snapshot = await _filesRef.get();

      if (!snapshot.exists) {
        return [];
      }

      final List<FileItem> files = [];
      final data = snapshot.value as Map<dynamic, dynamic>;

      data.forEach((key, value) {
        if (value is Map<dynamic, dynamic>) {
          try {
            final fileItem = FileItem.fromJson(Map<String, dynamic>.from(value));
            files.add(fileItem);
          } catch (e) {
            print('Error parsing file item: $e');
          }
        }
      });

      files.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
      return files;
    } catch (e) {
      print('Error getting all files: $e');
      throw 'Failed to retrieve files';
    }
  }

  Future<void> deleteFileMetadata(String loanNumber, String fileName) async {
    try {
      final fileKey = '${loanNumber}_$fileName';
      await _filesRef.child(fileKey).remove();
    } catch (e) {
      print('Error deleting file metadata: $e');
      throw 'Failed to delete file information';
    }
  }

  Stream<List<FileItem>> watchFilesByLoanNumber(String loanNumber) {
    final query = _filesRef.orderByChild('loanNumber').equalTo(loanNumber);

    return query.onValue.map((event) {
      final List<FileItem> files = [];

      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;

        data.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            try {
              final fileItem = FileItem.fromJson(Map<String, dynamic>.from(value));
              files.add(fileItem);
            } catch (e) {
              print('Error parsing file item: $e');
            }
          }
        });
      }

      files.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
      return files;
    });
  }

  Stream<List<FileItem>> watchAllFiles() {
    return _filesRef.onValue.map((event) {
      final List<FileItem> files = [];

      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;

        data.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            try {
              final fileItem = FileItem.fromJson(Map<String, dynamic>.from(value));
              files.add(fileItem);
            } catch (e) {
              print('Error parsing file item: $e');
            }
          }
        });
      }

      files.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
      return files;
    });
  }

}