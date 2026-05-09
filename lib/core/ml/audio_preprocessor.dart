import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import '../error/app_exceptions.dart';
import '../../features/prediction/data/prediction_constants.dart';

class AudioPreprocessor {
  const AudioPreprocessor();

  static const int _sr = PredictionConstants.audioSampleRate;
  static const int _targetSamples = PredictionConstants.audioTargetSamples;
  static const int _nMfcc = PredictionConstants.mfccCoefficients;
  static const int _maxLen = PredictionConstants.mfccMaxTimeSteps;
  static const double _topDb = PredictionConstants.audioTopDb;
  static const int _nFft = PredictionConstants.mfccNFft;
  static const int _hopLength = PredictionConstants.mfccHopLength;
  static const int _nMels = PredictionConstants.mfccNMels;

  static const int _specBins = _nFft ~/ 2 + 1;
  static const double _amin = 1e-10;

  List<List<List<List<double>>>> extractFeatures(File audioFile) {
    final bytes = audioFile.readAsBytesSync();
    final samples = _parsePreparedWav(bytes);

    if (samples.isEmpty) {
      throw const InferenceException('Could not read audio for prediction.');
    }

    final trimmed = _trimSilence(samples);
    final candidate = trimmed.isEmpty ? samples : trimmed;

    if (!_hasUsableMeowSignal(candidate)) {
      throw const InferenceException(
        'We couldn’t detect a clear meow. Please try again in a quieter place or record closer to your cat.',
      );
    }

    final normalized = _normalize(candidate);
    final fixed = _fixLength(normalized);

    final mfcc = _mfcc(fixed);
    final delta = _delta(mfcc);
    final delta2 = _delta(delta);

    return _buildTensor(mfcc, delta, delta2);
  }

  Float32List _parsePreparedWav(Uint8List bytes) {
    if (bytes.length < 44) {
      throw const InferenceException('Could not prepare audio for prediction.');
    }

    final riff = String.fromCharCodes(bytes.sublist(0, 4));
    final wave = String.fromCharCodes(bytes.sublist(8, 12));

    if (riff != 'RIFF' || wave != 'WAVE') {
      throw const InferenceException('Could not prepare audio for prediction.');
    }

    int offset = 12;
    int dataOffset = -1;
    int dataSize = -1;
    int audioFormat = -1;
    int numChannels = -1;
    int sampleRate = -1;
    int bitsPerSample = -1;

    while (offset + 8 <= bytes.length) {
      final chunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final chunkSize = ByteData.sublistView(bytes, offset + 4, offset + 8)
          .getUint32(0, Endian.little);

      if (chunkId == 'fmt ') {
        if (offset + 8 + 16 > bytes.length) {
          throw const InferenceException('Could not prepare audio for prediction.');
        }

        final fmtData = ByteData.sublistView(
          bytes,
          offset + 8,
          math.min(offset + 8 + chunkSize, bytes.length),
        );

        audioFormat = fmtData.getUint16(0, Endian.little);
        numChannels = fmtData.getUint16(2, Endian.little);
        sampleRate = fmtData.getUint32(4, Endian.little);
        bitsPerSample = fmtData.getUint16(14, Endian.little);
      } else if (chunkId == 'data') {
        dataOffset = offset + 8;
        dataSize = chunkSize;
        break;
      }

      offset += 8 + chunkSize;
      if (chunkSize.isOdd) {
        offset += 1;
      }
    }

    if (dataOffset < 0 || dataSize <= 0) {
      throw const InferenceException('Could not prepare audio for prediction.');
    }

    if (audioFormat != 1 || numChannels != 1 || sampleRate != _sr || bitsPerSample != 16) {
      throw const InferenceException('Could not prepare audio for prediction.');
    }

    final safeEnd = math.min(dataOffset + dataSize, bytes.length);
    final safeSize = safeEnd - dataOffset;

    if (safeSize <= 0 || safeSize.isOdd) {
      throw const InferenceException('Could not prepare audio for prediction.');
    }

    final numSamples = safeSize ~/ 2;
    final out = Float32List(numSamples);
    final bd = ByteData.sublistView(bytes, dataOffset, safeEnd);

    for (var i = 0; i < numSamples; i++) {
      out[i] = bd.getInt16(i * 2, Endian.little) / 32768.0;
    }

    return out;
  }

