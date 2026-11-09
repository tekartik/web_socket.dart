// ignore_for_file: avoid_print

/// A JSON request/response over a web socket, in memory.
///
/// The same `run` works on the VM with `webSocketChannelFactoryIo`
/// (`package:tekartik_web_socket_io/web_socket_io.dart`).
library;

import 'dart:convert';

import 'package:tekartik_web_socket/web_socket.dart';

/// Answers each `{"add": [a, b]}` request with `{"result": a + b}`.
Future<WebSocketChannelServer<String>> serveAdder(
  WebSocketChannelServerFactory serverFactory,
) async {
  var server = await serverFactory.serve<String>();
  server.stream.listen((channel) {
    channel.stream.listen((message) {
      var numbers = (jsonDecode(message) as Map)['add'] as List;
      channel.sink.add(
        jsonEncode({'result': (numbers[0] as num) + (numbers[1] as num)}),
      );
    });
  });
  return server;
}

Future<void> run(WebSocketChannelFactory factory) async {
  var server = await serveAdder(factory.server);
  var channel = factory.client.connect<String>(server.url);
  try {
    await channel.ready;
    // Listen before sending, the stream is single subscription.
    var response = channel.stream.first;
    channel.sink.add(
      jsonEncode({
        'add': [1, 2],
      }),
    );
    print(await response); // {"result":3}
  } finally {
    await channel.sink.close();
    await server.close();
  }
}

Future<void> main() async {
  await run(webSocketChannelFactoryMemory);
}
