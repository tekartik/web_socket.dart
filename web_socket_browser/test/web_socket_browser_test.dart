@TestOn('browser')
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:tekartik_web_socket_browser/web_socket_browser.dart';
import 'package:test/test.dart';

void main() {
  test('echo text and bytes', () async {
    var hybrid = spawnHybridUri('src/echo_server_hybrid.dart');
    var url = await hybrid.stream.first as String;
    var client = webSocketChannelClientFactoryBrowser.connect<Object?>(url);
    await client.ready;
    var received = <Object?>[];
    var allReceived = Completer<void>();
    client.stream.listen((data) {
      received.add(data);
      if (received.length == 3) {
        allReceived.complete();
      }
    });
    client.sink.add('hi');
    // A plain List<int> is sent as bytes, not as the text '1,2,3'.
    client.sink.add([1, 2, 3]);
    client.sink.add(Uint8List.fromList([4, 5]));
    await allReceived.future;
    expect(received[0], 'hi');
    expect(received[1], isA<List<int>>());
    expect(received[1], [1, 2, 3]);
    expect(received[2], [4, 5]);
    await client.sink.close();
  }, timeout: const Timeout(Duration(seconds: 30)));
}
