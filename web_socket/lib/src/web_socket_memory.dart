import 'dart:async';

import 'package:stream_channel/stream_channel.dart';
import 'package:tekartik_common_utils/int_utils.dart';
import 'package:tekartik_web_socket/web_socket.dart';

WebSocketClientChannelFactoryMemory? _webSocketChannelClientFactoryMemory;

/// Memory web socket channel client factory.
WebSocketClientChannelFactoryMemory get webSocketChannelClientFactoryMemory =>
    _webSocketChannelClientFactoryMemory ??=
        WebSocketClientChannelFactoryMemory();

WebSocketChannelServerFactory? _webSocketChannelServerFactoryMemory;

/// Memory web socket channel server factory.
WebSocketChannelServerFactory get webSocketChannelServerFactoryMemory =>
    _webSocketChannelServerFactoryMemory ??=
        _WebSocketChannelServerFactoryMemory();

WebSocketDataMemory? _webSocketMemory;

/// Memory web socket data.
WebSocketDataMemory get webSocketMemory =>
    _webSocketMemory ??= WebSocketDataMemory();

// initialize both
/// Memory web socket channel factory.
class WebSocketChannelFactoryMemory extends WebSocketChannelFactory {
  @override
  String get scheme => webSocketUrlMemoryScheme;

  /// Memory web socket channel factory.
  WebSocketChannelFactoryMemory()
    : super(
        webSocketChannelServerFactoryMemory,
        webSocketChannelClientFactoryMemory,
      );
}

WebSocketChannelFactoryMemory? _memoryWebSocketChannelFactory;

/// Memory web socket channel factory.
WebSocketChannelFactoryMemory get webSocketChannelFactoryMemory =>
    _memoryWebSocketChannelFactory ??= WebSocketChannelFactoryMemory();

/// Standard web socket url memory scheme.
String webSocketUrlMemoryScheme = 'ws';

/// The one to use, will redirect memory: to memory.
WebSocketChannelClientFactory smartWebSocketChannelClientFactory(
  WebSocketChannelClientFactory defaultFactory,
) => WebSocketChannelClientFactoryMerged(defaultFactory);

/// Web socket data memory.
class WebSocketDataMemory {
  int _lastPortId = 0;

  /// Map of ports to servers.
  Map<int, WebSocketChannelServer> servers = {};

  /// Map of ports to channels.
  Map<int, WebSocketChannelMemory> channels = {}; // both server and client

  /// Add a server.
  void addServer(WebSocketChannelServer server) {
    servers[server.port] = server;
    // devPrint('adding $server');
  }

  /// Remove a server.
  void removeServer(WebSocketChannelServer server) {
    servers.remove(server.port);
    // devPrint('removing $server');
  }

  /// Check if a port is available.
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
/// Memory sink.
class MemorySink<T> implements StreamSink<T> {
  /// Associated channel.
  final WebSocketChannelMemory channel;

  /// Create a sink for a channel.
  MemorySink(this.channel);

  /// Link to the other side.
  WebSocketChannelMemory? get link => channel.link;

  /// Done completer.
  Completer doneCompleter = Completer();

  @override
  void add(event) {
    if (link != null) {
      link!.streamController.add(event);
    }
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    if (link != null) {
      link!.streamController.addError(error, stackTrace);
    }
  }

