import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../features/results/data/prediction_record.dart';
import 'app_settings_service.dart';
import 'database_service.dart';

class BackupImportResult {
  const BackupImportResult({
    required this.imported,
    required this.skipped,
    required this.restoredTheme,
  });

  final int imported;
  final int skipped;
  final ThemeMode? restoredTheme;
}

class BackupService {
  BackupService({required this.db, required this.settings});

  final DatabaseService db;
  final AppSettingsService settings;

  Future<String> buildBackupZip() async {
    final predictions = await db.getRecentPredictions(limit: 999999);
    final themeMode = await settings.loadThemeMode();

    final tmpDir = await getTemporaryDirectory();
    final archive = Archive();

    final predictionMaps = <Map<String, dynamic>>[];
    for (final record in predictions) {
      String? imageFile;
      if (record.imagePath != null) {
        final imageFileOnDisk = File(record.imagePath!);
        if (await imageFileOnDisk.exists()) {
          final archiveName = 'images/${record.id}_${p.basename(record.imagePath!)}';
          final bytes = await imageFileOnDisk.readAsBytes();
          archive.addFile(ArchiveFile(archiveName, bytes.length, bytes));
          imageFile = archiveName;
        }
      }
      predictionMaps.add({
        'catName': record.catName,
        'breed': record.breed,
        'breedConfidence': record.breedConfidence,
        'gender': record.gender,
        'genderConfidence': record.genderConfidence,
        'timestamp': record.timestamp.toIso8601String(),
        'imageFile': imageFile,
      });
    }

    final dataJson = jsonEncode({
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'settings': {'themeMode': _serializeTheme(themeMode)},
      'predictions': predictionMaps,
    });

    final jsonBytes = utf8.encode(dataJson);
    archive.addFile(ArchiveFile('data.json', jsonBytes.length, jsonBytes));

    final now = DateTime.now();
    final timestamp =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '_${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}';
    final zipPath = p.join(tmpDir.path, 'fursure_backup_$timestamp.zip');
    await File(zipPath).writeAsBytes(ZipEncoder().encode(archive));
    return zipPath;
  }

  Future<String?> saveToDevice(String zipPath) async {
    final fileName = p.basename(zipPath);
    final bytes = await File(zipPath).readAsBytes();
    final chosen = await FilePicker.platform.saveFile(
      dialogTitle: 'Save backup as',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['zip'],
      bytes: bytes,
    );
    if (chosen == null) return null;
    return chosen;
  }

  Future<BackupImportResult?> import() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (result == null || result.files.single.path == null) return null;

    final zipPath = result.files.single.path!;
    final zipBytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(zipBytes);

    final dataEntry = archive.findFile('data.json');
    if (dataEntry == null) throw const FormatException('Invalid backup: missing data.json');

    final dataJson = jsonDecode(utf8.decode(dataEntry.content as List<int>)) as Map<String, dynamic>;

    ThemeMode? restoredTheme;
    final settingsMap = dataJson['settings'] as Map<String, dynamic>?;
    if (settingsMap != null) {
      final themeMode = _deserializeTheme(settingsMap['themeMode'] as String?);
      await settings.saveThemeMode(themeMode);
      restoredTheme = themeMode;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(docsDir.path, 'images'));
    if (!await imagesDir.exists()) await imagesDir.create(recursive: true);

    final extractedImages = <String, String>{};
    for (final file in archive.files) {
      if (file.name.startsWith('images/') && !file.isDirectory) {
        final basename = p.basename(file.name);
        final destPath = p.join(imagesDir.path, basename);
        await File(destPath).writeAsBytes(file.content as List<int>);
        extractedImages[file.name] = destPath;
      }
    }

    int imported = 0;
    int skipped = 0;
    final predictions = dataJson['predictions'] as List<dynamic>;
    for (final raw in predictions) {
      final map = raw as Map<String, dynamic>;
      final timestamp = map['timestamp'] as String;

      if (await db.predictionExistsAt(timestamp)) {
        skipped++;
        continue;
      }

      String? imagePath;
      final imageFile = map['imageFile'] as String?;
      if (imageFile != null && extractedImages.containsKey(imageFile)) {
        imagePath = extractedImages[imageFile];
      }

      await db.insertPrediction(PredictionRecord(
        catName: map['catName'] as String?,
        breed: map['breed'] as String?,
        breedConfidence: (map['breedConfidence'] as num?)?.toDouble(),
        gender: map['gender'] as String?,
        genderConfidence: (map['genderConfidence'] as num?)?.toDouble(),
        timestamp: DateTime.parse(timestamp),
        imagePath: imagePath,
      ));
      imported++;
    }

    return BackupImportResult(
      imported: imported,
      skipped: skipped,
      restoredTheme: restoredTheme,
    );
  }

  String _serializeTheme(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

  ThemeMode _deserializeTheme(String? value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.system,
      };
}
