import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import '../models/video_item.dart';
import '../models/video_stream.dart';
import '../models/subtitle_track.dart';
import '../models/intro_interval.dart';
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

class _TVPlayerScreenState extends State<TVPlayerScreen> with WidgetsBindingObserver {
  late final Player _player;
  late final VideoController _controller;

  bool _isLoading = true;
  String? _errorMessage;

  List<VideoStream> _availableStreams = [];
  VideoStream? _currentStream;

  List<CinemanaSubtitle> _availableSubtitles = [];
  CinemanaSubtitle? _currentSubtitle;

  IntroInterval? _introInterval;
  bool _showSkipIntro = false;

  bool _showOsd = true;
  Timer? _osdTimer;
  Timer? _progressSaveTimer;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isExiting = false;

  final FocusNode _playPauseFocus = FocusNode();
  final FocusNode _seekbarFocus = FocusNode();
  final FocusNode _backButtonFocus = FocusNode();
  final FocusScopeNode _playerScopeNode = FocusScopeNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final storage = Provider.of<StorageService>(context, listen: false);
    final bufferBytes = storage.bufferSizeMb * 1024 * 1024;

    _player = Player(
      configuration: PlayerConfiguration(
        bufferSize: bufferBytes,
        logLevel: MPVLogLevel.error,
      ),
    );
    _controller = VideoController(
      _player,
      configuration: VideoControllerConfiguration(
        hwdec: storage.hardwareDecoding,
        enableHardwareAcceleration: true,
      ),
    );

