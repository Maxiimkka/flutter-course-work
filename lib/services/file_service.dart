import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class FileService {
  static Future<String?> pickFile() async {
    try {
      final XFile? result = await openFile(
        acceptedTypeGroups: [
          XTypeGroup(
            label: 'files',
            extensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png', 'gif'],
          ),
        ],
      );

      if (result != null) {
        return result.path;
      }
    } catch (e) {
      print('Error picking file: $e');
    }
    return null;
  }

  static Future<String> saveFile(String sourcePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = path.basename(sourcePath);
      final savedPath = path.join(directory.path, fileName);
      
      final sourceFile = File(sourcePath);
      await sourceFile.copy(savedPath);
      
      return savedPath;
    } catch (e) {
      print('Error saving file: $e');
      rethrow;
    }
  }

  static Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting file: $e');
      rethrow;
    }
  }

  static Future<List<String>> getAttachments(List<String> attachmentPaths) async {
    final List<String> existingAttachments = [];
    
    for (final path in attachmentPaths) {
      final file = File(path);
      if (await file.exists()) {
        existingAttachments.add(path);
      }
    }
    
    return existingAttachments;
  }
} 