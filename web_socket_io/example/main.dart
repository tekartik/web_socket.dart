// ignore_for_file: avoid_print

import 'package:tekartik_web_socket_io/web_socket_io.dart';

/// An echo server and a client on the Dart VM (real sockets, free port).
Future<void> main() async {
  var server = await webSocketChannelServerFactoryIo.serve<String>();
  server.stream.listen((channel) {
    // One channel per connected client: echo
    channel.stream.listen((message) => channel.sink.add('echo $message'));
  });
  print('serving at ${server.url}'); // ws://localhost:<port>

  var client = webSocketChannelClientFactoryIo.connect<String>(server.url);
  await client.ready; // throws if the connection fails
  var answer = client.stream.first;
  client.sink.add('hi');
  print(await answer); // echo hi

  await client.sink.close();
  // Closes the http server, the remaining channels and ends server.stream.
  await server.close();
}
