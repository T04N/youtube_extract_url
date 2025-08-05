import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Class for handling signature decryption
class Cipher {
  final String jsCode;
  WebViewController? _webViewController;
  bool _isWebViewInitialized = false;

  Cipher(this.jsCode) {
    _initializeWebView();
  }

  /// Initialize WebView
  Future<void> _initializeWebView() async {
    try {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (url) {
              _isWebViewInitialized = true;
            },
          ),
        );

      final htmlContent = _generateHtmlContent();
      await _webViewController!.loadHtmlString(htmlContent);
    } catch (e) {
      print('Error initializing WebView: $e');
    }
  }

  /// Generate HTML content with JavaScript
  String _generateHtmlContent() {
    return '''
    <!DOCTYPE html>
    <html>
    <head><title>JS Runner</title></head>
    <body>
      <script>
        $jsCode
        window.processNSignature = function(n) {
          try {
            return n.split("").reverse().join(""); // Simplified
          } catch (e) {
            return "Error: " + e.toString();
          }
        };
      </script>
    </body>
    </html>
    ''';
  }

  /// Calculate parameter 'n'
  Future<String> calculateN(String initialN) async {
    if (!_isWebViewInitialized || _webViewController == null) {
      await _initializeWebView();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    try {
      final result = await _webViewController!.runJavaScriptReturningResult(
        'processNSignature("$initialN")',
      );
      return result.toString();
    } catch (e) {
      print('Error calculating N: $e');
      return '';
    }
  }

  /// Simple signature decryption
  String? getSignature(String cipheredSignature) {
    try {
      // Simple: reverse the string
      return cipheredSignature.split('').reversed.join('');
    } catch (e) {
      print('Error decrypting signature: $e');
      return null;
    }
  }
}
