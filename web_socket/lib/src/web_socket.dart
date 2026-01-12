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

/// The URL scheme used by the secure WebSocket protocol.
String webSocketUrlSecureScheme = 'wss';

/// Server factory
/// Web socket channel server factory.
abstract class WebSocketChannelServerFactory {
  /// Serve a web socket server at the given [address] and [port].
  Future<WebSocketChannelServer<T>> serve<T>({Object? address, int? port});
}

/// Web socket channel server.
abstract class WebSocketChannelServer<T> {
  /// Port assigned to the server.
  int get port;

  /// URL the server is listening on.
  String get url;

  /// Stream of connected channels.
  Stream<WebSocketChannel<T>> get stream;

  /// Close the server.
  Future close();
}

/// Web socket channel client factory.
abstract class WebSocketChannelClientFactory {
  /// Connect to the given [url].
  WebSocketChannel<T> connect<T>(String url);
}