    _player.stream.position.listen((pos) {
      if (mounted) {
        final curSec = pos.inMilliseconds / 1000.0;
        final inIntro = _introInterval != null && _introInterval!.contains(curSec);
        setState(() {
          _position = pos;
          _showSkipIntro = inIntro;
        });
      }
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _player.pause();
      _saveProgress();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveProgress();
    _osdTimer?.cancel();
    _progressSaveTimer?.cancel();
    _playPauseFocus.dispose();
    _seekbarFocus.dispose();
    _backButtonFocus.dispose();
    _playerScopeNode.dispose();
    try {
      _player.pause();
      _player.stop();
      _player.dispose();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _exitPlayer() async {
    if (_isExiting) return;
    _isExiting = true;
    _saveProgress();
    _osdTimer?.cancel();
    _progressSaveTimer?.cancel();
    try {
      await _player.pause();
      await _player.stop();
    } catch (_) {}
    if (mounted) {
      Navigator.of(context).pop();
    }
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
      final introFuture = CinemanaApiService.getIntroInterval(widget.video.id);

      final streams = await streamsFuture;
      final subs = await subsFuture;
      final intro = await introFuture;

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
      _introInterval = intro;

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
    try {
      final dynamic nativePlatform = _player.platform;
      if (nativePlatform != null) {
        final storage = context.read<StorageService>();
        final bufferBytes = storage.bufferSizeMb * 1024 * 1024;
        await nativePlatform.setProperty('demuxer-max-bytes', bufferBytes.toString());
        await nativePlatform.setProperty('demuxer-max-back-bytes', (bufferBytes ~/ 2).toString());
        await nativePlatform.setProperty('demuxer-readahead-secs', '45');
        await nativePlatform.setProperty('cache-secs', '45');
        await nativePlatform.setProperty('network-timeout', '15');
        await nativePlatform.setProperty('stream-buffer-size', '4194304');
        await nativePlatform.setProperty('force-seekable', 'yes');
        await nativePlatform.setProperty('hr-seek', 'no');
        await nativePlatform.setProperty('hr-seek-framedrop', 'yes');
        await nativePlatform.setProperty('vd-lavc-threads', '4');
      }
    } catch (_) {}

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

  void _skipIntro() {
    if (_introInterval != null) {
      _resetOsdTimer();
      _player.seek(Duration(milliseconds: (_introInterval!.end * 1000).toInt()));
      setState(() => _showSkipIntro = false);
    }
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
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // When OSD is hidden:
    if (!_showOsd) {
      if (event.logicalKey == LogicalKeyboardKey.escape ||
          event.logicalKey == LogicalKeyboardKey.backspace) {
        _exitPlayer();
        return KeyEventResult.handled;
      }
      // Any other remote key reveals OSD and focuses Play/Pause
      _resetOsdTimer();
      _playPauseFocus.requestFocus();
      return KeyEventResult.handled;
    }

    // Keep OSD awake on remote activity
    _resetOsdTimer();

    // Dedicated remote media keys
    if (event.logicalKey == LogicalKeyboardKey.mediaPlayPause ||
        event.logicalKey == LogicalKeyboardKey.space) {
      _togglePlayPause();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.mediaFastForward) {
      _seekBy(10);
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.mediaRewind) {
      _seekBy(-10);
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      _exitPlayer();
      return KeyEventResult.handled;
    }

    // Left, Right, Up, Down, Select are handled by the currently focused widget
    return KeyEventResult.ignored;
  }

  Widget _buildSeekBar() {
    final double progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return TVFocusable(
      focusNode: _seekbarFocus,
      scaleOnFocus: 1.0,
      showGlow: false,
      onKeyLeft: () => _seekBy(-10),
      onKeyRight: () => _seekBy(10),
      onPressed: _togglePlayPause,
      builder: (context, isFocused) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isFocused)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: TVColors.accent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: TVColors.accent.withOpacity(0.6),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_left_rounded, size: 18, color: Colors.black),
                        Text(
                          '◄ -10s   ${_formatDuration(_position)} / ${_formatDuration(_duration)}   +10s ►',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(Icons.arrow_right_rounded, size: 18, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              Row(
                children: [
                  Text(
                    _formatDuration(_position),
                    style: TextStyle(
                      color: isFocused ? TVColors.accent : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final fillWidth = (progress * width).clamp(0.0, width);
                        return Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.centerLeft,
                          children: [
                            Container(
                              width: width,
                              height: isFocused ? 8 : 5,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Container(
                              width: fillWidth,
                              height: isFocused ? 8 : 5,
                              decoration: BoxDecoration(
                                color: TVColors.accent,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: isFocused
                                    ? [
                                        BoxShadow(
                                          color: TVColors.accent.withOpacity(0.9),
                                          blurRadius: 10,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            if (isFocused)
                              Positioned(
                                left: (fillWidth - 8).clamp(0.0, width - 16),
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: TVColors.accent, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: TVColors.accent.withOpacity(0.9),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    _formatDuration(_duration),
                    style: const TextStyle(color: TVColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _exitPlayer();
      },
      child: FocusScope(
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
                            onPressed: _exitPlayer,
                            style: ElevatedButton.styleFrom(backgroundColor: TVColors.accent),
                            child: const Text('Go Back', style: TextStyle(color: Colors.black)),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Floating Skip Intro button when OSD is hidden
                if (!_showOsd && _showSkipIntro && _introInterval != null)
                  Positioned(
                    bottom: 40,
                    right: 50,
                    child: TVFocusable(
                      scaleOnFocus: 1.1,
                      borderRadius: BorderRadius.circular(10),
                      onPressed: _skipIntro,
                      builder: (context, isFocused) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: isFocused ? Colors.white : Colors.black.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isFocused ? TVColors.focusBorder : TVColors.accent,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: TVColors.accent.withOpacity(0.4),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.skip_next_rounded,
                                color: isFocused ? Colors.black : TVColors.accent,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'تخطي المقدمة • Skip Intro',
                                style: TextStyle(
                                  color: isFocused ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
                                focusNode: _backButtonFocus,
                                scaleOnFocus: 1.1,
                                borderRadius: BorderRadius.circular(8),
                                onPressed: _exitPlayer,
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

                          // Bottom Controls (Seekbar + Control Buttons)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Focusable Seekbar
                              _buildSeekBar(),
                              const SizedBox(height: 12),

                              // Control buttons row:
                              // Left / Right naturally moves focus between these buttons!
                              // Up moves focus to the Seekbar!
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
                                    label: _isPlaying ? 'إيقاف • Pause' : 'تشغيل • Play',
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
                                  if (_availableStreams.isNotEmpty) ...[
                                    _buildPlayerButton(
                                      icon: Icons.high_quality_rounded,
                                      label: _currentStream?.resolution ?? 'الجودة',
                                      onPressed: _showQualityPicker,
                                    ),
                                    const SizedBox(width: 16),
                                  ],

                                  // Subtitle Selector
                                  _buildPlayerButton(
                                    icon: Icons.subtitles_rounded,
                                    label: _currentSubtitle != null ? _currentSubtitle!.type.toUpperCase() : 'الترجمة',
                                    onPressed: _showSubtitlePicker,
                                  ),

                                  // Skip Intro (Only visible if video has skippable intro AND in intro interval)
                                  if (_showSkipIntro && _introInterval != null) ...[
                                    const SizedBox(width: 16),
                                    _buildPlayerButton(
                                      icon: Icons.skip_next_rounded,
                                      label: 'تخطي المقدمة • Skip Intro',
                                      isProminent: true,
                                      onPressed: _skipIntro,
                                    ),
                                  ],
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
                    : Colors.white,
                size: isProminent ? 24 : 18,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isFocused
                      ? (isProminent ? Colors.black : Colors.white)
                      : Colors.white,
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
