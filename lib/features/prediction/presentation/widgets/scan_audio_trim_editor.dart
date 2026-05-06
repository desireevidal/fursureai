import 'dart:io';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'package:fursure/core/error/app_exceptions.dart';
import 'package:fursure/core/theme/app_radius.dart';
import 'package:fursure/core/theme/app_spacing.dart';
import 'package:fursure/core/theme/brand_colors.dart';
import 'package:fursure/core/widgets/app_back_button.dart';
import 'package:fursure/core/widgets/app_page.dart';
import 'package:fursure/core/widgets/label.dart';
import 'package:fursure/features/prediction/data/prediction_constants.dart';
import 'package:fursure/services/audio_service.dart';

class ScanAudioTrimEditor extends StatefulWidget {
  const ScanAudioTrimEditor({
    super.key,
    required this.sourcePath,
    required this.audioService,
    this.sourceIsPrepared = false,
  });

  final String sourcePath;
  final AudioService audioService;
  final bool sourceIsPrepared;

  @override
  State<ScanAudioTrimEditor> createState() => _ScanAudioTrimEditorState();
}

class _ScanAudioTrimEditorState extends State<ScanAudioTrimEditor> {
  static const _editorMaxDuration = Duration(seconds: 15);
  static const _waveformMinBars = 56;
  static const _waveformMaxBars = 220;
  static const _timelineFollowPadding = 56.0;
  static const _minSelection = Duration(
    seconds: PredictionConstants.audioMinDurationSeconds,
  );
  static const _maxSelection = Duration(
    seconds: PredictionConstants.audioMaxDurationSeconds,
  );

  final AudioPlayer _player = AudioPlayer();
  final ScrollController _timelineScrollController = ScrollController();