  @override
  Future addStream(Stream stream) {
    if (link != null) {
      return link!.streamController.addStream(stream);
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

/// Memory web socket client channel factory.
class WebSocketClientChannelFactoryMemory
    extends WebSocketChannelClientFactory {
  @override
  WebSocketChannel<T> connect<T>(String url) {
    return MemoryWebSocketClientChannel<T>.connect(url);
  }
}

/// Memory web socket server channel.
class MemoryWebSocketServerChannel<T> extends WebSocketChannelMemory<T> {
  /// Associated server.
  final WebSocketChannelServerMemory channelServer;

  /// Associated client.
  MemoryWebSocketClientChannel<T?>? client;

  /// Create a server channel.
  MemoryWebSocketServerChannel(this.channelServer) {
    channelServer.channels.add(this);
  }

  @override
  WebSocketChannelMemory? get link => client;

  @override
  void _close() {
    super._close();
    channelServer.channels.remove(this);
  }

  @override
  Future<void> get ready => Future.value();
}

/// Memory web socket client channel.
class MemoryWebSocketClientChannel<T> extends WebSocketChannelMemory<T> {
  /// Associated server channel.
  MemoryWebSocketServerChannel<T?>? server;

  @override
  WebSocketChannelMemory? get link => server;

  // Ready completer.
  final Completer<void> _readyCompleter = Completer<void>();

  /// Connect to the given [url].
  MemoryWebSocketClientChannel.connect(String url) {
    this.url = url;
    if (!url.startsWith(webSocketUrlMemoryScheme)) {
      throw Exception('unsupported scheme');
    }
    final port = parseInt(url.replaceFirst('$webSocketUrlMemoryScheme:', ''));

    // 2019-01-23
    // Don't delay anymore
    // so that it can connect directly
    // Note that this affect a test 'Send client first'

    // Delay connection
    // Future.value().then((_) {
    // devPrint('port $port');

    // Find server
    final channelServer =
        webSocketMemory.servers[port] as WebSocketChannelServerMemory?;
    if (channelServer != null) {
      // connect them
      final serverChannel = MemoryWebSocketServerChannel<T>(channelServer)
        ..client = this;
      server = serverChannel;

      _readyCompleter.complete();
      // notify
      channelServer.streamController.add(serverChannel);
    } else {
      Future<void>.value().then((_) async {
        var error = Exception('cannot connect ${this.url}');
        streamController.addError(error);
        _readyCompleter.completeError(error);
        await close();
      });
      //throw 'cannot connect ${this.url}';
    }

    // });
  }
  @override
  Future<void> get ready => _readyCompleter.future;
}

/// Base class for memory web socket channels.
abstract class WebSocketChannelMemory<T> extends StreamChannelMixin<T>
    implements WebSocketChannel<T> {
  /// Channel id.
  int? id;

  /// Internal stream controller.
  late StreamController<T> streamController;

  /// Channel URL.
  String? url;

  /// Link to the other side.
  WebSocketChannelMemory? get link;

  /// Create a memory channel.
  WebSocketChannelMemory() {
    streamController = StreamController();
    sink = MemorySink(this);
  }

  @override
  late MemorySink<T> sink;

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

  /// Close the channel.
  Future close() async {
    if (!_closing) {
      _close();
      // link might be null if not connected yet
      link?._close();
    }
  }
}

// Handle both url and 'memory:url'
/// Merged web socket channel client factory (handle memory: too).
class WebSocketChannelClientFactoryMerged
    extends WebSocketChannelClientFactory {
  /// Default factory to use.
  WebSocketChannelClientFactory defaultFactory;

  /// Create with a default factory.
  WebSocketChannelClientFactoryMerged(this.defaultFactory);

  @override
  WebSocketChannel<T> connect<T>(String url) {
    if (url.startsWith('memory:')) {
      return webSocketChannelClientFactoryMemory.connect(url);
    }
    return defaultFactory.connect(url);
  }
}

/// Memory web socket server.
class WebSocketChannelServerMemory<T> implements WebSocketChannelServer<T> {
  /// List of connected channels.
  List<WebSocketChannel> channels = [];

  /// Internal stream controller.
  late StreamController<MemoryWebSocketServerChannel<T>> streamController;

  @override
  Stream<WebSocketChannel<T>> get stream => streamController.stream;

  @override
  @override
  final int port;

  /// Create a server on the given [port].
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
    final channels = List<WebSocketChannelMemory>.from(this.channels);
    for (final channel in channels) {
      await channel.close();
    }
  }

  @override
  String get url => '$webSocketUrlMemoryScheme:$port';

  @override
  String toString() => 'server $url';
}

class _WebSocketChannelServerFactoryMemory
    implements WebSocketChannelServerFactory {
  @override
  Future<WebSocketChannelServer<T>> serve<T>({address, int? port}) async {
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
