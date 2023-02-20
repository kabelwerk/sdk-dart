import 'dart:async';

import 'package:test/test.dart';

import 'package:kabelwerk/src/connection_state.dart';
import 'package:kabelwerk/src/events.dart';
import 'package:kabelwerk/src/kabelwerk.dart';
import 'package:kabelwerk/src/models.dart';

import 'helpers/setup.dart';

void main() {
  group('connect', () {
    late Kabelwerk kabelwerk;

    setUp(() {
      kabelwerk = Kabelwerk();
      kabelwerk.config.url = serverUrl;
    });

    tearDown(() {
      kabelwerk.disconnect();
    });

    test('socket connecting → connecting state', () async {
      kabelwerk.config.token = 'valid-token';

      expect(kabelwerk.state, equals(ConnectionState.inactive));

      final future = kabelwerk.connect();
      expect(kabelwerk.state, equals(ConnectionState.connecting));

      await future;
    });

    test('socket connection rejected → error event, connecting state', () {
      kabelwerk.config.token = 'bad-token';

      kabelwerk.on(
          'error',
          expectAsync1((ErrorEvent event) {
            expect(kabelwerk.state, equals(ConnectionState.connecting));
          }, count: 1));

      kabelwerk.connect();
    });

    test('socket connected → connected event, online state', () {
      kabelwerk.config.token = 'valid-token';

      kabelwerk.on(
          'connected',
          expectAsync1((ConnectedEvent event) {
            expect(event.connectionState, equals(ConnectionState.online));
            expect(kabelwerk.state, equals(ConnectionState.online));
          }, count: 1));

      kabelwerk.connect();
    });

    test('join error → error + disconnected event, inactive state', () {
      kabelwerk.config.token = 'valid-token';

      // the test server's private channel will reject the join attempt if the
      // ensure_rooms param is ['error']
      kabelwerk.config.ensureRoomsOn = ['error'];

      kabelwerk.on('error', expectAsync1((ErrorEvent event) {}, count: 1));

      kabelwerk.on(
          'disconnected',
          expectAsync1((DisconnectedEvent event) {
            expect(event.connectionState, equals(ConnectionState.inactive));
            expect(kabelwerk.state, equals(ConnectionState.inactive));
          }, count: 1));

      kabelwerk.connect();
    });

    test('join ok → ready event, online state', () {
      kabelwerk.config.token = 'valid-token';

      kabelwerk.on(
          'ready',
          expectAsync1((KabelwerkReadyEvent event) {
            expect(kabelwerk.state, equals(ConnectionState.online));
          }, count: 1));

      kabelwerk.connect();
    });

    test('socket disconnected → disconnected event, connecting state', () {
      kabelwerk.config.token = 'connect-then-disconnect';

      kabelwerk.on(
          'disconnected',
          expectAsync1((DisconnectedEvent event) {
            expect(event.connectionState, equals(ConnectionState.connecting));
            expect(kabelwerk.state, equals(ConnectionState.connecting));
          }, count: 1));

      kabelwerk.connect();
    });

    test('call connect twice → state error', () async {
      kabelwerk.config.token = 'valid-token';

      final future = kabelwerk.connect();

      expect(() => kabelwerk.connect(), throwsStateError);

      await future;
    });
  });

  group('reconnect', () {
    late Kabelwerk kabelwerk;

    setUp(() {
      kabelwerk = Kabelwerk();
      kabelwerk.config.url = serverUrl;

      kabelwerk.config.token = 'connect-then-disconnect';
      kabelwerk.config.refreshToken =
          expectAsync1((_) => Future.value('valid-token'), count: 1);
    });

    tearDown(() {
      kabelwerk.disconnect();
    });

    test('ready event is emitted once', () {
      kabelwerk.on(
          'ready',
          expectAsync1((KabelwerkReadyEvent event) {
            expect(kabelwerk.state, equals(ConnectionState.online));
          }, count: 1));

      kabelwerk.connect();
    });

    test('connected event is emitted each time', () {
      kabelwerk.on(
          'connected',
          expectAsync1((ConnectedEvent event) {
            expect(event.connectionState, equals(ConnectionState.online));
            expect(kabelwerk.state, equals(ConnectionState.online));
          }, count: 2));

      kabelwerk.connect();
    });

    test('rejoin private channel → user_updated event', () {
      // the private join response will triger a user_updated event regardless
      // of whether the user name has changed
      kabelwerk.on(
          'user_updated',
          expectAsync1((UserUpdatedEvent event) {
            expect(kabelwerk.user, equals(event.user));
          }, count: 1));

      kabelwerk.connect();
    });
  });

  group('disconnect', () {
    late Kabelwerk kabelwerk;

    test('disconnect → disconnected event, inactive state', () async {
      kabelwerk = await setUpKabelwerk();

      kabelwerk.on(
          'disconnected',
          expectAsync1((DisconnectedEvent event) {
            expect(event.connectionState, equals(ConnectionState.inactive));
            expect(kabelwerk.state, equals(ConnectionState.inactive));
          }, count: 1));

      kabelwerk.disconnect();
    });
  });

  group('user', () {
    late Kabelwerk kabelwerk;

    tearDown(() {
      kabelwerk.disconnect();
    });

    test('call user or updateUser too early → state error', () {
      kabelwerk = Kabelwerk();

      expect(() => kabelwerk.user, throwsStateError);
      expect(() => kabelwerk.updateUser(name: 'Valid Name'), throwsStateError);
    });

    test('get user', () async {
      kabelwerk = await setUpKabelwerk();

      // the test server's private channel returns a user with the following
      // properties by default
      expect(kabelwerk.user.id, equals(1));
      expect(kabelwerk.user.key, equals('test_user'));
      expect(kabelwerk.user.name, equals('Test User'));
    });

    test('update_user ok → future resolves, user_updated event', () async {
      kabelwerk = await setUpKabelwerk();

      kabelwerk.on(
          'user_updated',
          expectAsync1((UserUpdatedEvent event) {
            expect(event.user.id, equals(1));
            expect(event.user.key, equals('test_user'));
            expect(event.user.name, equals('Valid Name'));

            expect(kabelwerk.user, equals(event.user));
          }, count: 1));

      final future = kabelwerk.updateUser(name: 'Valid Name');

      future
          .then(expectAsync1((User user) {
            expect(user.id, equals(1));
            expect(user.key, equals('test_user'));
            expect(user.name, equals('Valid Name'));

            expect(kabelwerk.user, equals(user));
          }, count: 1))
          .catchError(expectAsync1((error) {}, count: 0));
    });

    test('update_user error → future rejected', () async {
      kabelwerk = await setUpKabelwerk();

      final future = kabelwerk.updateUser(name: 'Invalid Name');

      future
          .then(expectAsync1((_) {}, count: 0))
          .catchError(expectAsync1((ErrorEvent error) {
            expect(kabelwerk.user.name, equals('Test User'));
          }, count: 1));
    });
  });

  group('device', () {
    late Kabelwerk kabelwerk;

    tearDown(() {
      kabelwerk.disconnect();
    });

    test('call updateDevice too early → state error', () {
      kabelwerk = Kabelwerk();

      expect(
          () => kabelwerk.updateDevice(
              pushNotificationsToken: 'valid-token',
              pushNotificationsEnabled: true),
          throwsStateError);
    });

    test('update_device ok → future resolves', () async {
      kabelwerk = await setUpKabelwerk();

      // the test server's private channel accepts update_device requests only
      // when made with the parameters below
      final future = kabelwerk.updateDevice(
          pushNotificationsToken: 'valid-token',
          pushNotificationsEnabled: true);

      future
          .then(expectAsync1((Device device) {
            expect(device.id, equals(1));
            expect(device.pushNotificationsToken, equals('valid-token'));
            expect(device.pushNotificationsEnabled, equals(true));
          }, count: 1))
          .catchError(expectAsync1((error) {}, count: 0));
    });

    test('update_device error → future rejected', () async {
      kabelwerk = await setUpKabelwerk();

      final future = kabelwerk.updateDevice(
          pushNotificationsToken: 'bad-token', pushNotificationsEnabled: true);

      future
          .then(expectAsync1((_) {}, count: 0))
          .catchError(expectAsync1((error) {
            expect(error.runtimeType, equals(ErrorEvent));
          }, count: 1));
    });
  });

  group('create room', () {
    late Kabelwerk kabelwerk;

    tearDown(() {
      kabelwerk.disconnect();
    });

    test('call createRoom too early → state error', () {
      kabelwerk = Kabelwerk();

      expect(() => kabelwerk.createRoom(1), throwsStateError);
    });

    test('create_room ok → future resolves', () async {
      kabelwerk = await setUpKabelwerk();

      // the test server's private channel accepts create_room requests only if
      // the hub id is 1
      final future = kabelwerk.createRoom(1);

      future
          .then(expectAsync1((int roomId) {
            expect(roomId, equals(1));
          }, count: 1))
          .catchError(expectAsync1((error) {}, count: 0));
    });

    test('create_room error → future rejected', () async {
      kabelwerk = await setUpKabelwerk();

      final future = kabelwerk.createRoom(2);

      future
          .then(expectAsync1((_) {}, count: 0))
          .catchError(expectAsync1((error) {
            expect(error.runtimeType, equals(ErrorEvent));
          }, count: 1));
    });
  });

  group('open inboxes, notifiers, and rooms', () {
    late Kabelwerk kabelwerk;

    tearDown(() {
      kabelwerk.disconnect();
    });

    test('call open* too early → state error', () {
      kabelwerk = Kabelwerk();

      expect(() => kabelwerk.openInbox(), throwsStateError);
      expect(() => kabelwerk.openNotifier(), throwsStateError);
      expect(() => kabelwerk.openRoom(), throwsStateError);
    });

    test('init and connect an inbox', () async {
      kabelwerk = await setUpKabelwerk();

      final inbox = kabelwerk.openInbox();

      inbox.on('ready', expectAsync1((InboxReadyEvent event) {}, count: 1));

      inbox.connect();
    });

    test('init and connect a notifier', () async {
      kabelwerk = await setUpKabelwerk();

      final notifier = kabelwerk.openNotifier();

      notifier.on(
          'ready',
          expectAsync1((NotifierReadyEvent event) {
            expect(event.messages.length, equals(1));
          }, count: 1));

      notifier.connect();
    });

    test('init and connect a room', () async {
      kabelwerk = await setUpKabelwerk();

      final room = kabelwerk.openRoom(18);

      room.on(
          'ready',
          expectAsync1((RoomReadyEvent event) {
            expect(event.messages.length, equals(18));
          }, count: 1));

      room.connect();
    });

    test('init and connect a room, without an id', () async {
      kabelwerk = await setUpKabelwerk();

      final room = kabelwerk.openRoom();

      room.on(
          'ready',
          expectAsync1((RoomReadyEvent event) {
            // room id 0 opens an arbitrary room on the real backend
            expect(event.messages.length, equals(0));
          }, count: 1));

      room.connect();
    });
  });
}
