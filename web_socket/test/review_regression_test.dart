import 'package:tekartik_web_socket/web_socket.dart';
import 'package:test/test.dart';

void main() {
  group('review regression', () {
    test('memory server closed without being listened to', () async {
      var server = await webSocketChannelServerFactoryMemory.serve<String>();
      var port = server.port;
      await server.close();
      // The port is free again
      var server2 = await webSocketChannelServerFactoryMemory.serve<String>(
        port: port,
      );
      await server2.close();
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('memory dynamic port skips a port already used', () async {
      var server1 = await webSocketChannelServerFactoryMemory.serve<String>();
      // Explicit port, the next one that a dynamic serve would pick
      var server2 = await webSocketChannelServerFactoryMemory.serve<String>(
        port: server1.port + 1,
      );
      var server3 = await webSocketChannelServerFactoryMemory.serve<String>();
      expect(server3.port, isNot(server2.port));
      expect(server3.port, isNot(server1.port));

      // Each server gets its own client
      var client2 = webSocketChannelClientFactoryMemory.connect<String>(
        server2.url,
      );
      var serverChannel2 = await server2.stream.first;
      client2.sink.add('to 2');
      expect(await serverChannel2.stream.first, 'to 2');

      await client2.sink.close();
      for (var server in [server1, server2, server3]) {
        await server.close();
      }
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('client type differs from the server type', () async {
      var server = await webSocketChannelServerFactoryMemory.serve<String>();
      var client = webSocketChannelClientFactoryMemory.connect<Object?>(
        server.url,
      );
      await client.ready;
      var serverChannel = await server.stream.first;
      client.sink.add('hi');
      expect(await serverChannel.stream.first, 'hi');
      var clientFirst = client.stream.first;
      serverChannel.sink.add('hello');
      expect(await clientFirst, 'hello');
      await client.sink.close();
      await server.close();
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('smart client factory routes memory: urls', () async {
      var server = await webSocketChannelServerFactoryMemory.serve<String>();
      var factory = smartWebSocketChannelClientFactory(
        webSocketChannelClientFactoryMemory,
      );
      var client = factory.connect<String>('memory:${server.url}');
      await client.ready;
      var serverChannel = await server.stream.first;
      client.sink.add('hi');
      expect(await serverChannel.stream.first, 'hi');
      await client.sink.close();
      await server.close();
    }, timeout: const Timeout(Duration(seconds: 10)));
  });
}
