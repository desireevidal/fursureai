import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'package:fursure/core/theme/brand_colors.dart';
import 'package:fursure/core/theme/app_spacing.dart';
import 'package:fursure/core/widgets/label.dart';

class AudioPlayerPill extends StatefulWidget {
  const AudioPlayerPill({super.key, required this.audioPath});

  final String? audioPath;

  @override
  State<AudioPlayerPill> createState() => _AudioPlayerPillState();
}

class _AudioPlayerPillState extends State<AudioPlayerPill> {
  AudioPlayer? _player;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPreparing = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  AudioPlayer _ensurePlayer() {
    final existing = _player;
    if (existing != null) {
      return existing;
    }

    final player = AudioPlayer();
    player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    player.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });
    player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _position = Duration.zero);
    });
    _player = player;
    return player;
  }

  Future<void> _togglePlayback() async {
    final path = widget.audioPath;
    if (path == null || _isPreparing) return;
    final player = _ensurePlayer();

    try {
      if (_isPlaying) {
        await player.pause();
        return;
      }

      setState(() => _isPreparing = true);
      await player.play(DeviceFileSource(path));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
        _duration = Duration.zero;
      });
    } finally {
      if (mounted) {
        setState(() => _isPreparing = false);
      }
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;
    final brand = context.brand;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.m,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: brand.pink,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: _isPlaying ? 'Pause audio playback' : 'Play audio recording',
            child: GestureDetector(
              onTap: _togglePlayback,
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: onPrimary,
                size: 28,
              ),
            ),
          ),
          SizedBox(width: context.spacing.m),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: onPrimary.withValues(alpha: 0.4),
                valueColor: AlwaysStoppedAnimation(onPrimary),
                minHeight: 3,
              ),
            ),
          ),
          SizedBox(width: context.spacing.m),
          Label(
            _formatDuration(
              _duration > Duration.zero ? _duration : Duration.zero,
            ),
            variant: LabelVariant.label,
            color: onPrimary,
            weight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}
