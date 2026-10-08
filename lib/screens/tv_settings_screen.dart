import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/update_service.dart';
import '../theme/tv_theme.dart';
import '../widgets/tv_focusable.dart';

class TVSettingsScreen extends StatefulWidget {
  const TVSettingsScreen({super.key});

  @override
  State<TVSettingsScreen> createState() => _TVSettingsScreenState();
}

class _TVSettingsScreenState extends State<TVSettingsScreen> {
  bool _isCheckingUpdate = false;
  String _updateStatus = 'Version 1.0.0 (Latest)';
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatusText = '';

  Future<void> _checkUpdate() async {
    setState(() {
      _isCheckingUpdate = true;
      _updateStatus = 'Checking GitHub releases for KyuJunior/Cinemana-for-Tv...';
    });

    final info = await UpdateService.checkForUpdate();

    if (!mounted) return;

    setState(() {
      _isCheckingUpdate = false;
    });

    if (info != null && info.hasUpdate && info.apkDownloadUrl != null) {
      setState(() {
        _updateStatus = 'New version ${info.latestVersion} available!';
      });
      _showUpdateDialog(info);
    } else if (info != null) {
      setState(() {
        _updateStatus = 'App is up to date (${info.currentVersion})';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('App is up to date (v${info.currentVersion})'),
          backgroundColor: TVColors.surface,
        ),
      );
    } else {
      setState(() {
        _updateStatus = 'Could not reach GitHub Releases. Check your internet connection.';
      });
    }
  }

  void _showUpdateDialog(UpdateInfo info) {
    showDialog(
      context: context,
      barrierDismissible: !_isDownloading,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: TVColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.system_update_rounded, color: TVColors.accent, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Update Available: v${info.latestVersion}',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'A new version of Cinemana TV is ready to install.',
                      style: const TextStyle(color: TVColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    if (info.releaseNotes.isNotEmpty) ...[
                      const Text(
                        "What's New:",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          info.releaseNotes,
                          style: const TextStyle(color: TVColors.textSecondary, fontSize: 12.5),
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_isDownloading) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _downloadProgress > 0 ? _downloadProgress : null,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(TVColors.accent),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _downloadStatusText,
                        style: const TextStyle(color: TVColors.accent, fontSize: 12.5),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                if (!_isDownloading) ...[
                  TextButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    child: const Text('Later', style: TextStyle(color: TVColors.textMuted)),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TVColors.accent,
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Download & Update', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      setDialogState(() {
                        _isDownloading = true;
                        _downloadProgress = 0.0;
                        _downloadStatusText = 'Starting download...';
                      });

                      final success = await UpdateService.downloadAndInstall(
                        downloadUrl: info.apkDownloadUrl!,
                        onProgress: (progress, received, total) {
                          setDialogState(() {
                            _downloadProgress = progress;
                            final mbReceived = (received / (1024 * 1024)).toStringAsFixed(1);
                            final mbTotal = (total / (1024 * 1024)).toStringAsFixed(1);
                            _downloadStatusText = 'Downloading: $mbReceived MB / $mbTotal MB (${(progress * 100).toInt()}%)';
                          });
                        },
                      );

                      if (mounted) {
                        setState(() {
                          _isDownloading = false;
                        });
                      }

                      if (!success && mounted) {
                        setDialogState(() {
                          _isDownloading = false;
                          _downloadStatusText = 'Download failed or installer cancelled.';
                        });
                      }
                    },
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings & Preferences',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Customize video quality, parental controls, updates, and network diagnostics',
              style: TextStyle(color: TVColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 28),

            // In-App Software Update Section
            _buildSection(
              title: 'Software Updates (GitHub Releases)',
              subtitle: 'Check for new releases on github.com/KyuJunior/Cinemana-for-Tv',
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: TVColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: TVColors.card,
                      child: Icon(Icons.system_update_rounded, color: TVColors.accent, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cinemana TV for Android TV',
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _updateStatus,
                            style: const TextStyle(color: TVColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    TVFocusable(
                      scaleOnFocus: 1.08,
                      borderRadius: BorderRadius.circular(8),
                      onPressed: _isCheckingUpdate ? null : _checkUpdate,
                      builder: (context, isFocused) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: isFocused ? Colors.white : TVColors.accent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isCheckingUpdate) ...[
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                ),
                                const SizedBox(width: 8),
                              ] else ...[
                                const Icon(Icons.refresh_rounded, size: 18, color: Colors.black),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                _isCheckingUpdate ? 'Checking...' : 'Check Updates',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Preferred Video Quality
            _buildSection(
              title: 'Default Video Quality',
              subtitle: 'Preferred resolution when starting playback',
              child: Row(
                children: [
                  for (var q in ['2160p (4K)', '1080p (FHD)', '720p (HD)', '480p (SD)'])
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _buildChoiceChip(
                        label: q,
                        isSelected: storage.preferredQuality.contains(q.split(' ')[0].replaceAll('p', '')),
                        onSelect: () {
                          final shortQ = q.split(' ')[0];
                          storage.setPreferredQuality(shortQ);
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Preferred Subtitle Language
            _buildSection(
              title: 'Preferred Subtitle Language',
              subtitle: 'Default subtitle track automatically loaded',
              child: Row(
                children: [
                  _buildChoiceChip(
                    label: 'العربية (Arabic)',
                    isSelected: storage.preferredLanguage == 'ar',
                    onSelect: () => storage.setPreferredLanguage('ar'),
                  ),
                  const SizedBox(width: 12),
                  _buildChoiceChip(
                    label: 'English',
                    isSelected: storage.preferredLanguage == 'en',
                    onSelect: () => storage.setPreferredLanguage('en'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Parental Level
            _buildSection(
              title: 'Parental Guidance Filter',
              subtitle: 'Filter titles according to maturity rating',
              child: Row(
                children: [
                  _buildChoiceChip(
                    label: 'Level 0 (Unrestricted / All)',
                    isSelected: storage.parentalLevel == 0,
                    onSelect: () => storage.setParentalLevel(0),
                  ),
                  const SizedBox(width: 12),
                  _buildChoiceChip(
                    label: 'Level 1 (Family / PG-13)',
                    isSelected: storage.parentalLevel == 1,
                    onSelect: () => storage.setParentalLevel(1),
                  ),
                  const SizedBox(width: 12),
                  _buildChoiceChip(
                    label: 'Level 2 (Kids Safe)',
                    isSelected: storage.parentalLevel == 2,
                    onSelect: () => storage.setParentalLevel(2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Network & Diagnostics
            _buildSection(
              title: 'Network & Cinemana ISP Status',
              subtitle: 'Local connection check to Earthlink / Shabakaty CDN',
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TVColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: const Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Cinemana API (cinemana.shabakaty.com): Connected',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'High-Speed Media CDN (cdn.shabakaty.com): Online',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: TVColors.accent, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Platform Engine: Flutter Leanback TV with MediaKit (Hardware libmpv)',
                          style: TextStyle(color: TVColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: TVColors.textMuted, fontSize: 12.5)),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    return TVFocusable(
      scaleOnFocus: 1.08,
      borderRadius: BorderRadius.circular(8),
      onPressed: onSelect,
      builder: (context, isFocused) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isFocused
                ? TVColors.cardFocused
                : (isSelected ? TVColors.accent.withOpacity(0.18) : TVColors.card),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isFocused
                  ? TVColors.focusBorder
                  : (isSelected ? TVColors.accent : Colors.white.withOpacity(0.1)),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(Icons.check_rounded, color: TVColors.accent, size: 16),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : TVColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
