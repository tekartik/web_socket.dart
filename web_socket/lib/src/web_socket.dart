import 'dart:async';

import 'package:stream_channel/stream_channel.dart';

export 'web_socket_memory.dart'
    show
        webSocketChannelFactoryMemory,
        webSocketChannelClientFactoryMemory,
        webSocketMemory,
        webSocketChannelServerFactoryMemory;
export 'web_socket_native.dart' show WebSocketChannelNative;

/// A channel that communicates over a WebSocket connection.
abstract class WebSocketChannel<T> extends StreamChannelMixin<T> {
  /// Ready extension
  Future<void> get ready => Future.value();
}

/// A factory for creating [WebSocketChannel]s.
abstract class WebSocketChannelFactory {
  /// The URL scheme used by the factory.
  String get scheme;

  /// Creates a new [WebSocketChannel] connected to the given [url].
  WebSocketChannelFactory(this.server, this.client);

  /// The client factory
  WebSocketChannelClientFactory client;

  /// The server factory
  WebSocketChannelServerFactory server;
}

/// The URL scheme used by the WebSocket protocol.
String webSocketUrlScheme = 'ws';

/// Server factory
abstract class WebSocketChannelServerFactory {
  Future<WebSocketChannelServer<T>> serve<T>({Object? address, int? port});
}

abstract class WebSocketChannelServer<T> {
  // assigned port
  int get port;

  String get url;

  Stream<WebSocketChannel<T>> get stream;

  Future close();
}

abstract class WebSocketChannelClientFactory {
  WebSocketChannel<T> connect<T>(String url);
}
