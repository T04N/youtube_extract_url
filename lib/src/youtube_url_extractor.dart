import 'core/extraction.dart';
import 'core/cipher.dart';
import 'core/inner_tube.dart';
import 'models/video_url.dart';

/// Main YouTube URL Extractor
class YoutubeUrlExtractor {
  /// Get list of downloadable video URLs
  Future<List<VideoUrl>> extractUrls(String videoId) async {
    try {
      // 1. Get JavaScript information
      final jsInfo = await fetchJsInfo(videoId);
      if (jsInfo == null) {
        throw Exception('Unable to get JavaScript information');
      }

      // 2. Create InnerTube client
      final innertube = InnerTube(
        clientType: 'ios',
        visitorData: 'CgtvVjBfVXp1Z0FvWSiImZ6JbjIG',
      );

      // 3. Get player data
      final playerData = await innertube.player(videoId);

      // Check for common response structures
      if (playerData.containsKey('error')) {
        throw Exception('Player API returned error: ${playerData['error']}');
      }

      // 4. Process streaming data
      final streamingData = playerData['streamingData'];
      if (streamingData == null) {
        if (playerData.containsKey('playabilityStatus')) {
          final status = playerData['playabilityStatus'];
          if (status['status'] == 'LOGIN_REQUIRED') {
            throw Exception('Authentication required: ${status['reason']}');
          }
        }
        throw Exception('Streaming data not found');
      }

      // 5. Extract URLs
      final urls = <VideoUrl>[];

      // Process formats
      if (streamingData['formats'] != null) {
        for (var format in streamingData['formats']) {
          final url = _processFormat(format, jsInfo['js']);
          if (url != null) {
            urls.add(url);
          }
        }
      }

      // Process adaptiveFormats
      if (streamingData['adaptiveFormats'] != null) {
        for (var format in streamingData['adaptiveFormats']) {
          final url = _processFormat(format, jsInfo['js']);
          if (url != null) {
            urls.add(url);
          }
        }
      }

      return urls;
    } catch (e) {
      print('Error extracting URLs: $e');
      return [];
    }
  }

  /// Process format and create VideoUrl
  VideoUrl? _processFormat(Map<String, dynamic> format, String jsCode) {
    try {
      String? url = format['url'];

      // Process signatureCipher if needed
      if (url == null && format['signatureCipher'] != null) {
        final cipher = _parseSignatureCipher(format['signatureCipher']);
        url = cipher['url'];

        // Decrypt signature if needed
        if (cipher['s'] != null) {
          final cipherInstance = Cipher(jsCode);
          final signature = cipherInstance.getSignature(cipher['s']!);
          if (signature != null) {
            final separator = url!.contains('?') ? '&' : '?';
            url = '$url$separator${cipher['sp']}=$signature';
          }
        }
      }

      if (url == null) return null;

      return VideoUrl(
        url: url,
        quality: format['quality'] ?? 'unknown',
        mimeType: format['mimeType'] ?? '',
        bitrate: format['bitrate'],
        width: format['width'],
        height: format['height'],
        contentLength: format['contentLength'],
      );
    } catch (e) {
      print('Error processing format: $e');
      return null;
    }
  }

  /// Parse signatureCipher
  Map<String, String> _parseSignatureCipher(String signatureCipher) {
    final result = <String, String>{};
    final pairs = signatureCipher.split('&');

    for (final pair in pairs) {
      final keyValue = pair.split('=');
      if (keyValue.length == 2) {
        final key = Uri.decodeComponent(keyValue[0]);
        final value = Uri.decodeComponent(keyValue[1]);
        result[key] = value;
      }
    }

    return result;
  }
}
