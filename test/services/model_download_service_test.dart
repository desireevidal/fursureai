import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:fursure/core/error/app_exceptions.dart';
import 'package:fursure/services/model_download_service.dart';
import 'package:fursure/core/config/model_spec.dart';

class _MockDio extends Mock implements Dio {}

const _breedSpec = ModelSpec(
  label: 'breed',
  filename: 'breed_model.tflite',
  url: 'https://example.com/breed_model.tflite',
);

const _genderSpec = ModelSpec(
  label: 'gender',
  filename: 'gender_model.tflite',
  url: 'https://example.com/gender_model.tflite',
  usePlaceholder: true,
);

void main() {
  group('ModelDownloadService', () {
    late Directory tempDirectory;
    late _MockDio dio;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'model_download_service_test',
      );
      dio = _MockDio();
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    ModelDownloadService makeService() => ModelDownloadService(
      dio: dio,
      getDocumentsDirectory: () async => tempDirectory,
      validateConfig: () {},
    );

    test('returns cached model path when file already exists', () async {
      final File cachedFile = File('${tempDirectory.path}/breed_model.tflite');
      await cachedFile.writeAsString('cached');

      final String path = await makeService().ensureModel(_breedSpec);

      expect(path, cachedFile.path);
      verifyNever(() => dio.download(any(), any()));
    });

    test('preload downloads only non-placeholder models', () async {
      when(
        () => dio.download(
          any(),
          any(),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer((Invocation invocation) async {
        final String savePath = invocation.positionalArguments[1] as String;
        await File(savePath).writeAsString('downloaded');
        return Response<void>(requestOptions: RequestOptions(path: savePath));
      });

      await makeService().preloadModels([
        (spec: _breedSpec, onProgress: null),
        (spec: _genderSpec, onProgress: null),
      ]);

      expect(
        File('${tempDirectory.path}/breed_model.tflite').existsSync(),
        isTrue,
      );
      expect(
        File('${tempDirectory.path}/gender_model.tflite').existsSync(),
        isFalse,
      );
      verify(
        () => dio.download(
          any(),
          any(),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).called(1);
    });

    test('passes when SHA-256 matches cached file', () async {
      const String content = 'cached';
      final File cachedFile = File('${tempDirectory.path}/breed_model.tflite');
      await cachedFile.writeAsString(content);
      final String correctHash =
          sha256.convert(cachedFile.readAsBytesSync()).toString();

      final spec = ModelSpec(
        label: 'breed',
        filename: 'breed_model.tflite',
        url: 'https://example.com/breed_model.tflite',
        sha256: correctHash,
      );

      final String path = await makeService().ensureModel(spec);

      expect(path, cachedFile.path);
      verifyNever(() => dio.download(any(), any()));
    });

    test('throws and deletes file when SHA-256 of cached file mismatches',
        () async {
      final File cachedFile = File('${tempDirectory.path}/breed_model.tflite');
      await cachedFile.writeAsString('corrupted');

      final spec = ModelSpec(
        label: 'breed',
        filename: 'breed_model.tflite',
        url: 'https://example.com/breed_model.tflite',
        sha256: 'a' * 64,
      );

      await expectLater(
        makeService().ensureModel(spec),
        throwsA(isA<ModelDownloadException>()),
      );
      expect(cachedFile.existsSync(), isFalse);
    });

    test('throws and deletes file when SHA-256 of downloaded file mismatches',
        () async {
      when(
        () => dio.download(
          any(),
          any(),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer((Invocation invocation) async {
        final String savePath = invocation.positionalArguments[1] as String;
        await File(savePath).writeAsString('tampered');
        return Response<void>(requestOptions: RequestOptions(path: savePath));
      });

      final spec = ModelSpec(
        label: 'breed',
        filename: 'breed_model.tflite',
        url: 'https://example.com/breed_model.tflite',
        sha256: 'b' * 64,
      );

      await expectLater(
        makeService().ensureModel(spec),
        throwsA(isA<ModelDownloadException>()),
      );
      expect(
        File('${tempDirectory.path}/breed_model.tflite').existsSync(),
        isFalse,
      );
    });

    test('skips SHA-256 check when hash is empty', () async {
      when(
        () => dio.download(
          any(),
          any(),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer((Invocation invocation) async {
        final String savePath = invocation.positionalArguments[1] as String;
        await File(savePath).writeAsString('model');
        return Response<void>(requestOptions: RequestOptions(path: savePath));
      });

      final String path = await makeService().ensureModel(_breedSpec);

      expect(path, '${tempDirectory.path}/breed_model.tflite');
    });

    test('throws typed exception when download fails', () async {
      when(
        () => dio.download(
          any(),
          any(),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/breed_model.tflite'),
          message: 'network error',
        ),
      );

      expect(
        makeService().ensureModel(_breedSpec),
        throwsA(isA<ModelDownloadException>()),
      );
    });
  });
}
