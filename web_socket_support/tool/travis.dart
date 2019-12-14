import 'package:path/path.dart';
import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  for (var dir in [
    'web_socket',
    'web_socket_browser',
    'web_socket_io',
    'web_socket_test',
  ]) {
    shell = shell.pushd(join('..', dir));
    await shell.run('''
    
    pub get
    dart tool/travis.dart
    
''');
    shell = shell.popd();
  }
}
