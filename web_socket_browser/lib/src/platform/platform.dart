import 'package:tekartik_web_socket/web_socket_client.dart';

import 'platform.dart';
export 'platform_stub.dart' if (dart.library.js_interop) 'platform_web.dart';

/// Compat
WebSocketChannelClientFactory get webSocketClientChannelFactoryBrowser =>
    webSocketChannelClientFactoryBrowser;
