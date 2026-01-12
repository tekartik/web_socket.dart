import 'package:tekartik_web_socket/web_socket.dart';
import 'package:web_socket_channel/html.dart';

/// Browser web socket channel client factory.
class WebSocketChannelClientFactoryBrowser
    extends WebSocketChannelClientFactory {
  @override
  WebSocketChannel<T> connect<T>(String url) {
    return WebSocketChannelNative(HtmlWebSocketChannel.connect(url));
  }
}

WebSocketChannelClientFactoryBrowser?
_browserWebSocketChannelClientChannelFactory;

/// Browser web socket channel client factory.
WebSocketChannelClientFactoryBrowser get webSocketChannelClientFactoryBrowser =>
    _browserWebSocketChannelClientChannelFactory ??=
        WebSocketChannelClientFactoryBrowser();