  Float32List _trimSilence(Float32List audio) {
    if (audio.isEmpty) return audio;

    const frameLen = 2048;
    const hop = 512;
    final numFrames = 1 + (audio.length - 1) ~/ hop;

    double maxRms = 0.0;
    final rmsVals = Float64List(numFrames);

    for (var f = 0; f < numFrames; f++) {
      final start = f * hop;
      final end = math.min(start + frameLen, audio.length);
      if (end <= start) continue;

      double sumSq = 0.0;
      for (var i = start; i < end; i++) {
        sumSq += audio[i] * audio[i];
      }

      final rms = math.sqrt(sumSq / (end - start));
      rmsVals[f] = rms;
      if (rms > maxRms) maxRms = rms;
    }

    if (maxRms <= 0) return audio;

    final refDb = 20.0 * math.log(maxRms) / math.ln10;
    final threshold = refDb - _topDb;

    int startFrame = 0;
    int endFrame = numFrames - 1;

    for (var f = 0; f < numFrames; f++) {
      final db = 20.0 * math.log(math.max(_amin, rmsVals[f])) / math.ln10;
      if (db >= threshold) {
        startFrame = f;
        break;
      }
    }

    for (var f = numFrames - 1; f >= 0; f--) {
      final db = 20.0 * math.log(math.max(_amin, rmsVals[f])) / math.ln10;
      if (db >= threshold) {
        endFrame = f;
        break;
      }
    }

    final startSample = startFrame * hop;
    final endSample = math.min((endFrame + 1) * hop + frameLen, audio.length);

    if (startSample >= endSample) return audio;
    return _slice(audio, startSample, endSample);
  }

  Float32List _normalize(Float32List audio) {
    double maxAbs = 0.0;
    for (final s in audio) {
      final a = s.abs();
      if (a > maxAbs) maxAbs = a;
    }

    if (maxAbs <= 0) return audio;

    final out = Float32List(audio.length);
    for (var i = 0; i < audio.length; i++) {
      out[i] = audio[i] / maxAbs;
    }
    return out;
  }

  Float32List _fixLength(Float32List audio) {
    if (audio.length == _targetSamples) return audio;

    final out = Float32List(_targetSamples);
    final copyLen = math.min(audio.length, _targetSamples);
    out.setRange(0, copyLen, audio);
    return out;
  }

  Float32List _slice(Float32List audio, int start, int end) {
    start = math.max(0, start);
    end = math.min(audio.length, end);

    if (end <= start) return Float32List(0);

    final out = Float32List(end - start);
    for (var i = 0; i < out.length; i++) {
      out[i] = audio[start + i];
    }
    return out;
  }

  bool _hasUsableMeowSignal(Float32List audio) {
    if (audio.isEmpty) return false;

    double peak = 0.0;
    double sumSq = 0.0;
    int activeSamples = 0;

    for (final sample in audio) {
      final abs = sample.abs();
      if (abs > peak) peak = abs;
      sumSq += sample * sample;
      if (abs >= 0.015) {
        activeSamples++;
      }
    }

    final rms = math.sqrt(sumSq / audio.length);
    final activeRatio = activeSamples / audio.length;

    return peak >= 0.025 && rms >= 0.003 && activeRatio >= 0.005;
  }

  List<Float64List> _mfcc(Float32List audio) {
    final padLen = _nFft ~/ 2;
    final padded = Float64List(audio.length + 2 * padLen);

    for (var i = 0; i < padLen; i++) {
      padded[i] = audio[padLen - 1 - i];
    }
    for (var i = 0; i < audio.length; i++) {
      padded[padLen + i] = audio[i];
    }
    for (var i = 0; i < padLen; i++) {
      padded[padLen + audio.length + i] = audio[audio.length - 1 - i];
    }

    final window = Float64List(_nFft);
    for (var i = 0; i < _nFft; i++) {
      window[i] = 0.5 - 0.5 * math.cos(2 * math.pi * i / (_nFft - 1));
    }

    final melFb = _buildMelFilterbank();

    final numFrames = 1 + (padded.length - _nFft) ~/ _hopLength;
    final logMel = List.generate(_nMels, (_) => Float64List(numFrames));

    final re = Float64List(_nFft);
    final im = Float64List(_nFft);
    double globalMaxDb = double.negativeInfinity;

    for (var t = 0; t < numFrames; t++) {
      final start = t * _hopLength;

      for (var i = 0; i < _nFft; i++) {
        re[i] = padded[start + i] * window[i];
        im[i] = 0.0;
      }

      _fftInPlace(re, im);

      for (var m = 0; m < _nMels; m++) {
        double melPower = 0.0;
        for (var k = 0; k < _specBins; k++) {
          melPower += melFb[m][k] * (re[k] * re[k] + im[k] * im[k]);
        }

        final db = 10.0 * math.log(math.max(_amin, melPower)) / math.ln10;
        logMel[m][t] = db;

        if (db > globalMaxDb) {
          globalMaxDb = db;
        }
      }
    }

    final floor = globalMaxDb - 80.0;
    for (var m = 0; m < _nMels; m++) {
      for (var t = 0; t < numFrames; t++) {
        if (logMel[m][t] < floor) {
          logMel[m][t] = floor;
        }
      }
    }

    final mfccOut = List.generate(_nMfcc, (_) => Float64List(numFrames));
    final scale0 = math.sqrt(1.0 / _nMels);
    final scaleK = math.sqrt(2.0 / _nMels);

    for (var t = 0; t < numFrames; t++) {
      for (var k = 0; k < _nMfcc; k++) {
        double sum = 0.0;
        for (var n = 0; n < _nMels; n++) {
          sum +=
              logMel[n][t] *
              math.cos(math.pi * k * (2 * n + 1) / (2 * _nMels));
        }
        mfccOut[k][t] = (k == 0 ? scale0 : scaleK) * sum;
      }
    }

    if (numFrames == _maxLen) {
      return mfccOut;
    }

    return List.generate(_nMfcc, (k) {
      final row = Float64List(_maxLen);
      row.setRange(0, math.min(numFrames, _maxLen), mfccOut[k]);
      return row;
    });
  }

