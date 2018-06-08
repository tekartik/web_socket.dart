@TestOn("vm")
library _;

import 'package:test/test.dart';
import 'package:tekartik_web_socket_io/web_socket_io.dart';

import 'package:tekartik_web_socket_test/web_socket_test.dart';
//import 'package:tekartik_serial_wss_client/channel/channel.dart';

main() {
  web_socket_test_main(webSocketChannelFactoryIo);
}
