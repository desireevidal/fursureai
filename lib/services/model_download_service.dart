import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../core/config/app_config.dart';
import '../core/error/app_exceptions.dart';
import '../core/config/model_spec.dart';

class ModelDownloadService {
  ModelDownloadService({
    Dio? dio,
    Future<Directory> Function()? getDocumentsDirectory,
    void Function()? validateConfig,
  }) : _dio = dio ?? Dio(),
       _getDocumentsDirectory =
           getDocumentsDirectory ?? getApplicationDocumentsDirectory,
       _validateConfig = validateConfig ?? AppConfig.validateModelDownloadConfig;

  final Dio _dio;
  final Future<Directory> Function() _getDocumentsDirectory;
  final void Function() _validateConfig;

  Future<String> ensureModel(ModelSpec spec) => _ensureModel(spec);

  Future<void> preloadModels(
    List<({ModelSpec spec, void Function(double)? onProgress})> models, {
    bool forceRedownload = false,
  }) async {
    _validateConfig();
    await Future.wait([
      for (final entry in models)
        if (!entry.spec.usePlaceholder)
          _ensureModel(
            entry.spec,
            onProgress: entry.onProgress,
            forceRedownload: forceRedownload,
          ).then((_) {}),
    ]);
  }

  Future<String> _ensureModel(
    ModelSpec spec, {
    void Function(double)? onProgress,
    bool forceRedownload = false,
  }) async {
    final Directory dir = await _getDocumentsDirectory();
    final file = File('${dir.path}/${spec.filename}');

    if (forceRedownload && await file.exists()) {
      await file.delete();
    }

    if (!forceRedownload && await file.exists()) {
      if (spec.sha256.isNotEmpty) {
        await _verifySha256(file, spec.sha256, spec.label);
      }
      onProgress?.call(1.0);
      return file.path;
    }

    if (spec.url.isEmpty) {
      throw ModelDownloadException(
        'Missing download URL for ${spec.label} model.',
      );
    }

    try {
      await _dio.download(
        spec.url,
        file.path,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress?.call(received / total);
        },
      );
    } on DioException catch (e) {
      throw ModelDownloadException(
        'Failed to download ${spec.label} model: ${e.message}',
      );
    }

    if (spec.sha256.isNotEmpty) {
      await _verifySha256(file, spec.sha256, spec.label);
    }

    onProgress?.call(1.0);
    return file.path;
  }

  Future<void> _verifySha256(
    File file,
    String expectedHex,
    String modelLabel,
  ) async {
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    if (digest.toString() != expectedHex.toLowerCase()) {
      await file.delete();
      throw ModelDownloadException(
        'SHA-256 verification failed for $modelLabel model. '
        'Expected $expectedHex but got $digest. '
        'The file may be corrupted or tampered with.',
      );
    }
  }
}