  List<Float64List> _buildMelFilterbank() {
    const fSp = 200.0 / 3.0;
    const minLogHz = 1000.0;
    const minLogMel = minLogHz / fSp;
    final logStep = math.log(6.4) / 27.0;

    double hzToMel(double f) {
      if (f < minLogHz) return f / fSp;
      return minLogMel + math.log(f / minLogHz) / logStep;
    }

    double melToHz(double m) {
      if (m < minLogMel) return m * fSp;
      return minLogHz * math.exp(logStep * (m - minLogMel));
    }

    final melMin = hzToMel(0.0);
    final melMax = hzToMel(_sr / 2.0);

    final melPoints = List.generate(_nMels + 2, (i) {
      return melMin + (melMax - melMin) * i / (_nMels + 1);
    });

    final hzPoints = melPoints.map(melToHz).toList();
    final fftFreqs = List.generate(_specBins, (k) => k * _sr / _nFft);
    final fdiff =
        List.generate(_nMels + 1, (i) => hzPoints[i + 1] - hzPoints[i]);

    final fb = List.generate(_nMels, (_) => Float64List(_specBins));

    for (var m = 0; m < _nMels; m++) {
      for (var k = 0; k < _specBins; k++) {
        final f = fftFreqs[k];
        final lower = (f - hzPoints[m]) / fdiff[m];
        final upper = (hzPoints[m + 2] - f) / fdiff[m + 1];
        final w = math.min(lower, upper);
        if (w > 0) {
          fb[m][k] = w;
        }
      }
    }

    return fb;
  }

  List<Float64List> _delta(List<Float64List> features) {
    const halfW = 4;
    const norm = 60.0;

    final nRows = features.length;
    final nCols = features[0].length;

    return List.generate(nRows, (r) {
      final row = features[r];
      return Float64List.fromList(
        List.generate(nCols, (t) {
          double d = 0.0;

          for (var k = 1; k <= halfW; k++) {
            final tPlus = math.min(t + k, nCols - 1);
            final tMinus = math.max(t - k, 0);
            d += k * (row[tPlus] - row[tMinus]);
          }

          return d / norm;
        }),
      );
    });
  }

  List<List<List<List<double>>>> _buildTensor(
    List<Float64List> mfcc,
    List<Float64List> delta,
    List<Float64List> delta2,
  ) {
    Float64List rowAt(int row) {
      if (row < _nMfcc) return mfcc[row];
      if (row < 2 * _nMfcc) return delta[row - _nMfcc];
      return delta2[row - 2 * _nMfcc];
    }

    return [
      [
        for (var row = 0; row < PredictionConstants.mfccTotalFeatures; row++)
          [
            for (var t = 0; t < _maxLen; t++) [rowAt(row)[t]],
          ],
      ],
    ];
  }

  void _fftInPlace(Float64List re, Float64List im) {
    final n = re.length;

    for (int i = 1, j = 0; i < n; i++) {
      int bit = n >> 1;
      for (; j & bit != 0; bit >>= 1) {
        j ^= bit;
      }
      j ^= bit;

      if (i < j) {
        double tmp = re[i];
        re[i] = re[j];
        re[j] = tmp;

        tmp = im[i];
        im[i] = im[j];
        im[j] = tmp;
      }
    }

    for (int len = 2; len <= n; len <<= 1) {
      final ang = -2.0 * math.pi / len;
      final wRe = math.cos(ang);
      final wIm = math.sin(ang);

      for (int i = 0; i < n; i += len) {
        double curRe = 1.0;
        double curIm = 0.0;
        final half = len >> 1;

        for (int j = 0; j < half; j++) {
          final uRe = re[i + j];
          final uIm = im[i + j];

          final vRe =
              re[i + j + half] * curRe - im[i + j + half] * curIm;
          final vIm =
              re[i + j + half] * curIm + im[i + j + half] * curRe;

          re[i + j] = uRe + vRe;
          im[i + j] = uIm + vIm;
          re[i + j + half] = uRe - vRe;
          im[i + j + half] = uIm - vIm;

          final newRe = curRe * wRe - curIm * wIm;
          curIm = curRe * wIm + curIm * wRe;
          curRe = newRe;
        }
      }
    }
  }
}
