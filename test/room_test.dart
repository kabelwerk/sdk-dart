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

  group('post message', () {
    late Room room;

    setUp(() {
      final completer = Completer();

      room = Room(connector, 0);
      room.on('ready', completer.complete);
      room.connect();

      // return a future for async setUp
      return completer.future;
    });

    tearDown(() {
      room.disconnect();
    });

    test('post_message ok → future resolves, message_posted event', () {
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

    test('post_message error → future rejected', () {
      final future = room.postMessage(text: "");

      future
          .then(expectAsync1((Message message) {}, count: 0))
          .catchError(expectAsync1((ErrorEvent error) {}, count: 1));
    });
  });
}
