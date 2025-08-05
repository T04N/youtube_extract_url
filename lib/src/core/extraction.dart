import 'dart:convert';
import 'dart:io';

int? extractSignatureTimestamp(String js) {
  final regex = RegExp(r'(?:signatureTimestamp|sts)\s*:\s*([0-9]{5})');
  final match = regex.firstMatch(js);
  if (match != null && match.groupCount >= 1) {
    return int.tryParse(match.group(1)!);
  }
  return null;
}

Future<String?> fetchWatchHtml(String videoId) async {
  final url = 'https://www.youtube.com/watch?v=$videoId';
  final client = HttpClient();

  try {
    final request = await client.getUrl(Uri.parse(url));
    request.headers.set('User-Agent', 'Mozilla/5.0');
    final response = await request.close();
    final html = await response.transform(utf8.decoder).join();
    return html;
  } catch (e) {
    print('Error fetching HTML: $e');
    return null;
  } finally {
    client.close();
  }
}

String? extractJsUrlFromHtml(String html) {
  final regExp = RegExp(r'(/s/player/[\w\d]+/[\w\d_/.]+/base\.js)');
  final match = regExp.firstMatch(html);
  if (match != null) {
    return 'https://youtube.com${match.group(1)}';
  }
  return null;
}

Future<String?> fetchPlayerJs(String jsUrl) async {
  final client = HttpClient();

  try {
    final request = await client.getUrl(Uri.parse(jsUrl));
    request.headers.set('User-Agent', 'Mozilla/5.0');
    final response = await request.close();
    final js = await response.transform(utf8.decoder).join();
    return js;
  } catch (e) {
    print('Error fetching JavaScript: $e');
    return null;
  } finally {
    client.close();
  }
}

Future<Map<String, dynamic>?> fetchJsInfo(String videoId) async {
  final html = await fetchWatchHtml(videoId);
  if (html == null) return null;

  final jsUrl = extractJsUrlFromHtml(html);
  if (jsUrl == null) return null;

  final js = await fetchPlayerJs(jsUrl);
  if (js == null) return null;

  final signatureTimestamp = extractSignatureTimestamp(js);

  return {'js': js, 'signatureTimestamp': signatureTimestamp, 'html': html};
}
