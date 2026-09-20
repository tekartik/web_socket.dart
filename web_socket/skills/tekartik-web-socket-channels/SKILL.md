---
name: tekartik-web-socket-channels
description: >-
  Use when writing platform independent web socket code with
  tekartik_web_socket: the WebSocketChannel<T> abstraction (ready, stream,
  sink), WebSocketChannelClientFactory.connect<T>(url),
  WebSocketChannelServerFactory.serve<T>(address:, port:), WebSocketChannelServer
  (port, url, stream, close), the combined WebSocketChannelFactory (client,
  server, scheme), webSocketUrlScheme, the in memory implementation
  (webSocketChannelFactoryMemory, webSocketChannelClientFactoryMemory,
  webSocketChannelServerFactoryMemory, webSocketMemory,
  smartWebSocketChannelClientFactory) used to test without a network, and
  WebSocketChannelNative to wrap a package:web_socket_channel channel. Imports
  package:tekartik_web_socket/web_socket.dart and
  package:tekartik_web_socket/web_socket_client.dart.
---

# Web socket channels (tekartik_web_socket)

`tekartik_web_socket` is the platform independent web socket abstraction of the
Tekartik packages: a `WebSocketChannel<T>` and the client/server factories that
create one. The package itself only ships the in-memory implementation; the
real ones live in `tekartik_web_socket_io` (dart:io + shelf),
`tekartik_web_socket_browser` (dart:js_interop) and `tekartik_app_web_socket`
(picks one automatically).

## Guidelines

* Not on pub.dev, depend on it through git (the package lives in the
  `web_socket/` directory of the repo):
  ```yaml
  dependencies:
    tekartik_web_socket:
      git:
        url: https://github.com/tekartik/web_socket.dart
        path: web_socket
      version: '>=0.2.2'
  ```
* Two entry points: `package:tekartik_web_socket/web_socket.dart` exports
  everything (`WebSocketChannel`, `WebSocketChannelFactory`,
  `WebSocketChannelClientFactory`, `WebSocketChannelServerFactory`,
  `WebSocketChannelServer`, `WebSocketChannelNative`, `webSocketUrlScheme` and
  the memory factories); `package:tekartik_web_socket/web_socket_client.dart`
  is the client-only subset (`WebSocketChannel`,
  `WebSocketChannelClientFactory`, `webSocketUrlScheme`,
  `webSocketChannelClientFactoryMemory`, `smartWebSocketChannelClientFactory`,
  `WebSocketChannelNative`) - prefer it in code shared with the browser, where
  no server exists.
* This package has no platform code: shared code must take a factory
  (`WebSocketChannelClientFactory`, `WebSocketChannelServerFactory` or the
  combined `WebSocketChannelFactory`) as a parameter or a field. The entry
  point of the app injects `webSocketChannelFactoryIo`
  (`tekartik_web_socket_io`), `webSocketChannelClientFactoryBrowser`
  (`tekartik_web_socket_browser`), `webSocketChannelClientFactory`
  (`tekartik_app_web_socket`) or the memory factory in tests.
* Client: `clientFactory.connect<T>(url)` returns a `WebSocketChannel<T>`
  synchronously, *before* the connection is established. Always pass the type
  argument: incoming data is cast to `T` (`String` for a text/JSON protocol,
  `List<int>` for binary, `Object?` when both can arrive). A url with an
  unsupported scheme can throw right away from `connect`, but a connection
  failure is reported later, so `await channel.ready` inside a `try`/`catch`,
  and/or pass `onError:` to `channel.stream.listen`.
* `WebSocketChannel<T>` is a `StreamChannelMixin<T>`: read `channel.stream`
  (**single subscription** - listen once), write `channel.sink.add(message)`,
  finish with `await channel.sink.close()`. The remote end closing completes
  the stream (`onDone`). There is no reconnect, ping or backoff: on `onDone`
  create a brand new channel, never reuse a closed one.
* Server: `serverFactory.serve<T>({Object? address, int? port})` completes with
  a `WebSocketChannelServer<T>` exposing `port` (the effective one, `port: 0`
  or no port means "pick a free one"), `url`, `stream` (one
  `WebSocketChannel<T>` per connected client) and `close()`. `close()` also
  closes every client channel. `address` is implementation specific (io takes a
  `String` or an `InternetAddress`, memory ignores it).
* `WebSocketChannelFactory` just groups the two: `factory.client`,
  `factory.server` and `factory.scheme` (`'ws'`). It is what the shared test
  suite of `tekartik_web_socket_test` takes, so prefer it as the injected type
  when code needs both sides.
