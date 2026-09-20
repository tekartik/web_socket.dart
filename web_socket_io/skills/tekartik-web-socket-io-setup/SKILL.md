---
name: tekartik-web-socket-io-setup
description: >-
  Use when running tekartik_web_socket code on the Dart VM or Flutter native
  (dart:io) with tekartik_web_socket_io: the webSocketChannelFactoryIo,
  webSocketChannelClientFactoryIo and webSocketChannelServerFactoryIo getters
  from package:tekartik_web_socket_io/web_socket_io.dart, serving a real web
  socket server with serve(address:, port:) (shelf_web_socket + HttpServer,
  url ws://localhost:<port>), connecting with connect<T>(url)
  (IOWebSocketChannel), the UnsupportedError thrown off the VM, and running the
  tekartik_web_socket_test suite with webSocketTestMain(webSocketChannelFactoryIo).
---

# tekartik_web_socket_io: the dart:io implementation

`tekartik_web_socket_io` implements the `tekartik_web_socket` abstractions with
`dart:io`: `IOWebSocketChannel` for the client, a `shelf_web_socket` handler on
an `HttpServer` for the server. It is the only one of the implementations that
can *serve*. Importing it is safe everywhere, but the getters throw
`UnsupportedError` outside the VM.

## Guidelines

* Not on pub.dev, depend on it through git (the package lives in the
  `web_socket_io/` directory of the repo):
  ```yaml
  dependencies:
    tekartik_web_socket_io:
      git:
        url: https://github.com/tekartik/web_socket.dart
        path: web_socket_io
      version: '>=0.2.2'
  ```
  It brings `tekartik_web_socket` (same repo, `path: web_socket`), which shared
  code is written against; declare that one explicitly too when a library
  imports it directly.
* One import: `package:tekartik_web_socket_io/web_socket_io.dart`. It
  re-exports the whole `package:tekartik_web_socket/web_socket.dart` API
  (`WebSocketChannel`, `WebSocketChannelFactory`,
  `WebSocketChannelClientFactory`, `WebSocketChannelServerFactory`,
  `WebSocketChannelServer`, `WebSocketChannelNative`, `webSocketUrlScheme`, the
  memory factories) and adds exactly three getters:
  `webSocketChannelClientFactoryIo`, `webSocketChannelServerFactoryIo` and
  `webSocketChannelFactoryIo` (the combined factory, `.client` / `.server` /
  `.scheme`). The implementation classes are not exported: always go through
  the getters and type variables with the abstract types.
* The import uses a conditional export, so it compiles for the web too: there
  the three getters throw `UnsupportedError`. Never reference them from code
  shared with the browser - inject the factory instead, or use
  `tekartik_app_web_socket`, which picks io or browser for you.
* Client: `webSocketChannelClientFactoryIo.connect<T>(url)` wraps
  `IOWebSocketChannel.connect(url)`. It returns before the connection is
  established: `await channel.ready` in a `try`/`catch` to detect a refused
  connection, and pass `onError:` to `channel.stream.listen`. A malformed url
  throws from `connect` itself. Use `connect<String>` for a text protocol,
  `connect<List<int>>` for binary frames.
* Server: `await webSocketChannelServerFactoryIo.serve<T>(address: ..., port: ...)`.
  `address` defaults to `InternetAddress.anyIPv6` and also accepts a host
  `String` (`'localhost'`) or any `dart:io` `InternetAddress`; `port` null or
  `0` picks a free port, read it back with `server.port`. `server.url` is
  always `ws://localhost:<port>` (not the bound address, rewrite it yourself
  for a remote client).
* `server.stream` emits one `WebSocketChannel<T>` per connected client - listen
  right after `serve` returns. `await server.close()` closes the `HttpServer`
  (forced) and every client channel still open.
* There is no TLS server here (no `wss://` serving), no sub-protocol
  negotiation exposed and no shelf `Request` access: the handler is created
  internally. For those, use `shelf_web_socket` directly.
* Flutter: the same package works on Android/iOS/desktop. Only the client side
  makes sense in an app; remember the network permissions and that a cleartext
  `ws://` url may be blocked by the platform.
* Testing: `dev_dependencies` on `tekartik_web_socket_test`, then a
  `@TestOn('vm')` test file calling
  `webSocketTestMain(webSocketChannelFactoryIo)` runs the whole shared
  conformance suite (connect, exchange, close from each side, failures) against
  the io implementation.
* Anti-patterns: importing `web_socket_io.dart` from web/shared code and
  touching the getters; hard-coding `ws://localhost:<port>` instead of
  `server.url`; forgetting `server.close()` in a test (the port stays bound);
  reusing a channel after `sink.close()`; assuming `connect` throws when
  nothing listens on the port.

## Examples

### Serve an echo server on the VM

```dart
import 'package:tekartik_web_socket_io/web_socket_io.dart';

Future<void> main() async {
  // port 0 (the default): a free port is picked.
  var server = await webSocketChannelServerFactoryIo.serve<String>(
    address: 'localhost',
    port: 0,
  );
  // ws://localhost:<port>
  print('serving at ${server.url} (port ${server.port})');

  server.stream.listen((channel) {
    channel.stream.listen(
      (message) => channel.sink.add('echo $message'),
      onDone: () => print('client gone'),
    );
  });

  await Future<void>.delayed(const Duration(seconds: 30));
  // Closes the http server and every client channel.
  await server.close();
}
```

### Connect from the VM

```dart
import 'package:tekartik_web_socket_io/web_socket_io.dart';

Future<void> main() async {
  var channel = webSocketChannelClientFactoryIo.connect<String>(
    'ws://localhost:8080',
  );
  try {
    // connect() does not throw on a refused connection, ready does.
    await channel.ready;
  } catch (e) {
    print('cannot connect: $e');
    return;
  }
  channel.sink.add('hi');
  print('received ${await channel.stream.first}');
  await channel.sink.close();
}
```

### Client and server in the same test

```dart
@TestOn('vm')
library;

import 'package:tekartik_web_socket_io/web_socket_io.dart';
import 'package:test/test.dart';

void main() {
  test('io echo', () async {
    // webSocketChannelFactoryIo groups the client and the server factories.
    var server = await webSocketChannelFactoryIo.server.serve<String>();
    server.stream.listen((channel) {
      channel.stream.listen((message) => channel.sink.add('echo $message'));
    });

    var client = webSocketChannelFactoryIo.client.connect<String>(server.url);
    await client.ready;
    client.sink.add('hi');
    expect(await client.stream.first, 'echo hi');

    await client.sink.close();
    await server.close();
  });
}
```

### Run the shared conformance suite against io

```dart
@TestOn('vm')
library;

import 'package:tekartik_web_socket_io/web_socket_io.dart';
import 'package:tekartik_web_socket_test/web_socket_test.dart';
import 'package:test/test.dart';

void main() {
  // Every test of tekartik_web_socket_test, on the io implementation.
  webSocketTestMain(webSocketChannelFactoryIo);
}
```
