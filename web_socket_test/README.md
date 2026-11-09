# tekartik_web_socket_test

The shared test suite of [tekartik_web_socket](../web_socket/README.md):
`webSocketTestMain(factory)` checks that a `WebSocketChannelFactory` (client
and server) behaves like the others. The memory and io implementations run it;
a new implementation should too.

## Getting started

Git package, not on pub.dev, a dev dependency:

```yaml
dev_dependencies:
  tekartik_web_socket_test:
    git:
      url: https://github.com/tekartik/web_socket.dart
      path: web_socket_test
```

`test/my_web_socket_test.dart`:

```dart
import 'package:tekartik_web_socket_test/web_socket_test.dart';

void main() {
  // Replace with the factory of the implementation under test,
  // e.g. webSocketChannelFactoryIo under @TestOn('vm').
  webSocketTestMain(webSocketChannelFactoryMemory);
}
```

## What it checks

* Server: `close()` without any listener, `stream` done after `close()`, two
  `serve()` on dynamic ports get different ports, a client typed differently
  from the server (`serve<String>`, `connect<Object?>`) exchanges messages.
* Channels: messages both ways (`String` and `List<int>`), sent before or
  after the peer listens, close from the server, the server channel or the
  client (the other side gets `onDone`).
* Failures: no server, an unusable url throws from `connect`, a bad host
  fails on `ready` and on `stream`.

Each server test has a 10 s timeout. It needs a server factory, so a client
only implementation (the browser one) cannot run it.

## Testing

```bash
dart test # web_socket_io and web_socket run it
```
