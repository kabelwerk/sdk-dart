import 'dart:async';

import 'package:test/test.dart';

import 'package:kabelwerk/src/connector.dart';
import 'package:kabelwerk/src/events.dart';
import 'package:kabelwerk/src/inbox.dart';
import 'package:kabelwerk/src/models.dart';

import 'helpers/setup.dart';

void main() {
  late Connector connector;

  setUp(() async {
    connector = await setUpConnector();
  });

  tearDown(() {
    connector.disconnect();
  });

  group('connect', () {
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

  group('items', () {
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

    test('41 + 1 items', () {
      final inbox = Inbox(connector, 41);

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
