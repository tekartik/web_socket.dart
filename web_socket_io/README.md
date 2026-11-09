# tekartik_web_socket_io

The `dart:io` implementation of [tekartik_web_socket](../web_socket/README.md):
a web socket client (`IOWebSocketChannel`) and a web socket server
(`shelf_web_socket` on an `HttpServer`), on the Dart VM and Flutter native.
It is the only implementation that can serve.

## Getting started

Git package, not on pub.dev:

```yaml
dependencies:
  tekartik_web_socket_io:
    git:
      url: https://github.com/tekartik/web_socket.dart
      path: web_socket_io
```

```dart
import 'package:tekartik_web_socket_io/web_socket_io.dart';

Future<void> main() async {
  var server = await webSocketChannelServerFactoryIo.serve<String>();
  server.stream.listen((channel) {
    channel.stream.listen((message) => channel.sink.add('echo $message'));
  });

  var client = webSocketChannelClientFactoryIo.connect<String>(server.url);
  await client.ready; // throws if the connection fails
  var answer = client.stream.first;
  client.sink.add('hi');
  print(await answer); // echo hi

  await client.sink.close();
  await server.close();
}
```

Runnable: [example/main.dart](example/main.dart).

## Platforms

Dart VM and Flutter native. The import compiles everywhere (conditional
export), but on the web the getters throw `UnsupportedError`: inject the
factory, or use `tekartik_app_web_socket` which picks io or browser.

`package:tekartik_web_socket_io/web_socket_io.dart` re-exports the whole
`tekartik_web_socket` API and adds `webSocketChannelFactoryIo` (client and
server), `webSocketChannelClientFactoryIo` and
`webSocketChannelServerFactoryIo`.

## Common pitfalls

* `serve()` binds `InternetAddress.anyIPv6` by default (all interfaces, IPv4
  too on a dual stack host); pass `address: 'localhost'` to stay local, or
  `InternetAddress.anyIPv4` on a host without IPv6.
* `server.url` is always `ws://localhost:<port>`: build the url yourself for
  a remote client.
* `connect` returns at once: `await channel.ready` to know whether the
  connection succeeded; a malformed url throws from `connect`.
* `channel.stream` is single subscription: listen once.
* `await server.close()` closes the http server and every client channel, and
  ends `server.stream`.
* No TLS server (`wss://` serving): use `shelf_web_socket` directly behind
  your own `HttpServer.bindSecure`.

## Testing

```bash
dart test
```

`test/web_socket_io_test.dart` runs the shared suite of
`tekartik_web_socket_test` (`webSocketTestMain(webSocketChannelFactoryIo)`).
