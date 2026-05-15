import 'dart:io';

import 'package:http/http.dart' as http;

class DownloadProgress {
  const DownloadProgress({
    required this.downloadedBytes,
    required this.totalBytes,
  });

  final int downloadedBytes;
  final int? totalBytes;

  double? get percent {
    final t = totalBytes;
    if (t == null || t <= 0) return null;
    return (downloadedBytes / t).clamp(0.0, 1.0);
  }
}

class ModelDownloader {
  Future<void> downloadToFile({
    required Uri url,
    required File outputFile,
    void Function(DownloadProgress progress)? onProgress,
  }) async {
    if (await outputFile.exists()) {
      return;
    }

    await outputFile.parent.create(recursive: true);
    final tempFile = File('${outputFile.path}.partial');
    final already = await tempFile.exists() ? await tempFile.length() : 0;

    final request = http.Request('GET', url);
    if (already > 0) {
      // Resume support via HTTP Range
      request.headers['Range'] = 'bytes=$already-';
    }
    final response = await request.send();
    final ok = response.statusCode == 200 || response.statusCode == 206;
    if (!ok) {
      throw HttpException('Download failed: HTTP ${response.statusCode}');
    }

    // If we resumed, contentLength is remaining bytes; total becomes already+remaining.
    final remaining =
        (response.contentLength ?? 0) > 0 ? response.contentLength : null;
    final total =
        remaining == null ? null : (already > 0 ? already + remaining : remaining);

    final sink = tempFile.openWrite(mode: already > 0 ? FileMode.append : FileMode.write);
    var downloaded = already;
    try {
      await for (final chunk in response.stream) {
        downloaded += chunk.length;
        sink.add(chunk);
        if (onProgress != null) {
          onProgress(DownloadProgress(
            downloadedBytes: downloaded,
            totalBytes: total,
          ));
        }
      }
    } finally {
      await sink.flush();
      await sink.close();
    }

    await tempFile.rename(outputFile.path);
  }
}

