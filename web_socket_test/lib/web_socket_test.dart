import 'dart:async';

import 'package:tekartik_web_socket/web_socket.dart';
import 'package:test/test.dart';

//import 'package:tekartik_serial_wss_client/channel/channel.dart';

void main() {
  webSocketTestMain(webSocketChannelFactoryMemory);
}

void webSocketTestMain(WebSocketChannelFactory channelFactory) {
  group('channel', () {
    group('simple', () {
      late WebSocketChannelServer<List<int>> server;
      WebSocketChannel<List<int>> wsClient;
      late WebSocketChannel<List<int>> wsServer;

      Future simpleTest(Function() close) async {
        server = await channelFactory.server.serve();
        wsClient = channelFactory.client.connect(server.url);
        wsServer = await server.stream.first;

        //wsClient.stream.listen(onData)

        final serverDoneCompleter = Completer();
        final clientDoneCompleter = Completer();
        final masterReceiveCompleter = Completer();
        final slaveReceiveCompleter = Completer();

        wsServer.sink.add([1, 2, 3, 4]);
        wsClient.sink.add([5, 6, 7, 8]);

        wsServer.stream.listen((List<int> data) {
          expect(data, [5, 6, 7, 8]);
          //devPrint(data);
          masterReceiveCompleter.complete();
        }, onDone: () {
          //devPrint('server.onDone');
          serverDoneCompleter.complete();
        }, onError: (e) {
          print('server.onError $e');
        });

        wsClient.stream.listen((List<int> data) {
          expect(data, [1, 2, 3, 4]);
          //devPrint(data);
          slaveReceiveCompleter.complete();
        }, onDone: () {
          //devPrint('client.onDone');
          clientDoneCompleter.complete();
        }, onError: (e) {
          print('client.onError $e');
        });

        await masterReceiveCompleter.future;
        await slaveReceiveCompleter.future;

        // close server
        await close();
        await serverDoneCompleter.future;
        await clientDoneCompleter.future;
      }

      test('close_server', () async {
        await simpleTest(() async {
          await await server.close();
        });
      });

      test('close_ws_server', () async {
        await simpleTest(() async {
          await await wsServer.sink.close();
        });
      });

      test('close_ws_client', () async {
        await simpleTest(() async {
          await await wsServer.sink.close();
        });
      });

      test('Receive server first', () async {
        var server = await channelFactory.server.serve<String>();
        var wsClient = channelFactory.client.connect<String>(server.url);
        var wsServer = await server.stream.first;
        var firstMessageFuture = wsServer.stream.first;
        wsClient.sink.add('hi');
        expect(await firstMessageFuture, 'hi');
        await wsClient.sink.close();
        await server.close();
      });

      test('Send client first', () async {
        var server = await channelFactory.server.serve<String>();
        var wsClient = channelFactory.client.connect<String>(server.url);
        wsClient.sink.add('hi');
        // Here we listen on the server after
        var wsServer = await server.stream.first;
        expect(await wsServer.stream.first, 'hi');
        await wsClient.sink.close();
        await server.close();
      });
    });

    test('failure_right_away', () async {
      var failed = false;
      try {
        channelFactory.client.connect('dummy');
      } catch (_) {
        failed = true;
      }

      expect(failed, isTrue);
    });

    test('failure_on_done', () async {
      WebSocketChannel wsClient;
      wsClient =
          channelFactory.client.connect('${channelFactory.scheme}://dummy');

      var failed = false;
      try {
        await wsClient.stream.toList();
      } catch (e) {
        //devPrint('Err: $e');
        failed = true;
      }

      expect(failed, isTrue);
    });

    test('failure', () async {
      WebSocketChannel wsClient;
      wsClient =
          channelFactory.client.connect('${channelFactory.scheme}://dummy');

      var completer = Completer();
      wsClient.stream.listen((_) {}, onError: (e) {
        print(e);
        completer.complete();
      });
      await completer.future;
    });
  });
}
