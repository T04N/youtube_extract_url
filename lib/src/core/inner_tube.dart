import 'dart:convert';
import 'dart:io';

/// Client configuration
class Client {
  final String name;
  final String version;
  final String apiKey;
  final String userAgent;

  const Client({
    required this.name,
    required this.version,
    required this.apiKey,
    required this.userAgent,
  });
}

/// Simple InnerTube API client
class InnerTube {
  static const Map<String, Client> _clients = {
    'ios': Client(
      name: 'IOS',
      version: '20.10.4',
      apiKey: 'AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8',
      userAgent:
          'com.google.ios.youtube/20.10.4 (iPhone16,2; U; CPU iOS 18_3_2 like Mac OS X;)',
    ),
    'android': Client(
      name: 'ANDROID',
      version: '19.09.37',
      apiKey: 'AIzaSyA8eiZmM1FaDVjRy-df2KTyQ_vz_yYM39w',
      userAgent:
          'com.google.android.youtube/19.09.37 (Linux; U; Android 11) gzip',
    ),
  };

  final String _clientType;
  final String _visitorData;

  InnerTube({required String clientType, required String visitorData})
    : _clientType = clientType,
      _visitorData = visitorData;

  Client get _client => _clients[_clientType] ?? _clients['ios']!;

  /// Get player data
  Future<Map<String, dynamic>> player(String videoId) async {
    const endpoint = 'https://www.youtube.com/youtubei/v1/player';
    final query = <String, String>{
      'key': _client.apiKey,
      'prettyPrint': 'false',
    };

    final request = _buildPlayerRequest(videoId);
    return await _callAPI(endpoint, query, request);
  }

  /// Build request payload
  Map<String, dynamic> _buildPlayerRequest(String videoId) {
    return {
      'context': {
        'client': {
          'clientName': _client.name,
          'clientVersion': _client.version,
          'hl': 'en',
          'gl': 'US',
          'timeZone': 'UTC',
          'utcOffsetMinutes': 0,
          'userAgent': _client.userAgent,
          'osName': 'iOS',
          'osVersion': '18.0',
          'visitorData': _visitorData,
        },
        'user': {'lockedSafetyMode': false},
        'request': {
          'useSsl': true,
          'internalExperimentFlags': [],
          'consistencyTokenJars': [],
        },
      },
      'videoId': videoId,
      'playbackContext': {
        'contentPlaybackContext': {'html5Preference': 'HTML5_PREF_WANTS'},
      },
      'contentCheckOk': true,
      'racyCheckOk': true,
    };
  }

  /// Call API
  Future<Map<String, dynamic>> _callAPI(
    String endpoint,
    Map<String, String> query,
    Map<String, dynamic> object,
  ) async {
    final uri = Uri.parse(endpoint).replace(queryParameters: query);
    final client = HttpClient();

    try {
      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('User-Agent', _client.userAgent);
      request.headers.set('X-Goog-Visitor-Id', _visitorData);
      request.headers.set('Origin', 'https://www.youtube.com');

      final data = utf8.encode(json.encode(object));
      request.add(data);

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        return json.decode(responseBody) as Map<String, dynamic>;
      } else {
        throw HttpException('API call failed: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }
}
