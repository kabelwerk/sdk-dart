import 'package:test/test.dart';

import 'package:kabelwerk/src/config.dart';
import 'package:kabelwerk/src/connector.dart';
import 'package:kabelwerk/src/dispatcher.dart';
import 'package:kabelwerk/src/events.dart';
import 'package:kabelwerk/src/inbox.dart';

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
    late Inbox inbox;

    test('join error → error event', () {
      inbox = Inbox(connector, -1);

      inbox.on('error', expectAsync1((ErrorEvent event) {}, count: 1));

      inbox.connect();
    });

    test('join ok, list_rooms ok → ready event', () {
      inbox = Inbox(connector, 1);

      inbox.on(
          'ready',
          expectAsync1((InboxReady event) {
            expect(event.items.length, equals(1));
          }, count: 1));

      inbox.connect();
    });
  });
}
