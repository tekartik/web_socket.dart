---
name: tekartik-web-socket-test-suite
description: >-
  Use when validating a tekartik_web_socket implementation (io, browser, memory
  or a custom one) against the shared conformance suite of
  tekartik_web_socket_test: the webSocketTestMain(WebSocketChannelFactory)
  entry point from package:tekartik_web_socket_test/web_socket_test.dart, which
  also re-exports the whole tekartik_web_socket API (WebSocketChannel,
  WebSocketChannelFactory, WebSocketChannelClientFactory,
  WebSocketChannelServerFactory, WebSocketChannelServer,
  webSocketChannelFactoryMemory). Covers what the suite requires of connect,
  ready, serve, url, scheme and close, and how to wire it in a dev_dependency.
---

# Shared web socket test suite (tekartik_web_socket_test)

`tekartik_web_socket_test` holds the conformance tests every
`tekartik_web_socket` implementation must pass. A package implementing the
abstraction (io, browser, memory, or a custom transport) adds one test file
that calls `webSocketTestMain(factory)` and gets the whole suite.

## Guidelines

* Not on pub.dev, and it is a test helper: put it in `dev_dependencies` (the
  package lives in the `web_socket_test/` directory of the repo):
  ```yaml
  dev_dependencies:
    tekartik_web_socket_test:
      git:
        url: https://github.com/tekartik/web_socket.dart
        path: web_socket_test
      version: '>=0.1.0'
  ```
  It depends on `test` and on `tekartik_web_socket`, so a test file needs only
  the single import `package:tekartik_web_socket_test/web_socket_test.dart`,
  which re-exports `package:tekartik_web_socket/web_socket.dart` in full
  (`WebSocketChannel`, `WebSocketChannelFactory`,
  `WebSocketChannelClientFactory`, `WebSocketChannelServerFactory`,
  `WebSocketChannelServer`, `WebSocketChannelNative`, `webSocketUrlScheme`, the
  memory factories). Add `package:test/test.dart` only when writing extra
  tests of your own.
* The single entry point is `void webSocketTestMain(WebSocketChannelFactory
  channelFactory)`. Call it from the body of `main()` in a
  `test/*_test.dart` file, alone or inside a `group(...)`. It takes the
  **combined** factory (`.client`, `.server`, `.scheme`), not a client or
  server factory: a client-only implementation such as
  `tekartik_web_socket_browser` cannot run it - test that one against
  `webSocketChannelFactoryMemory` instead.
* Add `@TestOn('vm')` (before `library;`) for an implementation that needs
  dart:io, such as `tekartik_web_socket_io`. The memory factory passes on the
  VM and in the browser (`dart test -p chrome`).
* What the suite declares (group `channel`) and therefore what the
  implementation must honour:
  - `no server`: `client.connect<String>('ws://localhost:9999')` then
    `await channel.ready` must throw (not a `TestFailure`).
  - `simple`: `server.serve()` with no argument, `client.connect(server.url)`,
    `await server.stream.first` for the server side channel, then both sides
    exchange `List<int>` payloads; closing the server, the server channel sink
    or the client sink must complete the other side (`onDone`).
  - `Receive server first` / `Send client first`: a `String` message sent
    before the peer listens must still be delivered, whichever side listens
    first.
  - `failure_right_away`: `client.connect<Object?>('dummy')` (a url with no
    scheme) must throw **synchronously**.
  - `failure_ready`, `failure_on_done`, `failure`: connecting to
    `'${factory.scheme}://dummy'` must fail on `ready`, add the error to
    `stream` and complete it.
* So a new implementation must: pick a free port when `serve()` gets no
  `port`, expose a `url` its own client can `connect` to, deliver messages
  buffered before the peer listens, report connection failures on both `ready`
  and `stream`, and throw right away on an unusable url.
* The suite closes every server and channel it creates; it does not need a
  network besides localhost, and it never uses `setUpAll`, so it can be nested
  in a `group` with other tests.
* `package:tekartik_web_socket_test/web_socket_test.dart` also declares its own
  `main()` running the suite on the memory factory - that is for the package's
  own checks, do not call it.
* Anti-patterns: putting the package in `dependencies` instead of
  `dev_dependencies`; passing a `WebSocketChannelClientFactory` (it does not
  compile, the parameter is a `WebSocketChannelFactory`); running it on the
  browser factory; importing both `web_socket_test.dart` and
  `tekartik_web_socket/web_socket.dart` (the first re-exports the second);
  wrapping it in `setUp`/`test` (it declares tests, so it belongs to the
  declaration phase).

## Examples

### Run the suite against the memory implementation

```dart
import 'package:tekartik_web_socket_test/web_socket_test.dart';

void main() {
  // The whole conformance suite, no network, vm and browser.
  webSocketTestMain(webSocketChannelFactoryMemory);
}
```

### Run it against a dart:io implementation

```dart
@TestOn('vm')
library;

import 'package:tekartik_web_socket_io/web_socket_io.dart';
import 'package:tekartik_web_socket_test/web_socket_test.dart';
import 'package:test/test.dart';

void main() {
  // webSocketChannelFactoryIo groups the io client and server factories.
  webSocketTestMain(webSocketChannelFactoryIo);
}
```

### Nest the suite in a group and add your own tests

```dart
import 'package:tekartik_web_socket_test/web_socket_test.dart';
import 'package:test/test.dart';

void main() {
  // Swap this for the factory of the implementation under test.
  var factory = webSocketChannelFactoryMemory;

  group('my implementation', () {
    // Declares the shared tests here.
    webSocketTestMain(factory);

    test('server url uses the factory scheme', () async {
      var server = await factory.server.serve<String>();
      try {
        expect(server.url, startsWith(factory.scheme));
        var client = factory.client.connect<String>(server.url);
        await client.ready;
        await client.sink.close();
      } finally {
        await server.close();
      }
    });
  });
}
```
