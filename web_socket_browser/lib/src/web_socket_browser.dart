import 'dart:async';
import 'dart:typed_data';

import 'package:tekartik_web_socket/web_socket.dart';
import 'package:web_socket_channel/html.dart';

/// Browser web socket channel client factory.
class WebSocketChannelClientFactoryBrowser
    extends WebSocketChannelClientFactory {
  @override
  WebSocketChannel<T> connect<T>(String url) {
    return _WebSocketChannelBrowser<T>(HtmlWebSocketChannel.connect(url));
  }
}

/// A browser `WebSocket` sends a `List<int>` that is not a typed list as
/// text ('1,2,3'): it is sent as bytes, as on io and in memory.
Object? _browserMessage(Object? message) {
  if (message is List<int> && message is! TypedData) {
    return Uint8List.fromList(message);
  }
  return message;
}

class _WebSocketChannelBrowser<T> extends WebSocketChannelNative<T> {
  _WebSocketChannelBrowser(super.nativeChannel);

  StreamSink<T>? _browserSink;

  @override
  StreamSink<T> get sink =>
      _browserSink ??= _BrowserSink<T>(nativeChannel.sink);
}

class _BrowserSink<T> implements StreamSink<T> {
  final StreamSink<Object?> nativeSink;

  _BrowserSink(this.nativeSink);

  @override
  void add(T event) => nativeSink.add(_browserMessage(event));

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      nativeSink.addError(error, stackTrace);

  @override
  Future addStream(Stream<T> stream) =>
      nativeSink.addStream(stream.map(_browserMessage));

  @override
  Future close() => nativeSink.close();

  @override
  Future get done => nativeSink.done;
}

WebSocketChannelClientFactoryBrowser?
_browserWebSocketChannelClientChannelFactory;

/// Browser web socket channel client factory.
WebSocketChannelClientFactoryBrowser get webSocketChannelClientFactoryBrowser =>
    _browserWebSocketChannelClientChannelFactory ??=
        WebSocketChannelClientFactoryBrowser();
