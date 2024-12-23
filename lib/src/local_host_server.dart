import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mime/mime.dart';

class LocalHostServer {
  static HttpServer? server;

  ///Closes the server.
  static Future<void> close() async {
    if (server != null) {
      await server!.close(force: true);
      server = null;
    }
  }

  ///Starts the server
  static Future<int> start({int port = 0}) async {
    var completer = Completer<int>();

    runZonedGuarded(() {
      HttpServer.bind('localhost', port, shared: true).then((httpServer) {
        server = httpServer;
        httpServer.listen((HttpRequest httpRequest) async {
          List<int> body = [];
          String path = httpRequest.requestedUri.path;
          path = (path.startsWith('/')) ? path.substring(1) : path;
          path += (path.endsWith('/')) ? 'index.html' : '';
          try {
            body = (await rootBundle.load(path)).buffer.asUint8List();
          } catch (e) {
            if (kDebugMode) {
              print('Error: $e');
            }
            httpRequest.response.close();
            return;
          }
          var contentType = ['text', 'html'];
          if (!httpRequest.requestedUri.path.endsWith('/') &&
              httpRequest.requestedUri.pathSegments.isNotEmpty) {
            String? mimeType = lookupMimeType(httpRequest.requestedUri.path,
                headerBytes: body);
            if (mimeType != null) {
              contentType = mimeType.split('/');
            }
          }
          httpRequest.response.headers.contentType =
              ContentType(contentType[0], contentType[1], charset: 'utf-8');
          httpRequest.response.add(body);
          httpRequest.response.close();
        });
        completer.complete(httpServer.port);
        if (kDebugMode) {
          print("Server started on port: ${httpServer.port}");
        }
      });
    }, (e, stackTrace) {
      if (kDebugMode) {
        print('Error: $e $stackTrace');
      }
    });
    return completer.future;
  }
}
