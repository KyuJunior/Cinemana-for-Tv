import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import '../models/video_item.dart';
import '../models/video_stream.dart';
import '../models/subtitle_track.dart';
import '../services/cinemana_api_service.dart';
import '../services/storage_service.dart';
import '../theme/tv_theme.dart';
import '../widgets/tv_focusable.dart';

class TVPlayerScreen extends StatefulWidget {
  final VideoItem video;

  const TVPlayerScreen({
    super.key,
    required this.video,
  });

  @override
  State<TVPlayerScreen> createState() => _TVPlayerScreenState();
}

class _TVPlayerScreenState extends State<TVPlayerScreen> {
  late final Player _player;
  late final VideoController _controller;

  bool _isLoading = true;
  String? _errorMessage;

  List<VideoStream> _availableStreams = [];
  VideoStream? _currentStream;

  List<CinemanaSubtitle> _availableSubtitles = [];
  CinemanaSubtitle? _currentSubtitle;

  bool _showOsd = true;
  Timer? _osdTimer;
  Timer? _progressSaveTimer;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;

  final FocusNode _playPauseFocus = FocusNode();
  final FocusScopeNode _playerScopeNode = FocusScopeNode();

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);

    _player.stream.position.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });

    _player.stream.duration.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });

    _player.stream.playing.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });

    _player.stream.error.listen((err) {
      if (mounted && err.isNotEmpty) {
        setState(() => _errorMessage = 'Playback error: $err');
      }
    });

    _initPlayer();
  }

  @override
  void dispose() {
    _saveProgress();
    _osdTimer?.cancel();
    _progressSaveTimer?.cancel();
    _playPauseFocus.dispose();
    _playerScopeNode.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _initPlayer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final storage = context.read<StorageService>();
    final prefQuality = storage.preferredQuality;
    final resumeSeconds = storage.getSavedPosition(widget.video.id);

    try {
      final streamsFuture = CinemanaApiService.getVideoStreams(widget.video.id);
      final subsFuture = CinemanaApiService.getSubtitles(widget.video.id);

      final streams = await streamsFuture;
      final subs = await subsFuture;

      if (!mounted) return;

      if (streams.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No video streams available for this title on your network.';
        });
        return;
      }

      _availableStreams = streams;
      _availableSubtitles = subs;

      // Select initial stream based on user preference or highest quality
      VideoStream chosen = streams.first;
      for (var s in streams) {
        if (s.resolution.toLowerCase().contains(prefQuality.toLowerCase())) {
          chosen = s;
          break;
        }
      }
      _currentStream = chosen;

      // Select initial subtitle (default to Arabic if available)
      if (subs.isNotEmpty) {
        final arSub = subs.where((s) => s.type == 'ar' && s.extension == 'srt').toList();
        if (arSub.isNotEmpty) {
          _currentSubtitle = arSub.first;
        } else {
          _currentSubtitle = subs.first;
        }
      }

      await _startPlayback(_currentStream!.videoUrl, startPosition: Duration(seconds: resumeSeconds));

      // Periodic progress saving
      _progressSaveTimer = Timer.periodic(const Duration(seconds: 10), (_) => _saveProgress());

      _resetOsdTimer();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load video: $e';
        });
      }
    }
  }

  Future<void> _startPlayback(String url, {Duration? startPosition}) async {
    await _player.open(Media(url));

    if (startPosition != null && startPosition.inSeconds > 5) {
      await _player.seek(startPosition);
    }

    if (_currentSubtitle != null && _currentSubtitle!.fileUrl.isNotEmpty) {
      await _player.setSubtitleTrack(SubtitleTrack.uri(_currentSubtitle!.fileUrl) as dynamic);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _playPauseFocus.requestFocus();
    }
  }

  void _saveProgress() {
    if (_position.inSeconds > 10 && _duration.inSeconds > 60) {
      context.read<StorageService>().savePlaybackProgress(
            video: widget.video,
            positionSeconds: _position.inSeconds,
            totalDurationSeconds: _duration.inSeconds,
          );
    }
  }

  void _resetOsdTimer() {
    _osdTimer?.cancel();
    if (!mounted) return;
    setState(() => _showOsd = true);
    _osdTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _isPlaying) {
        setState(() => _showOsd = false);
      }
    });
  }

  void _seekBy(int seconds) {
    _resetOsdTimer();
    final newPos = _position + Duration(seconds: seconds);
    final clamped = Duration(
      seconds: newPos.inSeconds.clamp(0, _duration.inSeconds),
    );
    _player.seek(clamped);
  }

  void _togglePlayPause() {
    _resetOsdTimer();
    _player.playOrPause();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showQualityPicker() {
    _resetOsdTimer();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: TVColors.surface,
        title: const Text('Select Video Quality', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var stream in _availableStreams)
                ListTile(
                  title: Text(
                    '${stream.resolution} (${stream.container.toUpperCase()})',
                    style: TextStyle(
                      color: _currentStream == stream ? TVColors.accent : Colors.white,
                      fontWeight: _currentStream == stream ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: _currentStream == stream
                      ? const Icon(Icons.check_rounded, color: TVColors.accent)
                      : null,
                  onTap: () async {
                    Navigator.of(dialogCtx).pop();
                    if (_currentStream != stream) {
                      final currentPos = _position;
                      setState(() {
                        _currentStream = stream;
                        _isLoading = true;
                      });
                      await _startPlayback(stream.videoUrl, startPosition: currentPos);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubtitlePicker() {
    _resetOsdTimer();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: TVColors.surface,
        title: const Text('Subtitles (الترجمة)', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  'Off (إيقاف)',
                  style: TextStyle(
                    color: _currentSubtitle == null ? TVColors.accent : Colors.white,
                    fontWeight: _currentSubtitle == null ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: _currentSubtitle == null
                    ? const Icon(Icons.check_rounded, color: TVColors.accent)
                    : null,
                onTap: () {
                  Navigator.of(dialogCtx).pop();
                  setState(() => _currentSubtitle = null);
                  _player.setSubtitleTrack(SubtitleTrack.no() as dynamic);
                },
              ),
              for (var sub in _availableSubtitles)
                ListTile(
                  title: Text(
                    '${sub.label} [${sub.extension.toUpperCase()}]',
                    style: TextStyle(
                      color: _currentSubtitle == sub ? TVColors.accent : Colors.white,
                      fontWeight: _currentSubtitle == sub ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: _currentSubtitle == sub
                      ? const Icon(Icons.check_rounded, color: TVColors.accent)
                      : null,
                  onTap: () {
                    Navigator.of(dialogCtx).pop();
                    setState(() => _currentSubtitle = sub);
                    _player.setSubtitleTrack(SubtitleTrack.uri(sub.fileUrl) as dynamic);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  KeyEventResult _handleGlobalKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      _resetOsdTimer();

      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _seekBy(-10);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _seekBy(10);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.mediaPlayPause ||
          event.logicalKey == LogicalKeyboardKey.space) {
        _togglePlayPause();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.escape ||
          event.logicalKey == LogicalKeyboardKey.backspace) {
        Navigator.of(context).pop();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: _playerScopeNode,
      onKeyEvent: (node, event) => _handleGlobalKey(event),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _resetOsdTimer,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // MediaKit Video Surface
              Center(
                child: Video(
                  controller: _controller,
                  controls: NoVideoControls,
                ),
              ),

              // Loading Spinner
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.7),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(color: TVColors.accent),
                        ),
                        SizedBox(height: 16),
                        Text('Buffering Stream...', style: TextStyle(color: Colors.white, fontSize: 15)),
                      ],
                    ),
                  ),
                ),

              // Error banner
              if (_errorMessage != null)
                Container(
                  color: Colors.black.withOpacity(0.85),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: TVColors.crimson, size: 50),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(backgroundColor: TVColors.accent),
                          child: const Text('Go Back', style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                  ),
                ),

              // On Screen Display (OSD) Overlay
              AnimatedOpacity(
                opacity: _showOsd ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: !_showOsd,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.85),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.92),
                        ],
                        stops: const [0.0, 0.25, 0.65, 1.0],
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top Header (Back, Title, Stream badge)
                        Row(
                          children: [
                            TVFocusable(
                              scaleOnFocus: 1.1,
                              borderRadius: BorderRadius.circular(8),
                              onPressed: () => Navigator.of(context).pop(),
                              builder: (context, isFocused) {
                                return Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isFocused ? TVColors.cardFocused : Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isFocused ? TVColors.focusBorder : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                                );
                              },
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.video.primaryTitle,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (widget.video.secondaryTitle.isNotEmpty)
                                    Text(
                                      widget.video.secondaryTitle,
                                      style: const TextStyle(
                                        color: TVColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (_currentStream != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: TVColors.accent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: TVColors.accent.withOpacity(0.6)),
                                ),
                                child: Text(
                                  _currentStream!.resolution.toUpperCase(),
                                  style: const TextStyle(
                                    color: TVColors.accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        // Bottom Controls
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Progress Slider & Timestamps
                            Row(
                              children: [
                                Text(
                                  _formatDuration(_position),
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: _duration.inMilliseconds > 0
                                          ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
                                          : 0.0,
                                      backgroundColor: Colors.white.withOpacity(0.2),
                                      valueColor: const AlwaysStoppedAnimation<Color>(TVColors.accent),
                                      minHeight: 6,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _formatDuration(_duration),
                                  style: const TextStyle(color: TVColors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Control buttons row (Rewind, Play/Pause, Fast Forward, Quality, Subtitle, Skip Intro)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Rewind -10s
                                _buildPlayerButton(
                                  icon: Icons.replay_10_rounded,
                                  label: '-10s',
                                  onPressed: () => _seekBy(-10),
                                ),
                                const SizedBox(width: 16),

                                // Play / Pause
                                _buildPlayerButton(
                                  focusNode: _playPauseFocus,
                                  icon: _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  label: _isPlaying ? 'Pause' : 'Play',
                                  isProminent: true,
                                  onPressed: _togglePlayPause,
                                ),
                                const SizedBox(width: 16),

                                // Forward +10s
                                _buildPlayerButton(
                                  icon: Icons.forward_10_rounded,
                                  label: '+10s',
                                  onPressed: () => _seekBy(10),
                                ),
                                const SizedBox(width: 24),

                                // Quality Selector
                                if (_availableStreams.isNotEmpty)
                                  _buildPlayerButton(
                                    icon: Icons.high_quality_rounded,
                                    label: _currentStream?.resolution ?? 'Quality',
                                    onPressed: _showQualityPicker,
                                  ),
                                const SizedBox(width: 16),

                                // Subtitle Selector
                                _buildPlayerButton(
                                  icon: Icons.subtitles_rounded,
                                  label: _currentSubtitle != null ? _currentSubtitle!.type.toUpperCase() : 'CC',
                                  onPressed: _showSubtitlePicker,
                                ),
                                const SizedBox(width: 16),

                                // Skip Intro (+85s)
                                _buildPlayerButton(
                                  icon: Icons.skip_next_rounded,
                                  label: 'Skip Intro',
                                  onPressed: () => _seekBy(85),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerButton({
    FocusNode? focusNode,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isProminent = false,
  }) {
    return TVFocusable(
      focusNode: focusNode,
      scaleOnFocus: 1.15,
      borderRadius: BorderRadius.circular(10),
      onPressed: onPressed,
      builder: (context, isFocused) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isProminent ? 22 : 14,
            vertical: isProminent ? 10 : 8,
          ),
          decoration: BoxDecoration(
            color: isFocused
                ? (isProminent ? Colors.white : TVColors.cardFocused)
                : (isProminent ? TVColors.accent : Colors.black.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isFocused
                  ? (isProminent ? Colors.white : TVColors.focusBorder)
                  : Colors.white.withOpacity(0.15),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isFocused
                    ? (isProminent ? Colors.black : TVColors.accent)
                    : (isProminent ? Colors.black : Colors.white),
                size: isProminent ? 24 : 18,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isFocused
                      ? (isProminent ? Colors.black : Colors.white)
                      : (isProminent ? Colors.black : Colors.white),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
