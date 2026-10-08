import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class UpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String releaseName;
  final String releaseNotes;
  final String? apkDownloadUrl;
  final int? apkSize;

  UpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseName,
    required this.releaseNotes,
    this.apkDownloadUrl,
    this.apkSize,
  });
}

class UpdateService {
  static const String repoOwner = 'KyuJunior';
  static const String repoName = 'Cinemana-for-Tv';
  static const String apiUrl = 'https://api.github.com/repos/$repoOwner/$repoName/releases/latest';

  static const MethodChannel _channel = MethodChannel('com.cinemana.tv/app_updater');

  /// Compare two version strings (e.g. "v1.0.1" vs "1.0.0")
  static bool isNewerVersion(String current, String latest) {
    String cleanCur = current.replaceAll(RegExp(r'[^0-9.]'), '');
    String cleanLatest = latest.replaceAll(RegExp(r'[^0-9.]'), '');

    List<int> curParts = cleanCur.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> latestParts = cleanLatest.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    while (curParts.length < 3) {
      curParts.add(0);
    }
    while (latestParts.length < 3) {
      latestParts.add(0);
    }

    for (int i = 0; i < 3; i++) {
      if (latestParts[i] > curParts[i]) return true;
      if (latestParts[i] < curParts[i]) return false;
    }
    return false;
  }

  /// Check GitHub releases for a newer APK version
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version.isNotEmpty ? packageInfo.version : '1.0.0';

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'CinemanaTV-Updater',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final tagName = data['tag_name']?.toString() ?? '';
        final releaseName = data['name']?.toString() ?? tagName;
        final body = data['body']?.toString() ?? '';

        String? apkUrl;
        int? apkSize;

        if (data['assets'] is List) {
          for (var asset in data['assets']) {
            final name = asset['name']?.toString().toLowerCase() ?? '';
            if (name.endsWith('.apk')) {
              apkUrl = asset['browser_download_url']?.toString();
              apkSize = asset['size'] as int?;
              break;
            }
          }
        }

        final hasNewer = isNewerVersion(currentVersion, tagName);

        return UpdateInfo(
          hasUpdate: hasNewer,
          currentVersion: currentVersion,
          latestVersion: tagName.replaceAll('v', ''),
          releaseName: releaseName,
          releaseNotes: body,
          apkDownloadUrl: apkUrl,
          apkSize: apkSize,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking for update: $e');
      }
    }
    return null;
  }

  /// Download APK with progress tracking (0.0 to 1.0) and launch Android Package Installer
  static Future<bool> downloadAndInstall({
    required String downloadUrl,
    required void Function(double progress, int receivedBytes, int totalBytes) onProgress,
  }) async {
    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(downloadUrl));
      request.headers['User-Agent'] = 'CinemanaTV-Updater';

      final response = await client.send(request);

      if (response.statusCode != 200) {
        return false;
      }

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      final tempDir = await getTemporaryDirectory();
      final apkFile = File('${tempDir.path}/cinemana_update.apk');

      if (await apkFile.exists()) {
        await apkFile.delete();
      }

      final sink = apkFile.openWrite();

      await for (var chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          onProgress(receivedBytes / totalBytes, receivedBytes, totalBytes);
        }
      }

      await sink.flush();
      await sink.close();

      // Trigger Android Package Installer via native MethodChannel
      if (Platform.isAndroid) {
        final success = await _channel.invokeMethod<bool>('installApk', {
          'filePath': apkFile.path,
        });
        return success ?? false;
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to download and install update: $e');
      }
      return false;
    }
  }
}
