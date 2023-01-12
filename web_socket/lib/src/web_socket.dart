import 'dart:async';

import 'package:stream_channel/stream_channel.dart';

export 'web_socket_memory.dart'
    show
        webSocketChannelFactoryMemory,
        webSocketChannelClientFactoryMemory,
        webSocketMemory,
        webSocketChannelServerFactoryMemory;
export 'web_socket_native.dart' show WebSocketChannelNative;

abstract class WebSocketChannel<T> extends StreamChannelMixin<T> {}

abstract class WebSocketChannelFactory {
  String get scheme;

  WebSocketChannelFactory(this.server, this.client);

  WebSocketChannelClientFactory client;
  WebSocketChannelServerFactory server;
}

String webSocketUrlScheme = 'ws';

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
