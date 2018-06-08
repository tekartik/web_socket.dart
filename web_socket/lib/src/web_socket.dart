import 'dart:async';

import 'package:stream_channel/stream_channel.dart';
export 'web_socket_native.dart' show WebSocketChannelNative;
export 'web_socket_memory.dart'
    show
        webSocketChannelFactoryMemory,
        webSocketChannelClientFactoryMemory,
        webSocketMemory,
        webSocketChannelServerFactoryMemory;

abstract class WebSocketChannel<T> extends StreamChannelMixin<T> {}

abstract class WebSocketChannelFactory {
  String get scheme;

  WebSocketChannelFactory(this.server, this.client);

  WebSocketChannelClientFactory client;
  WebSocketChannelServerFactory server;
}

String webSocketUrlScheme = "ws";

abstract class WebSocketChannelServerFactory<T> {
  Future<WebSocketChannelServer<T>> serve<T>({var address, int port});
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
