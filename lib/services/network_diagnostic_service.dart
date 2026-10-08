import 'dart:async';
import 'dart:io';

enum SpeedQualityRating {
  ultra4k,
  fhd1080p,
  hd720p,
  sd480p,
  failed,
}

class DiagnosticProgress {
  final String stage;
  final double progress; // 0.0 to 1.0
  final double currentSpeedMbps;
  final int? currentPingMs;

  const DiagnosticProgress({
    required this.stage,
    required this.progress,
    required this.currentSpeedMbps,
    this.currentPingMs,
  });
}

class DiagnosticResult {
  final int apiPingMs;
  final int cdnPingMs;
  final double downloadSpeedMbps;
  final SpeedQualityRating rating;
  final String title;
  final String description;
  final String recommendation;
  final bool isSuccess;

  const DiagnosticResult({
    required this.apiPingMs,
    required this.cdnPingMs,
    required this.downloadSpeedMbps,
    required this.rating,
    required this.title,
    required this.description,
    required this.recommendation,
    this.isSuccess = true,
  });

  factory DiagnosticResult.failure(String message) {
    return DiagnosticResult(
      apiPingMs: -1,
      cdnPingMs: -1,
      downloadSpeedMbps: 0.0,
      rating: SpeedQualityRating.failed,
      title: 'فشل الفحص • Test Failed',
      description: message,
      recommendation: 'تأكد من اتصال الجهاز بالإنترنت أو الراوتر الخاص بشبكتك.',
      isSuccess: false,
    );
  }
}

class NetworkDiagnosticService {
  static const String _apiPingUrl = 'https://cinemana.shabakaty.com/api/android/latestMovies/level/0/itemsPerPage/1/page/0/';
  static const String _cdnPingUrl = 'https://cdn.shabakaty.com/';

  static const List<String> _downloadTestUrls = [
    'https://cnth2.shabakaty.com/vascin-poster-images/02B8C976-7678-2B8F-F705-24DE1E99FDAD_poster.jpg',
    'https://cnth2.shabakaty.com/vascin-poster-images/7FB23F4B-5178-CA1F-390F-45C8FB315910_poster.jpg',
    'https://cnth2.shabakaty.com/vascin-poster-images/83558784-6AF1-FDEA-43BD-A25EF9BA02A4_poster_thumb.jpg',
    'https://cinemana.shabakaty.com/api/android/latestMovies/level/0/itemsPerPage/100/page/0/',
    'https://cinemana.shabakaty.com/api/android/latestSeries/level/0/itemsPerPage/100/page/0/',
  ];

