import 'package:tekartik_common_utils/env_utils.dart';
import 'package:tekartik_web_socket_browser/web_socket_browser.dart';
import 'package:test/test.dart';

Future<void> main() async {
  test('api', () async {
    if (!kDartIsWeb) {
      try {
        webSocketChannelClientFactoryBrowser;
        fail('should fail');
      } on UnsupportedError catch (_) {}
      try {
        webSocketClientChannelFactoryBrowser;
        fail('should fail');
      } on UnsupportedError catch (_) {}
    }
  });
}
