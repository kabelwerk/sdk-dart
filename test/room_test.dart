import 'dart:async';

import 'package:test/test.dart';

import 'package:kabelwerk/src/config.dart';
import 'package:kabelwerk/src/connector.dart';
import 'package:kabelwerk/src/dispatcher.dart';
import 'package:kabelwerk/src/events.dart';
import 'package:kabelwerk/src/models.dart';
import 'package:kabelwerk/src/room.dart';

void main() {
  late Config config;
  late Dispatcher dispatcher;
  late Connector connector;
  late Room room;

  // set up the connector before each test
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

  Future<Room> setUpRoom({int roomId = 0}) {
    final Completer<Room> completer = Completer();

    final room = Room(connector, roomId);

    room.on('ready', (RoomReady event) {
      completer.complete(room);
    });

    room.connect();

    return completer.future;
  }

  group('connect', () {
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
          expectAsync1((MessagePosted event) {
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