  /// Execute complete network diagnostic and speed benchmark
  static Future<DiagnosticResult> runDiagnostics({
    void Function(DiagnosticProgress)? onProgress,
  }) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);

    try {
      // Step 1: Measure API Latency (Ping)
      onProgress?.call(const DiagnosticProgress(
        stage: 'قياس سرعة استجابة سيرفر سينمانا (API Ping)...',
        progress: 0.15,
        currentSpeedMbps: 0.0,
      ));

      int apiPing = 0;
      try {
        final sw = Stopwatch()..start();
        final req = await client.getUrl(Uri.parse(_apiPingUrl));
        final res = await req.close();
        await res.drain();
        sw.stop();
        apiPing = sw.elapsedMilliseconds;
      } catch (_) {
        apiPing = 999;
      }

      onProgress?.call(DiagnosticProgress(
        stage: 'قياس استجابة سيرفر الوسائط (CDN Ping)...',
        progress: 0.35,
        currentSpeedMbps: 0.0,
        currentPingMs: apiPing,
      ));

      // Step 2: Measure CDN Latency
      int cdnPing = 0;
      try {
        final sw = Stopwatch()..start();
        final req = await client.openUrl('HEAD', Uri.parse(_cdnPingUrl));
        final res = await req.close();
        await res.drain();
        sw.stop();
        cdnPing = sw.elapsedMilliseconds;
      } catch (_) {
        cdnPing = apiPing;
      }

      // Step 3: Measure Real Sustained Download Throughput (Mbps)
      onProgress?.call(DiagnosticProgress(
        stage: 'قياس سرعة التحميل الفعلي من سيرفرات الوسائط...',
        progress: 0.50,
        currentSpeedMbps: 0.0,
        currentPingMs: cdnPing,
      ));

      int totalBytesDownloaded = 0;
      final speedWatch = Stopwatch()..start();

      for (int i = 0; i < _downloadTestUrls.length; i++) {
        final url = _downloadTestUrls[i];
        try {
          final req = await client.getUrl(Uri.parse(url));
          final res = await req.close();
          await for (var chunk in res) {
            totalBytesDownloaded += chunk.length;
            final elapsedSec = speedWatch.elapsedMilliseconds / 1000.0;
            if (elapsedSec > 0.1) {
              final currentMbps = (totalBytesDownloaded * 8) / (elapsedSec * 1000000.0);
              final progressVal = 0.50 + ((i + 1) / _downloadTestUrls.length) * 0.45;
              onProgress?.call(DiagnosticProgress(
                stage: 'قياس سرعة تدفق البيانات (${currentMbps.toStringAsFixed(1)} Mbps)...',
                progress: progressVal.clamp(0.50, 0.95),
                currentSpeedMbps: currentMbps,
                currentPingMs: cdnPing,
              ));
            }
          }
        } catch (_) {}
      }
      speedWatch.stop();

      final totalSeconds = (speedWatch.elapsedMilliseconds / 1000.0).clamp(0.1, 60.0);
      final finalMbps = (totalBytesDownloaded * 8) / (totalSeconds * 1000000.0);

      onProgress?.call(DiagnosticProgress(
        stage: 'اكتمل الفحص بنجاح!',
        progress: 1.0,
        currentSpeedMbps: finalMbps,
        currentPingMs: cdnPing,
      ));

      // Step 4: Evaluate 4K and Streaming Capability
      SpeedQualityRating rating;
      String title;
      String description;
      String recommendation;

      if (finalMbps >= 25.0) {
        rating = SpeedQualityRating.ultra4k;
        title = 'ممتاز • 4K Ultra HD جاهز (2160p)';
        description = 'سرعة الاتصال والـ Ping فائقة ومثالية لتشغيل أفلام 4K Ultra HD بدون أي تقطيع وبأعلى بت-ريت.';
        recommendation = 'اتصالك ممتاز جداً! يمكنك الاستمتاع بدقة 4K مع تفعيل ميزة التخزين المؤقت 128MB.';
      } else if (finalMbps >= 15.0) {
        rating = SpeedQualityRating.fhd1080p;
        title = 'جيد جداً • 1080p Full HD فائق الاستقرار';
        description = 'سرعة ممتازة لدقة 1080p. دقة 4K قد تتطلب بضع ثوانٍ للتحميل المسبق في بداية المقطع.';
        recommendation = 'ننصح باختيار 1080p أو ترك الفيديو في وضع التوقف المؤقت لمدة 10 ثوانٍ عند بدء 4K.';
      } else if (finalMbps >= 8.0) {
        rating = SpeedQualityRating.hd720p;
        title = 'متوسط • 720p HD مستحسن';
        description = 'سرعة مناسبة لدقة 720p. دقة 4K ستعاني من تقطيع مستمر بسبب محدودية تدفق البيانات.';
        recommendation = 'يُفضل اختيار دقة 720p في الإعدادات أو توصيل التلفاز عبر كابل إيثرنت (LAN).';
      } else {
        rating = SpeedQualityRating.sd480p;
        title = 'ضعيف • 480p SD فقط';
        description = 'سرعة الاتصال بسيرفرات سينمانا بطيئة حالياً ولا تكفي لتشغيل الجودات العالية بسلاسة.';
        recommendation = 'تأكد من قرب التلفاز من الراوتر، واستخدم شبكة 5GHz بدلاً من 2.4GHz لتجنب التداخل.';
      }

      return DiagnosticResult(
        apiPingMs: apiPing,
        cdnPingMs: cdnPing,
        downloadSpeedMbps: finalMbps,
        rating: rating,
        title: title,
        description: description,
        recommendation: recommendation,
      );
    } catch (e) {
      return DiagnosticResult.failure('خطأ أثناء إجراء الاختبار: $e');
    } finally {
      client.close();
    }
  }
}
