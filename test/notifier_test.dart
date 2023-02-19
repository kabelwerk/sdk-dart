import 'package:test/test.dart';

import 'package:kabelwerk/src/connector.dart';
import 'package:kabelwerk/src/events.dart';
import 'package:kabelwerk/src/notifier.dart';

import 'helpers/setup.dart';

void main() {
  group('connect', () {
    late Connector connector;

    setUp(() async {
      connector = await setUpConnector();
    });

    tearDown(() {
      connector.disconnect();
    });

    test('join error → error event', () {
      // the test server's notifier channel rejects join attempts when the user
      // id is negative
      final notifier = Notifier(connector, -1);

      notifier.on('error', expectAsync1((ErrorEvent event) {}, count: 1));

      notifier.connect();
    });

    test('join ok → ready event', () {
      final notifier = Notifier(connector, 1);

      notifier.on(
          'ready',
          expectAsync1((NotifierReadyEvent event) {
            expect(event.messages.length, equals(1));
          }, count: 1));

      notifier.connect();
    });

    test('call connect twice → state error', () {
      final notifier = Notifier(connector, 0);

      notifier.connect();

      expect(() => notifier.connect(), throwsStateError);
    });
  });

  group('reconnect', () {
    late Connector connector;
    late Notifier notifier;

    setUp(() async {
      connector = await setUpConnector(
          token: 'connect-then-disconnect',
          refreshToken: (_) => Future.value('valid-token'));
    });

    tearDown(() {
      notifier.disconnect();
      connector.disconnect();
    });

    test('new message while reconnecting', () {
      // the test server's notifier channel generates another batch of messages
      // at rejoin if the user id is an odd number
      notifier = Notifier(connector, 1);

      // this also verifies that the ready event is not emitted more than once
      notifier.on(
          'ready',
          expectAsync1((NotifierReadyEvent event) {
            expect(event.messages.length, equals(1));
          }, count: 1));

      notifier.on(
          'updated',
          expectAsync1((NotifierUpdatedEvent event) {
            expect(event.message.id, equals(2));
          }, count: 1));

      notifier.connect();
    });

    test('no new messages while reconnecting', () {
      notifier = Notifier(connector, 2);

      notifier.on(
          'ready',
          expectAsync1((NotifierReadyEvent event) {
            expect(event.messages.length, equals(2));
          }, count: 1));

      notifier.on(
          'updated', expectAsync1((NotifierUpdatedEvent event) {}, count: 0));

      notifier.connect();
    });

    test('multiple new messages while reconnecting', () {
      notifier = Notifier(connector, 3);

      notifier.on(
          'ready',
          expectAsync1((NotifierReadyEvent event) {
            expect(event.messages.length, equals(3));
          }, count: 1));

      notifier.on(
          'updated', expectAsync1((NotifierUpdatedEvent event) {}, count: 3));

      notifier.connect();
    });
  });

  group('message_posted', () {
    late Connector connector;
    late Notifier notifier;

    setUp(() async {
      connector = await setUpConnector();
    });

    tearDown(() {
      notifier.disconnect();
      connector.disconnect();
    });

    test('message_posted → updated event', () {
      // the test server's notifier channel will send a message_posted event
      // when the user id is 41
      notifier = Notifier(connector, 41);

      notifier.on(
          'ready',
          expectAsync1((NotifierReadyEvent event) {
            expect(event.messages.length, equals(41));
          }, count: 1));

      notifier.on(
          'updated',
          expectAsync1((NotifierUpdatedEvent event) {
            expect(event.message.id, equals(42));
          }, count: 1));

      notifier.connect();
    });
  });
}
