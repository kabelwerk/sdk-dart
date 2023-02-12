import 'package:test/test.dart';

import 'package:kabelwerk/src/config.dart';
import 'package:kabelwerk/src/connector.dart';
import 'package:kabelwerk/src/dispatcher.dart';
import 'package:kabelwerk/src/events.dart';
import 'package:kabelwerk/src/room.dart';

void main() {
  late Config config;
  late Dispatcher dispatcher;
  late Connector connector;

  setUp(() {
    config = Config();
    config.url = 'ws://localhost:4000/socket/user/websocket';
    config.token = 'valid-token';

    dispatcher = Dispatcher(['error', 'connected', 'disconnected']);

    connector = Connector(config, dispatcher);
    connector.prepareSocket();

    // return a future for async setUp
    return connector.connect();
  });

  tearDown(() {
    connector.disconnect();
    dispatcher.off();
  });

  group('connect', () {
    late Room room;

    test('join error → error event', () {
      room = Room(connector, -1);

      room.on('error', expectAsync1((ErrorEvent event) {}, count: 1));

      room.connect();
    });

    test('join ok → ready event', () {
      room = Room(connector, 1);

      room.on(
          'ready',
          expectAsync1((RoomReady event) {
            expect(event.messages.length, equals(1));
          }, count: 1));

      room.connect();
    });

    test('call connect twice → state error', () {
      room = Room(connector, 1);

      room.connect();

      expect(() => room.connect(), throwsStateError);
    });
  });
}
