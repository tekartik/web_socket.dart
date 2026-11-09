# web_socket.dart

Portable web sockets for Dart: the same client and server code on the Dart VM,
in the browser and in memory for tests. A pub workspace.

| Package | Folder | What |
|---|---|---|
| `tekartik_web_socket` | [`web_socket/`](web_socket) | The API (`WebSocketChannel`, client/server factories) and the memory implementation. Start with its [README](web_socket/README.md). |
| `tekartik_web_socket_io` | [`web_socket_io/`](web_socket_io) | Dart VM client and server: `webSocketChannelFactoryIo`. |
| `tekartik_web_socket_browser` | [`web_socket_browser/`](web_socket_browser) | Browser client: `webSocketChannelClientFactoryBrowser`. |
| `tekartik_web_socket_test` | [`web_socket_test/`](web_socket_test) | Shared test suite of a factory: `webSocketTestMain(factory)`. |

## Getting started

Git packages, not on pub.dev. Shared code:

```yaml
dependencies:
  tekartik_web_socket:
    git:
      url: https://github.com/tekartik/web_socket.dart
      path: web_socket
```

On the VM add `tekartik_web_socket_io` (path `web_socket_io`), in the browser
`tekartik_web_socket_browser` (path `web_socket_browser`), and give their
factory to the shared code. See the
[tekartik_web_socket README](web_socket/README.md) for an example.

## Testing

```bash
# from a package folder
dart test
```
