import 'dart:async';

import 'package:stream_channel/stream_channel.dart';
import 'package:tekartik_common_utils/int_utils.dart';
import 'package:tekartik_web_socket/web_socket.dart';
import 'package:pedantic/pedantic.dart';

WebSocketClientChannelFactoryMemory _webSocketChannelClientFactoryMemory;

WebSocketClientChannelFactoryMemory get webSocketChannelClientFactoryMemory =>
    _webSocketChannelClientFactoryMemory ??=
        WebSocketClientChannelFactoryMemory();

WebSocketChannelServerFactory _webSocketChannelServerFactoryMemory;

WebSocketChannelServerFactory get webSocketChannelServerFactoryMemory =>
    _webSocketChannelServerFactoryMemory ??=
        _WebSocketChannelServerFactoryMemory();

WebSocketDataMemory _webSocketMemory;

WebSocketDataMemory get webSocketMemory =>
    _webSocketMemory ??= WebSocketDataMemory();

// initialize both
class WebSocketChannelFactoryMemory extends WebSocketChannelFactory {
  @override
  String get scheme => webSocketUrlMemoryScheme;

  WebSocketChannelFactoryMemory()
      : super(webSocketChannelServerFactoryMemory,
            webSocketChannelClientFactoryMemory);
}

WebSocketChannelFactoryMemory _memoryWebSocketChannelFactory;

WebSocketChannelFactoryMemory get webSocketChannelFactoryMemory =>
    _memoryWebSocketChannelFactory ??= WebSocketChannelFactoryMemory();

String webSocketUrlMemoryScheme = "memory";

// The one to use
// will redirect memory: to memory
WebSocketChannelClientFactory smartWebSocketChannelClientFactory(
        WebSocketChannelClientFactory defaultFactory) =>
    WebSocketChannelClientFactoryMerged(defaultFactory);

// Global list of servers
class WebSocketDataMemory {
  int _lastPortId = 0;
  Map<int, WebSocketChannelServer> servers = {};
  Map<int, WebSocketChannelMemory> channels = {}; // both server and client

  void addServer(WebSocketChannelServer server) {
    servers[server.port] = server;
    // devPrint("adding $server");
  }

  void removeServer(WebSocketChannelServer server) {
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

  Completer doneCompleter = Completer();

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
    return Future.value();
  }

  void _close() {
    if (!doneCompleter.isCompleted) {
      doneCompleter.complete();
    }
  }

  // close the channel instead
  // it will call _close
  @override
  Future close() async {
    await channel.close();
  }

  @override
  Future get done => doneCompleter.future;
}

class WebSocketClientChannelFactoryMemory
    extends WebSocketChannelClientFactory {
  @override
  WebSocketChannel<T> connect<T>(String url) {
    return MemoryWebSocketClientChannel<T>.connect(url);
  }
}

class MemoryWebSocketServerChannel<T> extends WebSocketChannelMemory<T> {
  final WebSocketChannelServerMemory channelServer;

  // associated client
  MemoryWebSocketClientChannel<T> client;

  MemoryWebSocketServerChannel(this.channelServer) {
    channelServer.channels.add(this);
  }

  @override
  WebSocketChannelMemory get link => client;

  @override
  void _close() {
    super._close();
    channelServer.channels.remove(this);
  }
}

class MemoryWebSocketClientChannel<T> extends WebSocketChannelMemory<T> {
  MemoryWebSocketServerChannel<T> server;

  @override
  WebSocketChannelMemory get link => server;

  MemoryWebSocketClientChannel.connect(String url) {
    this.url = url;
    if (!url.startsWith(webSocketUrlMemoryScheme)) {
      throw "unsupported scheme";
    }
    int port = parseInt(url.replaceFirst(webSocketUrlMemoryScheme + ":", ""));

    // 2019-01-23
    // Don't delay anymore
    // so that it can connect directly
    // Note that this affect a test 'Send client first'

    // Delay connection
    // Future.value().then((_) {
    // devPrint("port $port");

    // Find server
    final channelServer =
        webSocketMemory.servers[port] as WebSocketChannelServerMemory;
    if (channelServer != null) {
      // connect them
      MemoryWebSocketServerChannel<T> serverChannel =
          MemoryWebSocketServerChannel<T>(channelServer)..client = this;
      this.server = serverChannel;

      // notify
      channelServer.streamController.add(serverChannel);
    } else {
      streamController.addError("cannot connect ${this.url}");
      close();
      //throw "cannot connect ${this.url}";
    }

    // });
  }
}

abstract class WebSocketChannelMemory<T> extends StreamChannelMixin<T>
    implements WebSocketChannel<T> {
  int id;

  StreamController<T> streamController;
  String url;

  WebSocketChannelMemory get link;

  WebSocketChannelMemory() {
    streamController = StreamController();
    sink = MemorySink(this);
  }

  @override
  MemorySink<T> sink;

  @override
  Stream<T> get stream => streamController.stream;

  bool _closing = false;

  void _close() {
    if (!_closing) {
      _closing = true;
      sink._close();
      unawaited(streamController.close());
    }
  }

  Future close() async {
    if (!_closing) {
      _close();
      // link might be null if not connected yet
      link?._close();
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

  @override
  Stream<WebSocketChannel<T>> get stream => streamController.stream;

  @override
  final int port;

  WebSocketChannelServerMemory(this.port) {
    streamController = StreamController();
  }

  @override
  Future close() async {
    // Close our stream
    await streamController.close();

    // remove from our table
    webSocketMemory.removeServer(this);

    // kill all connections
    List<WebSocketChannelMemory> channels = List.from(this.channels);
    for (WebSocketChannelMemory channel in channels) {
      await channel.close();
    }
  }

  @override
  String get url => "${webSocketUrlMemoryScheme}:${port}";

  @override
  String toString() => "server $url";
}

class _WebSocketChannelServerFactoryMemory
    implements WebSocketChannelServerFactory {
  @override
  Future<WebSocketChannelServer<T>> serve<T>({address, int port}) async {
    port ??= 0;
    // We don't care about the address
    //address ??= InternetAddress.ANY_IP_V6;

    port = webSocketMemory.checkPort(port);

    var server = WebSocketChannelServerMemory<T>(port);

    // Add in our global table
    webSocketMemory.addServer(server);

    return server;
  }
}
