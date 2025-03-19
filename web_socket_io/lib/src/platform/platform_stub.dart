// ignore: implementation_imports
import 'package:tekartik_web_socket/web_socket.dart';

WebSocketChannelServerFactory get webSocketChannelServerFactoryIo =>
    throw UnsupportedError('WebSocketChannelServerFactory on io only');

WebSocketChannelClientFactory get webSocketChannelClientFactoryIo =>
    throw UnsupportedError('WebSocketClientChannelFactoryIo on io only');
WebSocketChannelFactory get webSocketChannelFactoryIo =>
    throw UnsupportedError('webSocketChannelFactoryIo on io only');