  File? _preparedFile;
  Duration _audioDuration = Duration.zero;
  Duration _clipDuration = _maxSelection;
  RangeValues _selection = const RangeValues(0, 2000);
  double _playheadMilliseconds = 0;
  double? _lastPlaybackStartMilliseconds;
  Duration? _playbackStopAt;
  List<double> _waveformBars = const [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPlaying = false;
  String? _errorMessage;
  double _timelineViewportWidth = 0;
  double _timelineContentWidth = 0;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state == PlayerState.playing);
    });
    _player.onPositionChanged.listen((position) {
      if (!mounted) return;
      final stopAt = _playbackStopAt;
      if (stopAt != null && position >= stopAt) {
        _player.pause();
        final restartAt = _lastPlaybackStartMilliseconds ?? stopAt.inMilliseconds.toDouble();
        _player.seek(Duration(milliseconds: restartAt.round()));
        setState(() {
          _playheadMilliseconds = restartAt;
          _isPlaying = false;
          _playbackStopAt = null;
        });
        _scheduleEnsurePlayheadVisible();
        return;
      }
      setState(() {
        _playheadMilliseconds = position.inMilliseconds.toDouble().clamp(
          0.0,
          _audioDuration.inMilliseconds.toDouble(),
        );
      });
      _scheduleEnsurePlayheadVisible();
    });
    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      final restartAt = _lastPlaybackStartMilliseconds ?? _playheadMilliseconds;
      setState(() {
        _isPlaying = false;
        _playheadMilliseconds = restartAt;
        _playbackStopAt = null;
      });
      _scheduleEnsurePlayheadVisible();
    });
    _prepareEditor();
  }

  @override
  void dispose() {
    _player.dispose();
    _timelineScrollController.dispose();
    final preparedFile = _preparedFile;
    if (preparedFile != null) {
      widget.audioService.deletePreparedAudio(preparedFile);
    }
    super.dispose();
  }

  Duration get _selectionStart =>
      Duration(milliseconds: _selection.start.round());

  Duration get _selectionEnd => Duration(milliseconds: _selection.end.round());

  Duration get _selectionDuration => _selectionEnd - _selectionStart;

  Duration get _playheadPosition =>
      Duration(milliseconds: _playheadMilliseconds.round());

  double get _maxRangeMilliseconds => math.max(
    _audioDuration.inMilliseconds.toDouble(),
    1,
  );

  Future<void> _prepareEditor() async {
    try {
      final prepared = widget.sourceIsPrepared
          ? File(widget.sourcePath)
          : await widget.audioService.prepareAudioForEditing(
              File(widget.sourcePath),
            );
      final duration = await widget.audioService.readWavDuration(prepared);
      final waveform = await widget.audioService.buildWaveformBars(
        prepared,
        barCount: _waveformBarCountFor(duration),
      );
      final selectionEnd = math.min(
        duration.inMilliseconds.toDouble(),
        _clipDuration.inMilliseconds.toDouble(),
      );

      if (!mounted) {
        await widget.audioService.deletePreparedAudio(prepared);
        return;
      }

      setState(() {
        _preparedFile = prepared;
        _audioDuration = duration;
        _waveformBars = waveform;
        _selection = RangeValues(0, selectionEnd);
        _playheadMilliseconds = 0;
        _isLoading = false;
      });
      _scheduleEnsurePlayheadVisible();
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not open this audio file for editing.';
        _isLoading = false;
      });
    }
  }

  int _waveformBarCountFor(Duration duration) {
    final seconds = math.max(
      duration.inMilliseconds / Duration.millisecondsPerSecond,
      1,
    );
    return (seconds * 5).round().clamp(_waveformMinBars, _waveformMaxBars);
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _player.pause();
      if (mounted) {
        setState(() => _playbackStopAt = null);
      }
      return;
    }

    await _startPlayback();
  }

  Future<void> _startPlayback({double? forcedStartMilliseconds}) async {
    final preparedFile = _preparedFile;
    if (preparedFile == null) return;

    final playhead = _playheadMilliseconds;
    final totalMilliseconds = _audioDuration.inMilliseconds.toDouble();
    final atAudioEnd =
        totalMilliseconds > 0 &&
        (totalMilliseconds - playhead).abs() <= 1;
    final playInsideSelection =
        playhead >= _selection.start && playhead <= _selection.end;
    final startMilliseconds =
        forcedStartMilliseconds ??
        (atAudioEnd
            ? 0.0
            : (playInsideSelection ? _selection.start : _playheadMilliseconds));

    await _player.stop();
    await _player.setSourceDeviceFile(preparedFile.path);
    await _player.seek(Duration(milliseconds: startMilliseconds.round()));

    if (mounted) {
      setState(() {
        _playheadMilliseconds = startMilliseconds;
        _lastPlaybackStartMilliseconds = startMilliseconds;
        _playbackStopAt = playInsideSelection ? _selectionEnd : null;
      });
    } else {
      _lastPlaybackStartMilliseconds = startMilliseconds;
      _playbackStopAt = playInsideSelection ? _selectionEnd : null;
    }

    await _player.resume();
  }

  void _onSelectionChanged(RangeValues values) {
    final totalMs = _audioDuration.inMilliseconds.toDouble();
    if (totalMs <= 0) return;

    final end = _selection.end;
    final minStart = math.max(
      end - _maxSelection.inMilliseconds.toDouble(),
      0.0,
    );
    final maxStart = math.max(
      end - _minSelection.inMilliseconds.toDouble(),
      0.0,
    );
    final effectiveMinStart = math.min(minStart, maxStart);
    final start = values.start.clamp(effectiveMinStart, maxStart).toDouble();

    if (_isPlaying) {
      _player.pause();
    }

    setState(() {
      _selection = RangeValues(start, end);
      _clipDuration = Duration(milliseconds: (end - start).round());
      if (_playheadMilliseconds < start) {
        _playheadMilliseconds = start;
      }
      _playbackStopAt = null;
    });
    _scheduleEnsurePlayheadVisible();
  }

  void _onSelectionEndChanged(double endMilliseconds) {
    final totalMs = _audioDuration.inMilliseconds.toDouble();
    if (totalMs <= 0) return;

    final start = _selection.start;
    final minEnd = start + _minSelection.inMilliseconds.toDouble();
    final maxEnd = math.min(
      start + _maxSelection.inMilliseconds.toDouble(),
      totalMs,
    );
    final effectiveMinEnd = math.min(minEnd, maxEnd);
    final end = endMilliseconds.clamp(effectiveMinEnd, maxEnd).toDouble();

    if (_isPlaying) {
      _player.pause();
    }

    setState(() {
      _clipDuration = Duration(milliseconds: (end - start).round());
      _selection = RangeValues(start, end);
      if (_playheadMilliseconds > end) {
        _playheadMilliseconds = end;
      }
      _playbackStopAt = null;
    });
    _scheduleEnsurePlayheadVisible();
  }

  void _setPlayhead(double valueMilliseconds) {
    final totalMs = _audioDuration.inMilliseconds.toDouble();
    if (totalMs <= 0) return;
    final clamped = valueMilliseconds.clamp(0.0, totalMs);

    if (_isPlaying) {
      _player.pause();
    }

    setState(() {
      _playheadMilliseconds = clamped;
      _playbackStopAt = null;
    });
    _scheduleEnsurePlayheadVisible();
  }

  void _moveSelectionToPlayhead() {
    final totalMs = _audioDuration.inMilliseconds.toDouble();
    if (totalMs <= 0) return;

    final clipMs = math.min(_clipDuration.inMilliseconds.toDouble(), totalMs);
    final maxStart = math.max(totalMs - clipMs, 0.0);
    final start = _playheadMilliseconds.clamp(0.0, maxStart).toDouble();
    final end = math.min(start + clipMs, totalMs).toDouble();

    if (_isPlaying) {
      _player.pause();
    }

    setState(() {
      _selection = RangeValues(start, end);
      _playbackStopAt = null;
    });
    _scheduleEnsurePlayheadVisible();
  }

  void _shiftSelectionBy(double deltaMilliseconds) {
    final totalMs = _audioDuration.inMilliseconds.toDouble();
    if (totalMs <= 0) return;

    final clipMs = (_selection.end - _selection.start).clamp(
      _minSelection.inMilliseconds.toDouble(),
      math.min(_maxSelection.inMilliseconds.toDouble(), totalMs),
    );
    final maxStart = math.max(totalMs - clipMs, 0.0);
    final start = (_selection.start + deltaMilliseconds)
        .clamp(0.0, maxStart)
        .toDouble();
    final end = math.min(start + clipMs, totalMs).toDouble();

    if (_isPlaying) {
      _player.pause();
    }

    setState(() {
      _selection = RangeValues(start, end);
      if (_playheadMilliseconds < start) {
        _playheadMilliseconds = start;
      } else if (_playheadMilliseconds > end) {
        _playheadMilliseconds = end;
      }
      _playbackStopAt = null;
    });
    _scheduleEnsurePlayheadVisible();
  }

  Future<void> _restartPlayback() async {
    final start = _playheadMilliseconds >= _selection.start &&
            _playheadMilliseconds <= _selection.end
        ? _selection.start
        : (_lastPlaybackStartMilliseconds ?? _playheadMilliseconds);
    await _startPlayback(forcedStartMilliseconds: start);
  }

  void _skipBy(Duration delta) {
    final totalMs = _audioDuration.inMilliseconds.toDouble();
    if (totalMs <= 0) return;

    final next = (_playheadMilliseconds + delta.inMilliseconds)
        .clamp(0.0, totalMs)
        .toDouble();

    if (_isPlaying) {
      _player.pause();
    }

    setState(() {
      _playheadMilliseconds = next;
      _playbackStopAt = null;
    });
    _scheduleEnsurePlayheadVisible();
  }

  void _cacheTimelineMetrics({
    required double viewportWidth,
    required double contentWidth,
  }) {
    _timelineViewportWidth = viewportWidth;
    _timelineContentWidth = contentWidth;
  }

  void _scheduleEnsurePlayheadVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ensurePlayheadVisible();
    });
  }

  void _ensurePlayheadVisible() {
    if (!_timelineScrollController.hasClients ||
        _timelineViewportWidth <= 0 ||
        _timelineContentWidth <= _timelineViewportWidth) {
      return;
    }

    final safeMax = math.max(_maxRangeMilliseconds, 1);
    final playheadX = (_playheadMilliseconds / safeMax) * _timelineContentWidth;
    final position = _timelineScrollController.position;
    final currentOffset = position.pixels;
    final minVisible = currentOffset + _timelineFollowPadding;
    final maxVisible = currentOffset + _timelineViewportWidth - _timelineFollowPadding;

    double? targetOffset;
    if (playheadX < minVisible) {
      targetOffset = playheadX - _timelineFollowPadding;
    } else if (playheadX > maxVisible) {
      targetOffset = playheadX - _timelineViewportWidth + _timelineFollowPadding;
    }

    if (targetOffset == null) return;

    final clampedOffset = targetOffset.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    ).toDouble();

    if ((clampedOffset - currentOffset).abs() < 1) return;
    _timelineScrollController.jumpTo(clampedOffset);
  }

  Future<void> _saveTrimmedAudio() async {
    final preparedFile = _preparedFile;
    if (preparedFile == null || _isSaving) return;

    final selectionDuration = _selectionDuration;
    if (selectionDuration < _minSelection || selectionDuration > _maxSelection) {
      setState(() {
        _errorMessage = 'Select a meow clip between 1 and 2 seconds.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final trimmed = await widget.audioService.trimPreparedAudio(
        inputFile: preparedFile,
        start: _selectionStart,
        end: _selectionEnd,
      );
      await widget.audioService.deletePreparedAudio(preparedFile);
      _preparedFile = null;
      if (!mounted) return;
      Navigator.of(context).pop(trimmed.path);
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isSaving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not save the trimmed meow. Please try again.';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final brand = context.brand;
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final contentMaxWidth = viewportWidth >= 900
        ? 760.0
        : viewportWidth >= 700
        ? 640.0
        : double.infinity;
    final timerFontSize = (viewportWidth * 0.08).clamp(44.0, 54.0).toDouble();

    return AppPage(
      horizontalPadding: false,
      backgroundColor: surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                spacing.m,
                spacing.sm,
                spacing.m,
                spacing.sm,
              ),
              child: Row(
                children: [
                  AppBackButton(
                    onPressed: () => Navigator.of(context).pop(),
                    padded: false,
                    color: onSurface,
                  ),
                  SizedBox(width: spacing.sm),
                  const Expanded(
                    child: Label(
                      'Edit',
                      variant: LabelVariant.title,
                      size: 22,
                      weight: FontWeight.w700,
                      uppercase: false,
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoading || _isSaving ? null : _saveTrimmedAudio,
                    child: _isSaving
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation(brand.purple),
                            ),
                          )
                        : Label(
                            'Save',
                            variant: LabelVariant.title,
                            size: 18,
                            color: brand.purple,
                            uppercase: false,
                          ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null && _preparedFile == null
                  ? _TrimErrorState(message: _errorMessage!)
                  : Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentMaxWidth),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            spacing.lg,
                            spacing.sm,
                            spacing.lg,
                            spacing.lg,
                          ),
                          child: Column(
                            children: [
                              Text(
                                _formatEditorTime(_selectionDuration),
                                style: TextStyle(
                                  fontSize: timerFontSize,
                                  fontWeight: FontWeight.w300,
                                  color: onSurface.withValues(alpha: 0.82),
                                  letterSpacing: -1.4,
                                ),
                              ),
                              SizedBox(height: spacing.xs),
                              Label(
                                '${_formatDuration(_selectionStart)} – ${_formatDuration(_selectionEnd)}',
                                variant: LabelVariant.body,
                                size: 16,
                                color: onSurfaceVariant,
                                uppercase: false,
                              ),
                              SizedBox(height: spacing.lg),
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final timelineViewportWidth = math.max(
                                      constraints.maxWidth,
                                      1,
                                    ).toDouble();
                                    final timelineWidth =
                                        _timelineContentWidthFor(
                                          viewportWidth: timelineViewportWidth,
                                        );
                                    _cacheTimelineMetrics(
                                      viewportWidth: timelineViewportWidth,
                                      contentWidth: timelineWidth,
                                    );

                                    return Column(
                                      children: [
                                        Expanded(
                                          child: SingleChildScrollView(
                                            controller: _timelineScrollController,
                                            scrollDirection: Axis.horizontal,
                                            child: SizedBox(
                                              width: timelineWidth,
                                              child: Column(
                                                children: [
                                                  _TimeRuler(
                                                    totalDuration: _audioDuration,
                                                  ),
                                                  SizedBox(height: spacing.xs),
                                                  Expanded(
                                                    child: _WaveformTrimView(
                                                      bars: _waveformBars,
                                                      selection: _selection,
                                                      playheadMilliseconds:
                                                          _playheadMilliseconds,
                                                      maxMilliseconds:
                                                          _maxRangeMilliseconds,
                                                      brand: brand,
                                                      onSelectionChanged:
                                                          _onSelectionChanged,
                                                      onSelectionEndChanged:
                                                          _onSelectionEndChanged,
                                                      onPlayheadChanged:
                                                          _setPlayhead,
                                                      onSelectionAreaDragged:
                                                          _shiftSelectionBy,
                                                      onMarkerLongPress:
                                                          _moveSelectionToPlayhead,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: spacing.m),
                                        if (_errorMessage != null) ...[
                                          SizedBox(height: spacing.sm),
                                          Label(
                                            _errorMessage!,
                                            variant: LabelVariant.caption,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                            align: TextAlign.center,
                                            uppercase: false,
                                          ),
                                        ],
                                      ],
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: spacing.m),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _TransportButton(
                                    icon: Icons.fast_rewind_rounded,
                                    onPressed: () =>
                                        _skipBy(const Duration(seconds: -2)),
                                  ),
                                  _TransportButton(
                                    icon: _isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    isPrimary: true,
                                    onPressed: _togglePlayback,
                                  ),
                                  _TransportButton(
                                    icon: Icons.repeat_rounded,
                                    onPressed: _restartPlayback,
                                  ),
                                  _TransportButton(
                                    icon: Icons.fast_forward_rounded,
                                    onPressed: () =>
                                        _skipBy(const Duration(seconds: 2)),
                                  ),
                                ],
                              ),
                              SizedBox(height: spacing.m),
                              Label(
                                'Drag the black bottom caps to trim. Top marker scrubs playback.',
                                variant: LabelVariant.caption,
                                color: onSurfaceVariant,
                                align: TextAlign.center,
                                uppercase: false,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final centiseconds =
        ((duration.inMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds.$centiseconds';
  }

  String _formatEditorTime(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final centiseconds =
        ((duration.inMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds.$centiseconds';
  }

  double _timelineContentWidthFor({required double viewportWidth}) {
    final seconds = math.max(
      _audioDuration.inMilliseconds / Duration.millisecondsPerSecond,
      1,
    );
    final pixelsPerSecond = viewportWidth >= 900
        ? 78.0
        : viewportWidth >= 700
        ? 68.0
        : 56.0;
    return math.max(viewportWidth, seconds * pixelsPerSecond);
  }
}

class _TransportButton extends StatelessWidget {
  const _TransportButton({
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return InkResponse(
      onTap: onPressed,
      radius: isPrimary ? 34 : 28,
      child: Container(
        width: isPrimary ? 68 : 56,
        height: isPrimary ? 68 : 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPrimary ? brand.purple : brand.pink,
          boxShadow: [
            BoxShadow(
              color: (isPrimary ? brand.purple : brand.pink).withValues(alpha: 0.24),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
          border: isPrimary
              ? Border.all(color: brand.pink.withValues(alpha: 0.45), width: 2)
              : null,
        ),
        child: Icon(
          icon,
          color: onPrimary,
          size: isPrimary ? 34 : 28,
        ),
      ),
    );
  }
}

class _TrimErrorState extends StatelessWidget {
  const _TrimErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.xl),
        child: Label(
          message,
          variant: LabelVariant.body,
          size: 16,
          align: TextAlign.center,
          color: Theme.of(context).colorScheme.error,
          uppercase: false,
        ),
      ),
    );
  }
}

class _TimeRuler extends StatelessWidget {
  const _TimeRuler({
    required this.totalDuration,
  });

  final Duration totalDuration;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final totalMs = math.max(totalDuration.inMilliseconds, 1);
    final labels = <Duration>[
      Duration.zero,
      Duration(milliseconds: (totalMs * 0.25).round()),
      Duration(milliseconds: (totalMs * 0.5).round()),
      Duration(milliseconds: (totalMs * 0.75).round()),
      Duration(milliseconds: totalMs),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final label in labels)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing.xs),
            child: Text(
              _shortTimestamp(label),
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.82),
              ),
            ),
          ),
      ],
    );
  }

  String _shortTimestamp(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _WaveformTrimView extends StatelessWidget {
  const _WaveformTrimView({
    required this.bars,
    required this.selection,
    required this.playheadMilliseconds,
    required this.maxMilliseconds,
    required this.brand,
    required this.onSelectionChanged,
    required this.onSelectionEndChanged,
    required this.onPlayheadChanged,
    required this.onSelectionAreaDragged,
    required this.onMarkerLongPress,
  });

  final List<double> bars;
  final RangeValues selection;
  final double playheadMilliseconds;
  final double maxMilliseconds;
  final BrandColors brand;
  final ValueChanged<RangeValues> onSelectionChanged;
  final ValueChanged<double> onSelectionEndChanged;
  final ValueChanged<double> onPlayheadChanged;
  final ValueChanged<double> onSelectionAreaDragged;
  final VoidCallback onMarkerLongPress;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final safeMax = math.max(maxMilliseconds, 1);
    final selectedStart = selection.start / safeMax;
    final selectedEnd = selection.end / safeMax;
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final usableWidth = math.max(constraints.maxWidth, 1);
        const trimLineWidth = 2.0;
        const handleCapWidth = 18.0;
        const handleCapHeight = 44.0;
        const handleTouchWidth = 30.0;
        const handleTouchHeight = 72.0;
        const playheadTouchWidth = 36.0;
        const playheadTouchHeight = 44.0;
        const playheadLineWidth = 2.0;
        final left = usableWidth * selectedStart;
        final right = usableWidth * selectedEnd;
        final playhead = usableWidth * (playheadMilliseconds / safeMax);
        final selectedWidth = math.max(right - left, 0).toDouble();
        final leftLineLeft = left.clamp(0.0, usableWidth).toDouble();
        final rightLineLeft = (right - trimLineWidth).clamp(
          0.0,
          math.max(usableWidth - trimLineWidth, 0.0),
        ).toDouble();
        final maxTouchLeft = math.max(usableWidth - handleTouchWidth, 0.0);
        final leftHandleVisualLeft = leftLineLeft + trimLineWidth;
        final rightHandleVisualLeft = rightLineLeft - handleCapWidth;
        final leftHandleTouchLeft = (leftHandleVisualLeft).clamp(
          0.0,
          maxTouchLeft,
        ).toDouble();
        final rightHandleTouchLeft = (rightHandleVisualLeft -
                (handleTouchWidth - handleCapWidth))
            .clamp(
          0.0,
          maxTouchLeft,
        ).toDouble();
        final leftHandleVisualOffset =
            leftHandleVisualLeft - leftHandleTouchLeft;
        final rightHandleVisualOffset =
            rightHandleVisualLeft - rightHandleTouchLeft;

        return Container(
          constraints: const BoxConstraints(minHeight: 320),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
                Align(
                  alignment: Alignment.center,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      for (var i = 0; i < bars.length; i++) ...[
                        Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: 4,
                              height: 72 + bars[i] * 180,
                              decoration: BoxDecoration(
                                color: _barColor(
                                  index: i,
                                  total: bars.length,
                                  selectedStart: selectedStart,
                                  selectedEnd: selectedEnd,
                                  colorScheme: colorScheme,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                        if (i != bars.length - 1) SizedBox(width: spacing.xs),
                      ],
                    ],
                  ),
                ),
                if (left > 0)
                  Positioned(
                    left: 0,
                    width: left,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.36),
                      ),
                    ),
                  ),
                Positioned(
                  left: left,
                  width: selectedWidth,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      color: brand.purple.withValues(alpha: 0.16),
                    ),
                  ),
                ),
                Positioned(
                  left: left,
                  width: selectedWidth,
                  top: 0,
                  bottom: 0,
                  child: _LongPressDragTarget(
                    onDragDelta: (deltaPx) => onSelectionAreaDragged(
                      (deltaPx / usableWidth) * safeMax,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                Positioned(
                  left: playhead - playheadLineWidth / 2,
                  top: 30,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      width: playheadLineWidth,
                      decoration: BoxDecoration(
                        color: brand.pink,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                if (right < usableWidth)
                  Positioned(
                    left: right,
                    width: usableWidth - right,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.36),
                      ),
                    ),
                  ),
                Positioned(
                  left: leftLineLeft,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      width: trimLineWidth,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: rightLineLeft,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      width: trimLineWidth,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: leftHandleTouchLeft,
                  bottom: 0,
                  height: handleTouchHeight,
                  child: _DragTarget(
                    width: handleTouchWidth,
                    onDragDelta: (deltaPx) {
                      onSelectionChanged(
                        RangeValues(
                          selection.start + (deltaPx / usableWidth) * safeMax,
                          selection.end,
                        ),
                      );
                    },
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: _TrimEdgeHandle(
                        color: Colors.black87,
                        width: handleCapWidth,
                        height: handleCapHeight,
                        horizontalOffset: leftHandleVisualOffset,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: (playhead - playheadTouchWidth / 2).clamp(
                    -playheadTouchWidth / 2,
                    math.max(
                      usableWidth - playheadTouchWidth / 2,
                      -playheadTouchWidth / 2,
                    ),
                  ),
                  top: 0,
                  child: IgnorePointer(
                    child: SizedBox(
                      width: playheadTouchWidth,
                      height: playheadTouchHeight,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: _CenterMarker(color: brand.pink),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: rightHandleTouchLeft,
                  bottom: 0,
                  height: handleTouchHeight,
                  child: _DragTarget(
                    width: handleTouchWidth,
                    onDragDelta: (deltaPx) => onSelectionEndChanged(
                      selection.end + (deltaPx / usableWidth) * safeMax,
                    ),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: _TrimEdgeHandle(
                        color: Colors.black87,
                        width: handleCapWidth,
                        height: handleCapHeight,
                        horizontalOffset: rightHandleVisualOffset,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: (playhead - playheadTouchWidth / 2).clamp(
                    -playheadTouchWidth / 2,
                    math.max(
                      usableWidth - playheadTouchWidth / 2,
                      -playheadTouchWidth / 2,
                    ),
                  ),
                  top: 0,
                  child: _DragTarget(
                    width: playheadTouchWidth,
                    height: playheadTouchHeight,
                    onDragDelta: (deltaPx) => onPlayheadChanged(
                      playheadMilliseconds + (deltaPx / usableWidth) * safeMax,
                    ),
                    onLongPress: onMarkerLongPress,
                    child: SizedBox(width: playheadTouchWidth),
                  ),
                ),
              ],
            ),
          );
      },
    );
  }

  Color _barColor({
    required int index,
    required int total,
    required double selectedStart,
    required double selectedEnd,
    required ColorScheme colorScheme,
  }) {
    final fraction = total <= 1 ? 0.0 : index / (total - 1);
    final selected =
        fraction >= selectedStart && fraction <= selectedEnd;
    if (selected) {
      return brand.purple.withValues(alpha: 0.55);
    }
    return colorScheme.outlineVariant.withValues(alpha: 0.34);
  }
}

class _DragTarget extends StatelessWidget {
  const _DragTarget({
    required this.width,
    this.height,
    required this.onDragDelta,
    required this.child,
    this.onLongPress,
  });

  final double width;
  final double? height;
  final ValueChanged<double> onDragDelta;
  final Widget child;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (details) => onDragDelta(details.delta.dx),
      onLongPress: onLongPress,
      child: SizedBox(
        width: width,
        height: height,
        child: child,
      ),
    );
  }
}

class _LongPressDragTarget extends StatefulWidget {
  const _LongPressDragTarget({
    required this.onDragDelta,
    required this.child,
  });

  final ValueChanged<double> onDragDelta;
  final Widget child;

  @override
  State<_LongPressDragTarget> createState() => _LongPressDragTargetState();
}

class _LongPressDragTargetState extends State<_LongPressDragTarget> {
  double? _lastGlobalDx;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPressStart: (details) => _lastGlobalDx = details.globalPosition.dx,
      onLongPressMoveUpdate: (details) {
        final lastDx = _lastGlobalDx;
        if (lastDx == null) {
          _lastGlobalDx = details.globalPosition.dx;
          return;
        }
        final delta = details.globalPosition.dx - lastDx;
        _lastGlobalDx = details.globalPosition.dx;
        widget.onDragDelta(delta);
      },
      onLongPressEnd: (_) => _lastGlobalDx = null,
      onLongPressUp: () => _lastGlobalDx = null,
      child: widget.child,
    );
  }
}

class _TrimEdgeHandle extends StatelessWidget {
  const _TrimEdgeHandle({
    required this.color,
    required this.width,
    required this.height,
    required this.horizontalOffset,
  });

  final Color color;
  final double width;
  final double height;
  final double horizontalOffset;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(horizontalOffset, 0),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterMarker extends StatelessWidget {
  const _CenterMarker({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.arrow_drop_down_rounded,
          size: 30,
          color: color,
        ),
      ],
    );
  }
}
