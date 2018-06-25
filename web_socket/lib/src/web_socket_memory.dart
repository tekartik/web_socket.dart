import 'dart:async';

import 'package:stream_channel/stream_channel.dart';
import 'package:tekartik_common_utils/int_utils.dart';
import 'package:tekartik_web_socket/web_socket.dart';

webSocketClientChannelFactoryMemory _webSocketChannelClientFactoryMemory;

webSocketClientChannelFactoryMemory get webSocketChannelClientFactoryMemory =>
    _webSocketChannelClientFactoryMemory ??=
        new webSocketClientChannelFactoryMemory();

WebSocketChannelServerFactory _webSocketChannelServerFactoryMemory;

WebSocketChannelServerFactory get webSocketChannelServerFactoryMemory =>
    _webSocketChannelServerFactoryMemory ??=
        new _WebSocketChannelServerFactoryMemory();

WebSocketDataMemory _webSocketMemory;

WebSocketDataMemory get webSocketMemory =>
    _webSocketMemory ??= new WebSocketDataMemory();

// initialize both
class WebSocketChannelFactoryMemory extends WebSocketChannelFactory {
  String get scheme => webSocketUrlMemoryScheme;

  WebSocketChannelFactoryMemory()
      : super(webSocketChannelServerFactoryMemory,
            webSocketChannelClientFactoryMemory);
}

WebSocketChannelFactoryMemory _memoryWebSocketChannelFactory;

WebSocketChannelFactoryMemory get webSocketChannelFactoryMemory =>
    _memoryWebSocketChannelFactory ??= new WebSocketChannelFactoryMemory();

String webSocketUrlMemoryScheme = "memory";

// The one to use
// will redirect memory: to memory
WebSocketChannelClientFactory smartWebSocketChannelClientFactory(
        WebSocketChannelClientFactory defaultFactory) =>
    new WebSocketChannelClientFactoryMerged(defaultFactory);

// Global list of servers
class WebSocketDataMemory {
  int _lastPortId = 0;
  Map<int, WebSocketChannelServer> servers = {};
  Map<int, WebSocketChannelMemory> channels = {}; // both server and client

  addServer(WebSocketChannelServer server) {
    servers[server.port] = server;
    // devPrint("adding $server");
  }

  removeServer(WebSocketChannelServer server) {
    servers.remove(server.port);
    // devPrint("removing $server");
  }

  int checkPort(int port) {
    if (servers.keys.contains(port)) {
      throw 'port $port used';
    }
    if (port == 0) {
      port = ++_lastPortId;
    }
    return port;
  }
}

/*
class MemoryServer {
  List<WebSocketChannelServer> servers;

  MemoryWebSocketChannel server;
  MemoryWebSocketChannel slave;

  bool addChannel(MemoryWebSocketChannel channel) {
    if (channel.url == masterUrl) {
      master = channel;
      return true;
    } else if (channel.url ==slaveUrl) {
        slave = channel;
        return true;
    }
    return false;
  }

  MemoryWebSocketChannel getOppositeChannel(MemoryWebSocketChannel channel) {
    if (channel == master) {
      return slave;
    } else if (channel == slave) {
      return master;
    }
  }
}

final MemoryServer memoryServicer = new MemoryServer();
*/
class MemorySink<T> implements StreamSink<T> {
  final WebSocketChannelMemory channel;

  MemorySink(this.channel);

  WebSocketChannelMemory get link => channel.link;

  Completer doneCompleter = new Completer();

  @override
  void add(event) {
    if (link != null) {
      link.streamController.add(event);
    }
  }

  @override
  void addError(Object error, [StackTrace stackTrace]) {
    if (link != null) {
      link.streamController.addError(error, stackTrace);
    }
  }

  @override
  Future addStream(Stream stream) {
    if (link != null) {
      return link.streamController.addStream(stream);
    }
    return new Future.value();
  }

  Future _close() async {
    if (!doneCompleter.isCompleted) {
      doneCompleter.complete();
    }
  }

  // close the channel instead
  // it will call _close
  @override
  Future close() async {
    channel.close();
  }

  @override
  Future get done => doneCompleter.future;
}

class webSocketClientChannelFactoryMemory
    extends WebSocketChannelClientFactory {
  @override
  WebSocketChannel<T> connect<T>(String url) {
    return new MemoryWebSocketClientChannel<T>.connect(url);
  }
}

class MemoryWebSocketServerChannel<T> extends WebSocketChannelMemory<T> {
  final WebSocketChannelServerMemory channelServer;

  // associated client
  MemoryWebSocketClientChannel<T> client;

  MemoryWebSocketServerChannel(this.channelServer) {
    channelServer.channels.add(this);
  }

