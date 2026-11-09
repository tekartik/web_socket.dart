import 'dart:io';

// ignore: depend_on_referenced_packages
import 'package:stream_channel/stream_channel.dart';

/// Web socket echo server run in the VM by `spawnHybridUri`, sends its url.
Future<void> hybridMain(StreamChannel<Object?> channel) async {
  var server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    var socket = await WebSocketTransformer.upgrade(request);
    socket.listen(socket.add, onDone: socket.close);
  });
  channel.sink.add('ws://127.0.0.1:${server.port}');
}
