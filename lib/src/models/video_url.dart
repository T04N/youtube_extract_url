/// Model containing video URL information
class VideoUrl {
  final String url;
  final String quality;
  final String mimeType;
  final int? bitrate;
  final int? width;
  final int? height;
  final String? contentLength;

  VideoUrl({
    required this.url,
    required this.quality,
    required this.mimeType,
    this.bitrate,
    this.width,
    this.height,
    this.contentLength,
  });

  @override
  String toString() {
    return 'VideoUrl(url: $url, quality: $quality, mimeType: $mimeType)';
  }
}
