# tekartik_web_socket

Portable web sockets for Dart: a `WebSocketChannel<T>` (a `StreamChannel`:
`stream`, `sink`, `ready`) created by a client factory, and a server factory,
so the same code runs on the Dart VM, in the browser and in memory for tests.
This package holds the API and the memory implementation.

## Getting started

Git package, not on pub.dev:

```yaml
dependencies:
  tekartik_web_socket:
    git:
      url: https://github.com/tekartik/web_socket.dart
      path: web_socket
```

An echo server and a client, in memory (no network, any platform):

```dart
import 'package:tekartik_web_socket/web_socket.dart';

Future<void> main() async {
  // webSocketChannelFactoryIo on the VM (tekartik_web_socket_io)
  var factory = webSocketChannelFactoryMemory;
  var server = await factory.server.serve<String>(); // any free port
  server.stream.listen((channel) {
    // One channel per connected client: echo
    channel.stream.listen((message) => channel.sink.add('echo $message'));
  });

  var client = factory.client.connect<String>(server.url);
  await client.ready; // throws if the connection fails
  var answer = client.stream.first;
  client.sink.add('hi');
  print(await answer); // echo hi

  await client.sink.close();
  await server.close();
}
```

## Platforms

| Platform | Package (same repo) | Factories |
|---|---|---|
| Any, in memory (tests) | `tekartik_web_socket` | `webSocketChannelFactoryMemory`, `webSocketChannelClientFactoryMemory`, `webSocketChannelServerFactoryMemory` |
| Dart VM (client and server) | `tekartik_web_socket_io` (`web_socket_io`) | `webSocketChannelFactoryIo`, `webSocketChannelClientFactoryIo`, `webSocketChannelServerFactoryIo` |
| Browser (client) | `tekartik_web_socket_browser` (`web_socket_browser`) | `webSocketChannelClientFactoryBrowser` |
| Flutter, picks io or browser (client) | `tekartik_app_web_socket` (repo app_common_utils.dart) | `webSocketChannelClientFactory` |

Shared code takes a factory as a parameter. Import
`package:tekartik_web_socket/web_socket_client.dart` in client only code (no
server types).

## When to use what

* `clientFactory.connect<T>(url)`: a channel at once, connected later. Await
  `channel.ready` (or listen with `onError`) to know if it failed.
* `serverFactory.serve<T>(port:)`: a `WebSocketChannelServer<T>`, `port` and
  `url` to give to the clients, `stream` of one channel per client,
  `close()` (closes the client channels too).
* `T`: `String` for text/JSON, `List<int>` for binary, `Object?` for both.
* `WebSocketChannelNative<T>(channel)`: wraps a `package:web_socket_channel`
  channel (to write a new platform).
* `smartWebSocketChannelClientFactory(defaultFactory)`: urls
  `memory:<memory server url>` go to the memory factory, the others to
  `defaultFactory`.

## Common pitfalls

* `connect` does not throw when the server is down: await `ready`.
* `channel.stream` is single subscription: listen once.
* A closed channel is not reopened: connect a new one.
* Memory urls are `ws:<port>` (no host): pass `server.url` around, never build
  it.
* Close the servers at the end of a test, or their port stays used.

The [tekartik-web-socket-channels skill](skills/tekartik-web-socket-channels/SKILL.md)
has more examples (request/response client, echo server, tests).
