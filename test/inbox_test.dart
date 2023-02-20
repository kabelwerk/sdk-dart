import 'dart:async';

import 'package:test/test.dart';

import 'package:kabelwerk/src/connector.dart';
import 'package:kabelwerk/src/events.dart';
import 'package:kabelwerk/src/inbox.dart';
import 'package:kabelwerk/src/models.dart';

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
      // the test server's inbox channel rejects join attempts when the user id
      // is negative
      final inbox = Inbox(connector, -1);

      inbox.on('error', expectAsync1((ErrorEvent event) {}, count: 1));

      inbox.connect();
    });

    test('join ok, list_rooms ok → ready event', () {
      final inbox = Inbox(connector, 1);

      inbox.on(
          'ready',
          expectAsync1((InboxReadyEvent event) {
            expect(inbox.items.length, equals(1));
            expect(event.items, equals(inbox.items));
          }, count: 1));

      inbox.connect();
    });

    test('call connect twice → state error', () {
      final inbox = Inbox(connector, 0);

      inbox.connect();

      expect(() => inbox.connect(), throwsStateError);
    });
  });

  group('reconnect', () {
    late Connector connector;
    late Inbox inbox;

    setUp(() async {
      connector = await setUpConnector(
          token: 'connect-then-disconnect',
          refreshToken: (_) => Future.value('valid-token'));
    });

    tearDown(() {
      inbox.disconnect();
      connector.disconnect();
    });

    test('updates while reconnecting', () {
      inbox = Inbox(connector, 1);

      // this also verifies that the ready event is not emitted more than once
      inbox.on(
          'ready',
          expectAsync1((InboxReadyEvent event) {
            expect(event.items.length, equals(1));
          }, count: 1));

      // the list_rooms response will trigger an updated event regardless of
      // whether the inbox items have changed
      inbox.on(
          'updated',
          expectAsync1((InboxUpdatedEvent event) {
            expect(event.items.length, equals(1));
          }, count: 1));

      inbox.connect();
    });
  });

  group('load more items', () {
    late Connector connector;

    setUp(() async {
      connector = await setUpConnector();
    });

    tearDown(() {
      connector.disconnect();
    });

    Future<Inbox> setUpInbox(userId) {
      final Completer<Inbox> completer = Completer();
      final inbox = Inbox(connector, userId);

      inbox.on('ready', (InboxReadyEvent event) {
        completer.complete(inbox);
      });

      inbox.connect();

      return completer.future;
    }

    test('0 items', () async {
      final inbox = await setUpInbox(0);
      expect(inbox.items.length, equals(0));

      final List<InboxItem> items = await inbox.loadMore();
      expect(inbox.items, equals(items));
      expect(inbox.items.length, equals(0));
    });

    test('21 items', () async {
      final inbox = await setUpInbox(21);
      expect(inbox.items.length, equals(10));

      // load the second 10 items
      final List<InboxItem> items1 = await inbox.loadMore();
      expect(inbox.items, equals(items1));
      expect(inbox.items.length, equals(20));

      // load the last item
      final List<InboxItem> items2 = await inbox.loadMore();
      expect(inbox.items, equals(items2));
      expect(inbox.items.length, equals(21));

      // no more items to load
      final List<InboxItem> items3 = await inbox.loadMore();
      expect(inbox.items, equals(items3));
      expect(inbox.items.length, equals(21));
    });
  });

  group('inbox_updated', () {
    late Connector connector;
    late Inbox inbox;

    setUp(() async {
      connector = await setUpConnector();
    });

    tearDown(() {
      inbox.disconnect();
      connector.disconnect();
    });

    test('inbox_updated → updated event', () {
      // the test server's user inbox channel will send an inbox_updated event
      // when the user id is 41
      inbox = Inbox(connector, 41);

      inbox.on(
          'ready',
          expectAsync1((InboxReadyEvent event) {
            expect(inbox.items, equals(event.items));
            expect(inbox.items.length, equals(10));
          }, count: 1));

      inbox.on(
          'updated',
          expectAsync1((InboxUpdatedEvent event) {
            expect(inbox.items, equals(event.items));
            expect(inbox.items.length, equals(11));
          }, count: 1));

      inbox.connect();
    });
  });
}
