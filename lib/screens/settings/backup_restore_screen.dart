import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../../database/database_helper.dart';

class BackupRestoreScreen extends StatelessWidget {
  const BackupRestoreScreen({Key? key}) : super(key: key);

  Future<String> getDatabasePath() async {
    return await DatabaseHelper.getDatabaseFilePath();
  }

  Future<void> backupDatabase(BuildContext context) async {
    try {
      final dbPath = await getDatabasePath();
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        await Share.shareXFiles([XFile(dbFile.path)], text: 'Sabaq App Backup');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database file not found.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    }
  }

  Future<void> restoreDatabase(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null && result.files.single.path != null) {
        final pickedFile = File(result.files.single.path!);
        final dbPath = await getDatabasePath();
        await pickedFile.copy(dbPath);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore successful! Please restart the app.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.backup),
              label: const Text('Backup Data'),
              onPressed: () => backupDatabase(context),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.restore),
              label: const Text('Restore Data'),
              onPressed: () => restoreDatabase(context),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            ),
          ],
        ),
      ),
    );
  }
} 