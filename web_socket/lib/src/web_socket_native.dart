import 'dart:async';

import 'package:stream_channel/stream_channel.dart';
import 'package:tekartik_web_socket/web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart' as native;

class _SinkNative<T> implements StreamSink<T> {
  final native.WebSocketSink nativeInstance;

  _SinkNative(this.nativeInstance);

  @override
  void add(T event) {
    nativeInstance.add(event);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    nativeInstance.addError(error, stackTrace);
  }

  @override
  Future addStream(Stream<T> stream) async {
    await nativeInstance.addStream(stream);
  }

  @override
  Future close() async {
    await nativeInstance.close();
  }

  @override
  Future get done => nativeInstance.done;
}

/// Native web socket channel.
class WebSocketChannelNative<T> extends StreamChannelMixin<T>
    implements WebSocketChannel<T> {
  /// Internal stream controller.
  StreamController<T> streamController = StreamController<T>();

  /// Native channel.
  final native.WebSocketChannel nativeChannel;

  /// Done completer.
  Completer doneCompleter = Completer();

  /// Create from a native channel.
  WebSocketChannelNative(this.nativeChannel) {
    nativeChannel.stream.listen(
      (data) {
        streamController.add(data as T);
      },
      onDone: () {
        doneCompleter.complete();
        streamController.close();
      },
      onError: (Object e, StackTrace st) {
        streamController.addError(e, st);
      },
    );
    // Eat error we'll get it later...
    nativeChannel.ready.onError((Object error, st) {});
  }

  StreamSink<T>? _sink;

  @override
  StreamSink<T> get sink => _sink ??= _SinkNative<T>(nativeChannel.sink);

  @override
  Stream<T> get stream => streamController.stream;

  /// Future that completes when the channel is closed.
  Future get done => doneCompleter.future;

  @override
  /// Native channel string representation.
  String toString() => nativeChannel.toString();

  @override
  Future<void> get ready => nativeChannel.ready;
}
