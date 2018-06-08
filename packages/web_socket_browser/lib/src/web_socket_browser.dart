import 'package:tekartik_web_socket/web_socket.dart';
import 'package:web_socket_channel/html.dart';

class WebSocketChannelClientFactoryBrowser
    extends WebSocketChannelClientFactory {
  @override
  WebSocketChannel<T> connect<T>(String url) {
    return new WebSocketChannelNative(new HtmlWebSocketChannel.connect(url));
  }
}

WebSocketChannelClientFactoryBrowser _browserWebSocketClientChannelFactory;

WebSocketChannelClientFactoryBrowser get webSocketClientChannelFactoryBrowser =>
    _browserWebSocketClientChannelFactory ??=
        new WebSocketChannelClientFactoryBrowser();
