import 'package:test/test.dart';

import 'package:kabelwerk/src/connector.dart';
import 'package:kabelwerk/src/events.dart';
import 'package:kabelwerk/src/notifier.dart';

import 'helpers/setup.dart';

void main() {
  group('connect', () {
    late Connector connector;
    late Notifier notifier;

    setUp(() async {
      connector = await setUpConnector();
    });

    tearDown(() {
      connector.disconnect();
    });

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
