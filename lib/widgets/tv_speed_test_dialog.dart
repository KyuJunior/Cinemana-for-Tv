import 'package:flutter/material.dart';
import '../services/network_diagnostic_service.dart';
import '../theme/tv_theme.dart';
import 'tv_focusable.dart';

class TVSpeedTestDialog extends StatefulWidget {
  const TVSpeedTestDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const TVSpeedTestDialog(),
    );
  }

  @override
  State<TVSpeedTestDialog> createState() => _TVSpeedTestDialogState();
}

class _TVSpeedTestDialogState extends State<TVSpeedTestDialog> {
  bool _isRunning = false;
  DiagnosticProgress? _progress;
  DiagnosticResult? _result;

  @override
  void initState() {
    super.initState();
    _startTest();
  }

  Future<void> _startTest() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _result = null;
      _progress = const DiagnosticProgress(
        stage: 'جاري بدء فحص الاتصال بسينمانا...',
        progress: 0.05,
        currentSpeedMbps: 0.0,
      );
    });

    final res = await NetworkDiagnosticService.runDiagnostics(
      onProgress: (p) {
        if (mounted) {
          setState(() => _progress = p);
        }
      },
    );

    if (mounted) {
      setState(() {
        _isRunning = false;
        _result = res;
      });
    }
  }

  Color _getRatingColor(SpeedQualityRating? rating) {
    switch (rating) {
      case SpeedQualityRating.ultra4k:
        return Colors.greenAccent;
      case SpeedQualityRating.fhd1080p:
        return Colors.cyanAccent;
      case SpeedQualityRating.hd720p:
        return Colors.amberAccent;
      case SpeedQualityRating.sd480p:
        return Colors.orangeAccent;
      case SpeedQualityRating.failed:
      default:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratingColor = _getRatingColor(_result?.rating);

    return Dialog(
      backgroundColor: TVColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 640,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: TVColors.card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.speed_rounded, color: TVColors.accent, size: 26),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'فحص سرعة وبينغ سيرفرات سينمانا • Cinemana Diagnostics',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'قياس مدى جاهزية اتصالك لتشغيل دقة 4K Ultra HD',
                        style: TextStyle(color: TVColors.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Live Gauge / Metrics Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: TVColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _result != null ? ratingColor.withOpacity(0.35) : TVColors.accent.withOpacity(0.15),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Download Speed
                      Column(
                        children: [
                          const Text(
                            'سرعة التحميل • Download',
                            style: TextStyle(color: TVColors.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _result != null
                                    ? _result!.downloadSpeedMbps.toStringAsFixed(1)
                                    : (_progress?.currentSpeedMbps ?? 0.0).toStringAsFixed(1),
                                style: TextStyle(
                                  color: _result != null ? ratingColor : Colors.white,
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Mbps',
                                style: TextStyle(color: TVColors.textMuted, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),

                      Container(width: 1, height: 50, color: Colors.white12),

                      // API Ping
                      Column(
                        children: [
                          const Text(
                            'بينغ السيرفر • API Ping',
                            style: TextStyle(color: TVColors.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _result != null
                                    ? '${_result!.apiPingMs}'
                                    : (_progress?.currentPingMs != null ? '${_progress!.currentPingMs}' : '--'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'ms',
                                style: TextStyle(color: TVColors.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),

                      Container(width: 1, height: 50, color: Colors.white12),

                      // CDN Ping
                      Column(
                        children: [
                          const Text(
                            'بينغ الوسائط • CDN Ping',
                            style: TextStyle(color: TVColors.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _result != null ? '${_result!.cdnPingMs}' : '--',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'ms',
                                style: TextStyle(color: TVColors.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _isRunning ? (_progress?.progress ?? 0.1) : 1.0,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _result != null ? ratingColor : TVColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isRunning
                        ? (_progress?.stage ?? 'جاري الفحص...')
                        : (_result != null ? 'اكتمل الفحص بنجاح' : 'جاهز'),
                    style: const TextStyle(color: TVColors.textMuted, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Verdict and Recommendations
            if (_result != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ratingColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ratingColor.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _result!.rating == SpeedQualityRating.ultra4k
                              ? Icons.verified_rounded
                              : Icons.info_rounded,
                          color: ratingColor,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _result!.title,
                            style: TextStyle(
                              color: ratingColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _result!.description,
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'نصيحة • Tip: ${_result!.recommendation}',
                      style: const TextStyle(color: TVColors.textSecondary, fontSize: 12, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
            ],

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TVFocusable(
                  borderRadius: BorderRadius.circular(8),
                  onPressed: () => Navigator.of(context).pop(),
                  builder: (context, isFocused) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isFocused ? Colors.white24 : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Text(
                        'إغلاق • Close',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                TVFocusable(
                  autoFocus: true,
                  borderRadius: BorderRadius.circular(8),
                  onPressed: _isRunning ? null : _startTest,
                  builder: (context, isFocused) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        color: isFocused ? Colors.white : TVColors.accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isRunning) ...[
                            SizedBox(
                              width: 16,
                              height: 16,
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
                            _isRunning ? 'جاري الفحص...' : 'إعادة الفحص • Test Again',
                            style: TextStyle(
                              color: isFocused ? Colors.black : Colors.white,
                              fontSize: 14,
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
          ],
        ),
      ),
    );
  }
}