* Memory implementation, for tests with no network (works on the VM and in the
  browser): `webSocketChannelServerFactoryMemory.serve<T>()` then
  `webSocketChannelClientFactoryMemory.connect<T>(server.url)`, or the combined
  `webSocketChannelFactoryMemory`. The memory url is `ws:<port>` (scheme `ws`,
  no host) - always pass `server.url` around instead of building it. Serving a
  port already in use throws a `StateError`; connecting to a port with no
  server fails on `ready` and adds the error to `stream`.
* `webSocketMemory` is the global registry of the memory servers
  (`servers`, `channels`, `checkPort`). Only touch it to debug a leaked
  server; a test closes its server instead.
* `smartWebSocketChannelClientFactory(defaultFactory)` returns a factory that
  routes urls starting with `memory:` to the memory factory and everything else
  to `defaultFactory`. Since memory urls are `ws:<port>`, prefer injecting
  `webSocketChannelClientFactoryMemory` explicitly in tests.
* Implementing a new platform: extend `WebSocketChannelClientFactory` and
  return `WebSocketChannelNative<T>(nativeChannel)`, which adapts a
  `package:web_socket_channel` channel (its `ready`, `stream`, `sink`, plus a
  `done` future that completes when the peer closed).
* Anti-patterns: calling `connect` without a type argument (everything becomes
  `dynamic`); listening to `channel.stream` twice; assuming `connect` throws
  when the server is down; importing `dart:io` or a platform package in code
  meant to be shared; hard-coding a factory deep in the code instead of
  injecting it; leaving a memory server open at the end of a test (its port
  stays used).
* Testing: `tekartik_web_socket_test` runs the full conformance suite against
  any `WebSocketChannelFactory` with `webSocketTestMain(factory)`.

## Examples

### Client: connect, send a request, read the answer

```dart
import 'dart:convert';

import 'package:tekartik_web_socket/web_socket_client.dart';

/// Send one json request and wait for the first json response.
///
/// [clientFactory] comes from the platform package (io/browser/app) or is the
/// memory factory in tests.
Future<Map<String, Object?>> sendRequest(
  WebSocketChannelClientFactory clientFactory,
  String url,
  Map<String, Object?> request,
) async {
  var channel = clientFactory.connect<String>(url);
  try {
    // Throws if the connection fails, connect() itself does not.
    await channel.ready;
    // Listen before sending, the stream is single subscription.
    var responseFuture = channel.stream.first;
    channel.sink.add(jsonEncode(request));
    return jsonDecode(await responseFuture) as Map<String, Object?>;
  } finally {
    await channel.sink.close();
  }
}
```

### Server: one echo handler per connected client

```dart
import 'package:tekartik_web_socket/web_socket.dart';

/// Serve an echo server, the caller must `close()` it.
///
/// [serverFactory] is webSocketChannelServerFactoryIo on the VM,
/// webSocketChannelServerFactoryMemory in tests.
Future<WebSocketChannelServer<String>> serveEcho(
  WebSocketChannelServerFactory serverFactory, {
  int? port,
}) async {
  // port null or 0: a free port is picked, read it back on server.port.
  var server = await serverFactory.serve<String>(port: port);
  server.stream.listen((channel) {
    // One channel per client, its stream is single subscription.
    channel.stream.listen(
      (message) => channel.sink.add('echo $message'),
      onDone: () {
        // Client gone, nothing to clean up.
      },
    );
  });
  return server;
}
```

### Test a client/server exchange in memory, with no network

```dart
import 'package:tekartik_web_socket/web_socket.dart';
import 'package:test/test.dart';

void main() {
  test('memory echo', () async {
    // Client and server sides of the same in-memory implementation.
    var factory = webSocketChannelFactoryMemory;
    var server = await factory.server.serve<String>();
    expect(server.url, startsWith('${factory.scheme}:')); // ws:<port>

    var client = factory.client.connect<String>(server.url);
    var serverChannel = await server.stream.first;
    serverChannel.stream.listen((message) {
      serverChannel.sink.add('echo $message');
    });

    await client.ready;
    client.sink.add('hi');
    expect(await client.stream.first, 'echo hi');

    await client.sink.close();
    // Always close, the port stays registered otherwise.
    await server.close();
  });

  test('no server on that port', () async {
    var client = webSocketChannelClientFactoryMemory.connect<String>('ws:9999');
    await expectLater(client.ready, throwsA(isA<Exception>()));
  });
}
```

### Implement the client factory for a new platform

```dart
import 'package:tekartik_web_socket/web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart' as native;

/// Wraps package:web_socket_channel, like tekartik_web_socket_io and
/// tekartik_web_socket_browser do.
class MyWebSocketChannelClientFactory extends WebSocketChannelClientFactory {
  @override
  WebSocketChannel<T> connect<T>(String url) {
    // WebSocketChannelNative adapts ready/stream/sink and casts data to T.
    return WebSocketChannelNative<T>(
      native.WebSocketChannel.connect(Uri.parse(url)),
    );
  }
}
```