  WebSocketChannelMemory get link => client;

  _close() {
    channelServer.channels.remove(this);
  }
}

class MemoryWebSocketClientChannel<T> extends WebSocketChannelMemory<T> {
  MemoryWebSocketServerChannel<T> server;

  WebSocketChannelMemory get link => server;
  String url;

  MemoryWebSocketClientChannel.connect(this.url) {
    if (!url.startsWith(webSocketUrlMemoryScheme)) {
      throw "unsupported scheme";
    }
    int port = parseInt(url.replaceFirst(webSocketUrlMemoryScheme + ":", ""));

    // Deley others
    new Future.value().then((_) {
      // devPrint("port $port");

      // Find server
      WebSocketChannelServerMemory channelServer =
          webSocketMemory.servers[port];
      if (channelServer != null) {
        // connect them
        MemoryWebSocketServerChannel<T> serverChannel =
            new MemoryWebSocketServerChannel<T>(channelServer)..client = this;
        this.server = serverChannel;

        // notify
        channelServer.streamController.add(serverChannel);
      } else {
        streamController.addError("cannot connect ${this.url}");
        close();
        //throw "cannot connect ${this.url}";
      }
    });
  }
}

abstract class WebSocketChannelMemory<T> extends StreamChannelMixin<T>
    implements WebSocketChannel<T> {
  int id;

  StreamController<T> streamController;
  String url;

  WebSocketChannelMemory get link;

  WebSocketChannelMemory() {
    streamController = new StreamController();
    sink = new MemorySink(this);
  }

  @override
  MemorySink<T> sink;

  @override
  Stream<T> get stream => streamController.stream;

  bool _closing = false;

  Future close() async {
    if (!_closing) {
      _closing = true;
      await sink._close();
      await streamController.close();
      // link might be null if not connected yet
      await link?.close();
    }
  }
}

// Handle both url and 'memory:url'
class WebSocketChannelClientFactoryMerged
    extends WebSocketChannelClientFactory {
  WebSocketChannelClientFactory defaultFactory;

  WebSocketChannelClientFactoryMerged(this.defaultFactory);

  @override
  WebSocketChannel<T> connect<T>(String url) {
    if (url.startsWith("memory:")) {
      return webSocketChannelClientFactoryMemory.connect(url);
    }
    return defaultFactory.connect(url);
  }
}

class WebSocketChannelServerMemory<T> implements WebSocketChannelServer<T> {
  List<WebSocketChannel> channels = [];
  StreamController<MemoryWebSocketServerChannel<T>> streamController;

  Stream<WebSocketChannel<T>> get stream => streamController.stream;

  final int port;

  WebSocketChannelServerMemory(this.port) {
    streamController = new StreamController();
  }

  close() async {
    // Close our stream
    await streamController.close();

    // remove from our table
    webSocketMemory.removeServer(this);

    // kill all connections
    List<WebSocketChannelMemory> channels = new List.from(this.channels);
    for (WebSocketChannelMemory channel in channels) {
      await channel.close();
    }
  }

  @override
  String get url => "${webSocketUrlMemoryScheme}:${port}";

  toString() => "server $url";
}

class _WebSocketChannelServerFactoryMemory<T>
    implements WebSocketChannelServerFactory<T> {
  Future<WebSocketChannelServer<T>> serve<T>({address, int port}) async {
    port ??= 0;
    // We don't care about the address
    //address ??= InternetAddress.ANY_IP_V6;

    port = webSocketMemory.checkPort(port);

    var server = new WebSocketChannelServerMemory<T>(port);

    // Add in our global table
    webSocketMemory.addServer(server);

    return server;
    /*
    port ??= serialWssPortDefault;
    address ??= InternetAddress.ANY_IP_V6;
    HttpServer httpServer;

    _IoWebSocketChannelServer serialServer;

    var handler = webSocketHandler((native.WebSocketChannel webSocketChannel) {
      SerialServerConnection serverChannel = new SerialServerConnection(
          serialServer, ++serialServer.lastId, webSocketChannel);

      serialServer.channels.add(serverChannel);
      if (SerialServer.debug) {
        print("[SerialServer] adding channel: ${serialServer.channels}");
      }
    });

    httpServer = await shelf_io.serve(handler, address, port);
    serialServer =
    //new SerialServer(await shelf_io.serve(handler, 'localhost', 8988));
    new IoSerialServer(httpServer);
    if (SerialServer.debug) {
      print(
          'Serving at ws://${serialServer.httpServer.address
              .host}:${serialServer
              .httpServer.port}');
    }
    return serialServer;
    */
  }
}

// bool _debug = true;
