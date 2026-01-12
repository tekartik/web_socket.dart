import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
// ignore: implementation_imports
import 'package:tekartik_web_socket/web_socket.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart' as native;

class _WebSocketChannelServerFactoryIo
    implements WebSocketChannelServerFactory {
  @override
  Future<WebSocketChannelServer<T>> serve<T>({
    Object? address /* Address or String */,
    int? port,
  }) async {
    port ??= 0;
    address ??= InternetAddress.anyIPv6;
    var server = _WebSocketChannelServerIo<T>(address, port);
    await server.serve();
    return server;
  }
}

bool _debug = false;

/// Io web socket channel server factory.
WebSocketChannelServerFactory webSocketChannelServerFactoryIo =
    _WebSocketChannelServerFactoryIo();

class _WebSocketChannelServerIo<T> implements WebSocketChannelServer<T> {
  List<WebSocketChannel> channels = [];

  //static DevFlag debug = new DevFlag('debug');
  Object address;

  // Port will changed when serving
  @override
  int port;
  late HttpServer httpServer;

  _WebSocketChannelServerIo(this.address, this.port) {
    streamController = StreamController();
  }

  Future serve() async {
    var handler = webSocketHandler((
      native.WebSocketChannel webSocket,
      String? subprotocol,
    ) {
      final webSocketChannel = WebSocketChannelNative<T>(webSocket);

      // add to our list for cleanup
      channels.add(webSocketChannel);

      streamController.add(webSocketChannel);
      if (_debug) {
        // ignore: avoid_print
        print('[_IoWebSocketChannelServer] adding channel: $webSocketChannel');
      }
      // handle when the channel is done
      webSocketChannel.done.then((_) {
        channels.remove(webSocketChannel);
      });
    });

    httpServer = await shelf_io.serve(handler, address, port);
    port = httpServer.port;
    if (_debug) {
      // ignore: avoid_print
      print(httpServer.address);
      // ignore: avoid_print
      print('Serving at $url');
    }
  }

  late StreamController<WebSocketChannel<T>> streamController;

  @override
  Stream<WebSocketChannel<T>> get stream => streamController.stream;

  @override
  Future close() async {
    await httpServer.close(force: true);

    // copy the channels remaining list and close them
    final channels = List<WebSocketChannel>.from(this.channels);
    for (final channel in channels) {
      await channel.sink.close();
    }
  }

  @override
  String get url => 'ws://localhost:$port';
  // 'ws://${httpServer.address.host}:${port}'; not working
}

/// Io web socket client channel factory.
class WebSocketClientChannelFactoryIo extends WebSocketChannelClientFactory {
  @override
  WebSocketChannel<T> connect<T>(String url) {
    return WebSocketChannelNative(IOWebSocketChannel.connect(url));
  }
}

WebSocketClientChannelFactoryIo? _webSocketClientChannelFactoryIo;

/// Io web socket channel client factory.
WebSocketClientChannelFactoryIo get webSocketChannelClientFactoryIo =>
    _webSocketClientChannelFactoryIo ??= WebSocketClientChannelFactoryIo();

// both client/server
/// Io web socket channel factory (both client and server).
class WebSocketChannelFactoryIo extends WebSocketChannelFactory {
  @override
  String get scheme => webSocketUrlScheme;

  /// Io web socket channel factory.
  WebSocketChannelFactoryIo()
    : super(webSocketChannelServerFactoryIo, webSocketChannelClientFactoryIo);
}

/// Io web socket channel factory.
final WebSocketChannelFactoryIo webSocketChannelFactoryIo =
    WebSocketChannelFactoryIo();
