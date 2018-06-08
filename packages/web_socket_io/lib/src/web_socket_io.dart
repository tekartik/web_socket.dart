import 'dart:async';
import 'dart:io';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart' as native;
import 'package:tekartik_web_socket/src/web_socket_native.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:tekartik_web_socket/web_socket.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

class _IoWebSocketChannelServerFactory
    implements WebSocketChannelServerFactory {
  Future<WebSocketChannelServer<T>> serve<T>({address, int port}) async {
    port ??= 0;
    address ??= InternetAddress.anyIPv6;
    var server = new _IoWebSocketChannelServer<T>(address, port);
    await server.serve();
    return server;
  }
}

bool _debug = false;

WebSocketChannelServerFactory ioWebSocketChannelServerFactory =
    new _IoWebSocketChannelServerFactory();

class _IoWebSocketChannelServer<T> implements WebSocketChannelServer<T> {
  List<WebSocketChannel> channels = [];

  //static DevFlag debug = new DevFlag("debug");
  var address;

  // Port will changed when serving
  int port;
  HttpServer httpServer;

  _IoWebSocketChannelServer(this.address, this.port) {
    streamController = new StreamController();
  }

  Future serve() async {
    var handler =
        webSocketHandler((native.WebSocketChannel nativeWebSocketChannel) {
      WebSocketChannelNative<T> webSocketChannel =
          new WebSocketChannelNative(nativeWebSocketChannel);

      // add to our list for cleanup
      channels.add(webSocketChannel);

      streamController.add(webSocketChannel);
      if (_debug) {
        print(
            "[_IoWebSocketChannelServer] adding channel: ${webSocketChannel}");
      }
      // handle when the channel is done
      webSocketChannel.done.then((_) {
        channels.remove(webSocketChannel);
      });
    });

    this.httpServer = await shelf_io.serve(handler, address, port);
    port = httpServer.port;
    if (_debug) {
      print(httpServer.address);
      print('Serving at $url');
    }
  }

  StreamController<WebSocketChannel<T>> streamController;

  Stream<WebSocketChannel<T>> get stream => streamController.stream;

  close() async {
    await httpServer.close(force: true);

    // copy the channels remaining list and close them
    List channels = new List.from(this.channels);
    for (WebSocketChannel channel in channels) {
      await channel.sink.close();
    }
  }

  @override
  String get url => "ws://localhost:${port}";
// "ws://${httpServer.address.host}:${port}"; not working
}

class WebSocketClientChannelFactoryIo extends WebSocketChannelClientFactory {
  @override
  WebSocketChannel<T> connect<T>(String url) {
    return new WebSocketChannelNative(new IOWebSocketChannel.connect(url));
  }
}

WebSocketClientChannelFactoryIo _webSocketClientChannelFactoryIo;

WebSocketClientChannelFactoryIo get webSocketChannelClientFactoryIo =>
    _webSocketClientChannelFactoryIo ??= new WebSocketClientChannelFactoryIo();

// both client/server
class WebSocketChannelFactoryIo extends WebSocketChannelFactory {
  String get scheme => webSocketUrlScheme;
  WebSocketChannelFactoryIo()
      : super(ioWebSocketChannelServerFactory, webSocketChannelClientFactoryIo);
}

final WebSocketChannelFactoryIo webSocketChannelFactoryIo =
    new WebSocketChannelFactoryIo();
