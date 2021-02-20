import 'package:dev_test/package.dart';
import 'package:path/path.dart';

Future main() async {
  for (var dir in [
    'web_socket',
    'web_socket_browser',
    'web_socket_io',
    'web_socket_test',
  ]) {
    await packageRunCi(join('..', dir));
  }
}
