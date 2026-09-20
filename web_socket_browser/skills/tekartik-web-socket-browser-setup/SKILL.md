---
name: tekartik-web-socket-browser-setup
description: >-
  Use when connecting to a web socket from a Dart or Flutter web app with
  tekartik_web_socket_browser: the webSocketChannelClientFactoryBrowser getter
  (and its webSocketClientChannelFactoryBrowser compat alias) from
  package:tekartik_web_socket_browser/web_socket_browser.dart, which wraps
  HtmlWebSocketChannel and returns a WebSocketChannel<T> (ready, stream, sink)
  via connect<T>(url), the client-only re-export of
  tekartik_web_socket/web_socket_client.dart (WebSocketChannelClientFactory,
  webSocketUrlScheme, webSocketChannelClientFactoryMemory,
  smartWebSocketChannelClientFactory), the UnsupportedError thrown off the web,
  and testing with dart test -p chrome.
---

# tekartik_web_socket_browser: the web implementation

`tekartik_web_socket_browser` implements the client side of
`tekartik_web_socket` with the browser `WebSocket` (through
`package:web_socket_channel`'s `HtmlWebSocketChannel`). Client only: a browser
cannot serve. Importing it is safe everywhere, but the getter throws
`UnsupportedError` outside the web.

## Guidelines

* Not on pub.dev, depend on it through git (the package lives in the
  `web_socket_browser/` directory of the repo):
  ```yaml
  dependencies:
    tekartik_web_socket_browser:
      git:
        url: https://github.com/tekartik/web_socket.dart
        path: web_socket_browser
      version: '>=0.2.2'
  ```
  It brings `tekartik_web_socket` (same repo, `path: web_socket`), which shared
  code is written against; declare that one explicitly too when a library
  imports it directly.
* One import: `package:tekartik_web_socket_browser/web_socket_browser.dart`. It
  re-exports the **client-only** subset
  `package:tekartik_web_socket/web_socket_client.dart` (`WebSocketChannel`,
  `WebSocketChannelClientFactory`, `webSocketUrlScheme`,
  `WebSocketChannelNative`, `webSocketChannelClientFactoryMemory`,
  `smartWebSocketChannelClientFactory`) and adds
  `webSocketChannelClientFactoryBrowser`, plus the older alias
  `webSocketClientChannelFactoryBrowser` (same object, kept for compatibility -
  prefer the first one). There is no server factory and no
  `WebSocketChannelFactory` here.
* The import uses a conditional export (`dart.library.js_interop`), so it
  compiles on the VM too, where the getters throw `UnsupportedError`. Never
  reference them from shared code: inject a `WebSocketChannelClientFactory`, or
  depend on `tekartik_app_web_socket`, which picks
  `tekartik_web_socket_browser` on the web and `tekartik_web_socket_io`
  elsewhere.
* `webSocketChannelClientFactoryBrowser.connect<T>(url)` returns a
  `WebSocketChannel<T>` synchronously, before the socket is open. Pass the type
  argument: `connect<String>` for a text/JSON protocol, `connect<Object?>` when
  the peer may also send binary frames (the browser delivers them as a
  `ByteBuffer`/`Blob`, not as `List<int>`).
* `await channel.ready` in a `try`/`catch`: a refused connection is reported
  there and on `channel.stream` (`onError`), never by `connect`. Read with a
  single `channel.stream.listen(...)` (single subscription stream), write with
  `channel.sink.add(...)`, finish with `await channel.sink.close()`.
* Browser constraints: a page served over `https` (or a Flutter web release
  build behind https) may only open `wss://` urls; the browser sends the page
  origin, and custom headers, sub-protocols or a ping interval are not
  available through this factory. Cross origin is controlled by the server, not
  by the client. There is no automatic reconnect: on `onDone`, create a new
  channel after a delay.
* Testing: browser tests need `dev_dependencies` on `test` and
  `build_web_compilers`, and run with `dart test -p chrome`. The real factory
  needs a server, so test application logic against
  `webSocketChannelClientFactoryMemory` (re-exported here), which also runs in
  the browser. The full conformance suite of `tekartik_web_socket_test`
  (`webSocketTestMain`) needs both sides, so it can only be run with the memory
  factory here, not with the browser one.
* Anti-patterns: importing `web_socket_browser.dart` in shared/VM code and
  touching the getter; expecting a server factory; using `ws://` from an https
  page; listening twice to `channel.stream`; hard-coding the factory instead of
  injecting it (it makes the code untestable on the VM).

## Examples

### Connect from a web app

```dart
import 'dart:convert';

import 'package:tekartik_web_socket_browser/web_socket_browser.dart';

Future<void> main() async {
  // wss:// is required from an https page.
  var channel = webSocketChannelClientFactoryBrowser.connect<String>(
    'wss://example.com/ws',
  );
  try {
    // connect() never throws on failure, ready does.
    await channel.ready;
  } catch (e) {
    print('cannot connect: $e');
    return;
  }

  // Single subscription stream: listen once.
  channel.stream.listen(
    (message) => print('received ${jsonDecode(message)}'),
    onError: (Object e) => print('socket error $e'),
    onDone: () => print('socket closed'),
  );
  channel.sink.add(jsonEncode({'action': 'hello'}));
}
```

### Inject the factory, so the logic stays testable

```dart
import 'package:tekartik_web_socket_browser/web_socket_browser.dart';

/// Shared code: no browser import, just the abstraction.
class ChatClient {
  final String url;
  final WebSocketChannelClientFactory clientFactory;
  WebSocketChannel<String>? _channel;

  ChatClient({required this.url, required this.clientFactory});

  Future<void> connect() async {
    var channel = clientFactory.connect<String>(url);
    await channel.ready;
    _channel = channel;
  }

  void send(String message) => _channel!.sink.add(message);

  Future<void> close() async => _channel?.sink.close();
}

Future<void> main() async {
  // Web entry point: the only place naming the browser factory.
  var client = ChatClient(
    url: 'wss://example.com/ws',
    clientFactory: webSocketChannelClientFactoryBrowser,
  );
  await client.connect();
  client.send('hi');
}
```

### Test the same logic in the browser, without a server

```dart
@TestOn('browser')
library;

import 'package:tekartik_web_socket_browser/web_socket_browser.dart';
import 'package:tekartik_web_socket_test/web_socket_test.dart';
import 'package:test/test.dart';

void main() {
  // Runs with: dart test -p chrome
  test('browser factory is available', () {
    expect(webSocketChannelClientFactoryBrowser, isNotNull);
    // Same object, older name.
    expect(webSocketClientChannelFactoryBrowser, isNotNull);
  });

  // The browser has no server: the shared suite runs on the memory factory,
  // which works in the browser too.
  webSocketTestMain(webSocketChannelFactoryMemory);
}
```
