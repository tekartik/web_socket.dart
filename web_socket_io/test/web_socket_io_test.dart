@TestOn('vm')
library tekartik_web_socket_io.test.web_socket_io_test;

import 'package:test/test.dart';
import 'package:tekartik_web_socket_io/web_socket_io.dart';

import 'package:tekartik_web_socket_test/web_socket_test.dart';
//import 'package:tekartik_serial_wss_client/channel/channel.dart';

void main() {
  webSocketTestMain(webSocketChannelFactoryIo);
}
