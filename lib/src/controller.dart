import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';

import 'package:flutter/services.dart';

class WebViewControllerPlus extends WebViewController {
  WebViewControllerPlus({
    super.onPermissionRequest,
  });

  /// Return the height of [WebViewWidget]
  Future<Object> getWebViewHeight() async {
    String getHeightScript = r"""getWebviewHeight();
        function getWebviewHeight() {
            var element = document.body;
            var height = element.offsetHeight,
                style = window.getComputedStyle(element)
            return ['top', 'bottom']
                .map(function (side) {
                    return parseInt(style["margin-" + side]);
                })
                .reduce(function (total, side) {
                    return total + side;
                }, height)
              }""";

    return await super.runJavaScriptReturningResult(getHeightScript);
  }

  /// Load assets on server
  Future<void> loadFlutterAssetWithServer(
    String uri,
    int port, {
    LoadRequestMethod method = LoadRequestMethod.get,
    Map<String, String> headers = const <String, String>{},
    Uint8List? body,
  }) async {
    return super.loadRequest(Uri.parse('http://localhost:$port/$uri'),
        headers: headers, body: body, method: method);
  }
}
