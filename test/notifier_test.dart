import 'dart:async';

import 'package:test/test.dart';

import 'package:kabelwerk/src/config.dart';
import 'package:kabelwerk/src/connector.dart';
import 'package:kabelwerk/src/dispatcher.dart';
import 'package:kabelwerk/src/events.dart';
import 'package:kabelwerk/src/models.dart';
import 'package:kabelwerk/src/notifier.dart';

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
    late Notifier notifier;

    test('join error → error event', () {
      // the test server's notifier channel rejects join attempts when the user
      // id is negative
      notifier = Notifier(connector, -1);

      notifier.on('error', expectAsync1((ErrorEvent event) {}, count: 1));

      notifier.connect();
    });

    test('join ok → ready event', () {
      notifier = Notifier(connector, 1);

      notifier.on(
          'ready',
          expectAsync1((NotifierReadyEvent event) {
            expect(event.messages.length, equals(1));
          }, count: 1));

      notifier.connect();
    });

    test('call connect twice → state error', () {
      notifier = Notifier(connector, 0);

      notifier.connect();

      expect(() => notifier.connect(), throwsStateError);
    });
  });

  // group('re-connect', () {
  //   late Connector connector;
  //   late Notifier notifier;

  //   setUp(() {
  //     config.token = 'connect-then-disconnect';

  //     connector = Connector(config, dispatcher);
  //     connector.prepareSocket();

  //     // return a future for async setUp
  //     return connector.connect();
  //   });

  //   tearDown(() {
  //     connector.disconnect();
  //   });

  //   test('after', () {
  //     notifier = Notifier(connector, 1);

  //     notifier.on(
  //         'ready',
  //         expectAsync1((NotifierReadyEvent event) {
  //           expect(event.messages.length, equals(1));
  //         }, count: 1));

  //     notifier.on(
  //         'updated',
  //         expectAsync1((NotifierUpdatedEvent event) {
  //           expect(event.message.id, equals(2));
  //         }, count: 1));

  //     notifier.connect();
  //   });
  // });
}
