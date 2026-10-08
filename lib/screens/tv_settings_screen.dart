import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
  String _updateStatus = 'الإصدار الحالي: v1.0.2 • Version 1.0.2';
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatusText = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _updateStatus = 'الإصدار الحالي: v${info.version} • Version ${info.version}';
        });
      }
    } catch (_) {}
  }

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
              'الإعدادات • Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'تخصيص جودة الفيديو، التحديثات، والتفضيلات • Customize video quality, updates, and preferences',
              style: TextStyle(color: TVColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 28),

            // In-App Software Update Section
            _buildSection(
              title: 'تحديثات التطبيق • Software Updates',
              subtitle: 'التحقق من الإصدارات الجديدة عبر GitHub Releases',
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
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: isFocused ? Colors.black : Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ] else ...[
                                Icon(
                                  Icons.refresh_rounded,
                                  size: 18,
                                  color: isFocused ? Colors.black : Colors.white,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                _isCheckingUpdate ? 'جاري الفحص • Checking...' : 'فحص التحديثات • Check Updates',
                                style: TextStyle(
                                  color: isFocused ? Colors.black : Colors.white,
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
              title: 'جودة الفيديو الافتراضية • Default Video Quality',
              subtitle: 'الدقة المفضلة عند بدء التشغيل • Preferred playback resolution',
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
              title: 'لغة الترجمة المفضلة • Preferred Subtitles',
              subtitle: 'تحديد لغة الترجمة التلقائية • Automatic subtitle track',
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
              title: 'المستوى العائلي • Parental Guidance',
              subtitle: 'فلترة المحتوى حسب التصنيف العمري • Filter content by maturity rating',
              child: Row(
                children: [
                  _buildChoiceChip(
                    label: 'المستوى 0 (مفتوح / غير مقيد • All)',
                    isSelected: storage.parentalLevel == 0,
                    onSelect: () => storage.setParentalLevel(0),
                  ),
                  const SizedBox(width: 12),
                  _buildChoiceChip(
                    label: 'المستوى 1 (عائلي • PG-13)',
                    isSelected: storage.parentalLevel == 1,
                    onSelect: () => storage.setParentalLevel(1),
                  ),
                  const SizedBox(width: 12),
                  _buildChoiceChip(
                    label: 'المستوى 2 (أطفال • Kids Safe)',
                    isSelected: storage.parentalLevel == 2,
                    onSelect: () => storage.setParentalLevel(2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Network & Diagnostics
            _buildSection(
              title: 'حالة الشبكة والاتصال • Network & ISP Status',
              subtitle: 'التحقق من الاتصال بشبكة سينمانا وسيرفرات شبكتي • Earthlink / Shabakaty CDN',
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
                          'سيرفر سينمانا (cinemana.shabakaty.com): متصل • Connected',
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
                          'سيرفر الوسائط عالي السرعة (cdn.shabakaty.com): نشط • Online',
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
                          'محرك العرض: Flutter Leanback TV مع MediaKit (libmpv عتادي)',
                          style: TextStyle(color: TVColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Legal & Privacy Notice
            _buildSection(
              title: 'إشعار الشروط والخصوصية • Legal & Privacy Notice',
              subtitle: 'معلومات الترخيص والاستخدام القانوني • Terms of service & privacy details',
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: TVColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.policy_rounded, color: TVColors.textMuted, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'سياسة الاستخدام وحقوق الملكية • Terms of Service',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      'تطبيق سينمانا للتلفاز (Cinemana for TV) هو عميل تشغيل مخصص للوصول إلى شبكة سينمانا التابعة لشركة شبكتي / إيرثلنك عبر الشبكات المحلية المعتمدة. جميع حقوق الملكية الفكرية والعلامات التجارية والمحتوى الإعلامي تعود لأصحابها الأصليين. هذا التطبيق مفتوح المصدر ومستقل ولا يقوم باستضافة أو تخزين أي مواد رقمية على خوادم خاصة به.',
                      style: TextStyle(color: TVColors.textSecondary, fontSize: 12.5, height: 1.5),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Cinemana for TV is a client designed for accessing Shabakaty Cinemana services within authorized ISP networks. All trademarks, logos, and media assets belong to their respective copyright owners. This application is an independent open-source client that does not host or distribute media directly.',
                      style: TextStyle(color: TVColors.textMuted, fontSize: 11.5, height: 1.4),
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
