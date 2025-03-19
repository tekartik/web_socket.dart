import 'package:tekartik_common_utils/env_utils.dart';
import 'package:tekartik_web_socket_io/web_socket_io.dart';
import 'package:test/test.dart';

Future<void> main() async {
  test('api', () async {
    if (kDartIsWeb) {
      try {
        webSocketChannelFactoryIo;
        fail('should fail');
      } on UnsupportedError catch (_) {}
      try {
        webSocketChannelClientFactoryIo;
        fail('should fail');
      } on UnsupportedError catch (_) {}
      try {
        webSocketChannelServerFactoryIo;
        fail('should fail');
      } on UnsupportedError catch (_) {}
    }
  });
}
