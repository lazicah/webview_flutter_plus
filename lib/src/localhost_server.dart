import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'mime_type_resolver.dart';

/// A simple HTTP server that serves files from the local file system. This class is borrowed from the `Flutter InAppWebView Plugin`.
class LocalhostServer {
  /// Whether the server should be shared across multiple instances of the application. If set to `true`, the server will be shared across multiple instances of the application and will not be destroyed when the application is closed.
  final bool shared;

  /// The index file to serve when a directory is requested. Default is `index.html`.
  final String directoryIndex;

  /// The root directory where files will be served from. Default is `./`. This path is relative to the root of the application's assets.
  final String documentRoot;

  LocalhostServer({
    this.shared = false,
    this.directoryIndex = 'index.html',
    this.documentRoot = './',
  });

  int? get port => _server?.port;

  bool _started = false;
  HttpServer? _server;

  /// Starts the server on the given [port].
  Future<void> start({port = 0}) async {
    if (_started) {
      throw Exception('Server already started on http://localhost:$port');
    }
    _started = true;

    final completer = Completer();

    runZonedGuarded(() {
      HttpServer.bind('127.0.0.1', port, shared: shared).then((server) {
        if (kDebugMode) {
          print('Server running on http://localhost:$port');
        }
        _server = server;

        server.listen((HttpRequest request) async {
          Uint8List body = Uint8List(0);

          var path = request.requestedUri.path;
          path = (path.startsWith('/')) ? path.substring(1) : path;
          path += (path.endsWith('/')) ? directoryIndex : '';
          if (path == '') {
            // if the path still empty, try to load the index file
            path = directoryIndex;
          }
          path = documentRoot + path;

          try {
            body = (await rootBundle.load(Uri.decodeFull(path)))
                .buffer
                .asUint8List();
          } catch (e) {
            if (kDebugMode) {
              print(Uri.decodeFull(path));
              print(e.toString());
            }
            request.response.close();
            return;
          }

          var contentType = ContentType('text', 'html', charset: 'utf-8');
          if (!request.requestedUri.path.endsWith('/') &&
              request.requestedUri.pathSegments.isNotEmpty) {
            final mimeType = MimeTypeResolver.lookup(request.requestedUri.path);
            if (mimeType != null) {
              contentType = _getContentTypeFromMimeType(mimeType);
            }
          }

          request.response.headers.contentType = contentType;
          request.response.add(body);
          request.response.close();
        });

        completer.complete();
      });
    }, (e, stackTrace) {
      if (kDebugMode) {
        print('Error: $e $stackTrace');
      }
    });

    return completer.future;
  }

  /// Closes the server.
  Future<void> close() async {
    if (_server == null) {
      return;
    }
    final serverPort = port;
    await _server!.close(force: true);

    if (kDebugMode) {
      print('Server running on http://localhost:$serverPort closed');
    }

    _started = false;
    _server = null;
  }

  /// Returns whether the server is running or not.
  bool isRunning() {
    return _server != null;
  }

  /// Returns a [ContentType] object based on the given [mimeType].
  ContentType _getContentTypeFromMimeType(String mimeType) {
    final contentType = mimeType.split('/');
    String? charset;

    if (_isTextFile(mimeType)) {
      charset = 'utf-8';
    }

    return ContentType(contentType[0], contentType[1], charset: charset);
  }

  /// Returns whether the given [mimeType] is a text file or not.
  bool _isTextFile(String mimeType) {
    final textFile = RegExp(r'^text\/|^application\/(javascript|json)');
    return textFile.hasMatch(mimeType);
  }
}
