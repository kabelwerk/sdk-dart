import 'dart:async';

import 'package:test/test.dart';

import 'package:kabelwerk/src/connector.dart';
import 'package:kabelwerk/src/events.dart';
import 'package:kabelwerk/src/models.dart';
import 'package:kabelwerk/src/room.dart';

import 'helpers/setup.dart';

void main() {
  late Connector connector;
  late Room room;

  setUp(() async {
    connector = await setUpConnector();
  });

  tearDown(() {
    connector.disconnect();
  });

  Future<Room> setUpRoom({int roomId = 0}) {
    final Completer<Room> completer = Completer();

    final room = Room(connector, roomId);

    room.on('ready', (RoomReadyEvent event) {
      completer.complete(room);
    });

    room.connect();

    return completer.future;
  }

  group('connect', () {
    test('join error → error event', () {
      // the test server's room channel rejects join attempts when the room id
      // is negative
      room = Room(connector, -1);

      room.on('error', expectAsync1((ErrorEvent event) {}, count: 1));

      room.connect();
    });

    test('join ok → ready event', () {
      room = Room(connector, 1);

      room.on(
          'ready',
          expectAsync1((RoomReadyEvent event) {
            expect(event.messages.length, equals(1));
            expect(event.ownMarker, equals(null));
            expect(event.theirMarker, equals(null));
          }, count: 1));

      room.connect();
    });

    test('call connect twice → state error', () {
      room = Room(connector, 1);

      room.connect();

      expect(() => room.connect(), throwsStateError);
    });
  });

  group('load earlier messages', () {
    tearDown(() {
      room.disconnect();
    });

    test('call loadEarlier too early → state error', () {
      room = Room(connector, 0);

      expect(() => room.loadEarlier(), throwsStateError);
    });

    test('0 messages', () async {
      room = await setUpRoom(roomId: 0);

      // no more messages to load
      final List<Message> messages = await room.loadEarlier();
      expect(messages.length, equals(0));
    });

    test('201 messages', () async {
      room = await setUpRoom(roomId: 201);

      // load messages 101-200
      final List<Message> messages1 = await room.loadEarlier();
      expect(messages1.length, equals(100));
      expect(messages1[0].id, equals(2));
      expect(messages1[99].id, equals(101));

      // load the 201st message
      // it is the earliest message, so its id will be 1
      final List<Message> messages2 = await room.loadEarlier();
      expect(messages2.length, equals(1));
      expect(messages2[0].id, equals(1));

      // no more messages to load
      final List<Message> messages3 = await room.loadEarlier();
      expect(messages3.length, equals(0));
    });
  });

  group('post message', () {
    tearDown(() {
      room.disconnect();
    });

    test('call postMessage too early → state error', () {
      room = Room(connector, 0);

      expect(() => room.postMessage(text: "Hello!"), throwsStateError);
    });

    test('post_message error → future rejected', () async {
      room = await setUpRoom();

      final future = room.postMessage(text: "");

      future
          .then(expectAsync1((Message message) {}, count: 0))
          .catchError(expectAsync1((ErrorEvent error) {}, count: 1));
    });

    test('post_message ok → future resolves, message_posted event', () async {
      room = await setUpRoom();

      room.on(
          'message_posted',
          expectAsync1((MessagePostedEvent event) {
            expect(event.message.text, equals("Hello!"));
          }, count: 1));

      final future = room.postMessage(text: "Hello!");

      future
          .then(expectAsync1((Message message) {
            expect(message.text, equals("Hello!"));
          }, count: 1))
          .catchError(expectAsync1((ErrorEvent error) {}, count: 0));
    });
  });

  group('delete message', () {
    tearDown(() {
      room.disconnect();
    });

    test('call deleteMessage too early → state error', () {
      room = Room(connector, 1);

      expect(() => room.deleteMessage(1), throwsStateError);
    });

    test('delete_message error → future rejected', () async {
      room = await setUpRoom(roomId: 1);

      // see test/server/lib/server_web/channels/room_channel.ex
      // IDs of messages not in the room result in errors
      final future = room.deleteMessage(2);

      future
          .then(expectAsync1((Message message) {}, count: 0))
          .catchError(expectAsync1((ErrorEvent error) {}, count: 1));
    });

    test('delete_message ok → future resolves, message_deleted event',
        () async {
      room = await setUpRoom(roomId: 1);

      room.on(
          'message_deleted',
          expectAsync1((MessageDeletedEvent event) {
            expect(event.message.id, equals(1));
          }, count: 1));

      final future = room.deleteMessage(1);

      future
          .then(expectAsync1((Message message) {
            expect(message.id, equals(1));
          }, count: 1))
          .catchError(expectAsync1((ErrorEvent error) {}, count: 0));
    });
  });

  group('move marker', () {
    tearDown(() {
      room.disconnect();
    });

    test('call moveMarker too early → state error', () {
      room = Room(connector, 0);

      expect(() => room.moveMarker(), throwsStateError);
    });

    test('call moveMarker in a room without messages → state error', () async {
      room = await setUpRoom(roomId: 0);

      expect(() => room.moveMarker(), throwsStateError);
    });

    test('move_marker error → future rejected', () async {
      room = await setUpRoom(roomId: 1);

      // see test/server/lib/server_web/channels/room_channel.ex
      // non-positive message IDs result in errors
      final future = room.moveMarker(-1);

      future
          .then(expectAsync1((Marker marker) {}, count: 0))
          .catchError(expectAsync1((ErrorEvent error) {}, count: 1));
    });

    test('move_marker ok → future resolves, marker_moved event', () async {
      room = await setUpRoom(roomId: 1);

      room.on(
          'marker_moved',
          expectAsync1((MarkerMovedEvent event) {
            expect(event.marker, equals(room.ownMarker));
          }, count: 1));

      // move the marker to the latest message in the room
      // as the room only has one message, the latter will have ID 1
      final future = room.moveMarker();

      future
          .then(expectAsync1((Marker marker) {
            expect(marker.messageId, equals(1));

            expect(room.ownMarker, equals(marker));
          }, count: 1))
          .catchError(expectAsync1((ErrorEvent error) {}, count: 0));
    });
  });

  group('attributes', () {
    tearDown(() {
      room.disconnect();
    });

    test('call attributes too early → state error', () {
      room = Room(connector, 0);

      expect(() => room.attributes, throwsStateError);
    });

    test('call updateAttributes too early → state error', () {
      room = Room(connector, 0);

      expect(() => room.updateAttributes({'valid': true}), throwsStateError);
    });

    test('set_attributes error → future rejected', () async {
      room = await setUpRoom();

      final future = room.updateAttributes({'valid': false});

      future
          .then(expectAsync1((Map attributes) {}, count: 0))
          .catchError(expectAsync1((ErrorEvent error) {
            expect(room.attributes.length, equals(0));
          }, count: 1));
    });

    test('set_attributes ok → future resolves, attributes updated', () async {
      room = await setUpRoom();

      final newAttributes = {'valid': true, 'answer': 42};
      final future = room.updateAttributes(newAttributes);

      future
          .then(expectAsync1((Map attributes) {
            expect(attributes, equals(newAttributes));
            expect(room.attributes, equals(newAttributes));
          }, count: 1))
          .catchError(expectAsync1((ErrorEvent error) {}, count: 0));
    });
  });

  group('user', () {
    tearDown(() {
      room.disconnect();
    });

    test('call user too early → state error', () {
      room = Room(connector, 0);

      expect(() => room.user, throwsStateError);
    });

    test('get room user', () async {
      room = await setUpRoom();

      // see test/server/lib/server/factory.ex
      expect(room.user.id, equals(1));
      expect(room.user.key, equals('test_user'));
      expect(room.user.name, equals('Test User'));
    });
  });
}
