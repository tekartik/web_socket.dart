# tekartik_web_socket_browser

The browser client of [tekartik_web_socket](../web_socket/README.md):
`webSocketChannelClientFactoryBrowser` connects a `WebSocketChannel<T>` with
the browser `WebSocket` (`package:web_socket_channel` `HtmlWebSocketChannel`),
for Dart web and Flutter web, dart2js or dart2wasm. Client only: a browser
cannot serve.

## Getting started

Git package, not on pub.dev:

```yaml
dependencies:
  tekartik_web_socket_browser:
    git:
      url: https://github.com/tekartik/web_socket.dart
      path: web_socket_browser
```

```dart
import 'package:tekartik_web_socket_browser/web_socket_browser.dart';

Future<void> main() async {
  // wss:// from an https page.
  var channel = webSocketChannelClientFactoryBrowser.connect<String>(
    'wss://example.com/ws',
  );
  try {
    await channel.ready; // a refused connection throws here
  } catch (e) {
    print('cannot connect: $e');
    return;
  }
  channel.stream.listen((message) => print('received $message'));
  channel.sink.add('hello');
}
```

Shared code takes a `WebSocketChannelClientFactory`; only the web entry point
names `webSocketChannelClientFactoryBrowser` (`webSocketChannelClientFactoryIo`
on the VM, `webSocketChannelClientFactoryMemory` in tests).

## Platforms

Web only. The import compiles everywhere (conditional export), but off the
web the getter throws `UnsupportedError`. `tekartik_app_web_socket` picks the
browser or the io client for Flutter code running everywhere.

## Common pitfalls

* Binary messages: a `List<int>` is sent as bytes and received as a
  `Uint8List`, as on io (connect with `<List<int>>` or `<Object?>`).
* Errors come on `ready` and on `stream`, `connect` itself does not throw for
  a url the browser can resolve: `'dummy'` is resolved against the page url.
* An https page can only open `wss://` urls; there is no custom header, no
  ping and no automatic reconnect.
* `channel.stream` is single subscription: listen once.

## Testing

```bash
dart test -p chrome
dart test -p chrome -c dart2wasm
```

`test/web_socket_browser_test.dart` connects to an echo server started in the
VM by `spawnHybridUri` (`test/src/echo_server_hybrid.dart`). The shared suite
of `tekartik_web_socket_test` needs a server factory, so it cannot run on this
client alone.
