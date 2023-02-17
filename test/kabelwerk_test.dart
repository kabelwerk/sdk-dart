import 'dart:async';

import 'package:test/test.dart';

import 'package:kabelwerk/src/connection_state.dart';
import 'package:kabelwerk/src/events.dart';
import 'package:kabelwerk/src/kabelwerk.dart';
import 'package:kabelwerk/src/models.dart';

const serverUrl = 'ws://localhost:4000/socket/user/websocket';

void main() {
  group('connection', () {
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

    // test('join error → error + disconnected event, inactive state', () async {
    //   final run = await runServer([
    //     Connect(),
    //     Join('private', {}, {}, accept: false),
    //   ]);

    //   final kabelwerk = Kabelwerk();
    //   kabelwerk.config.url = run.url;
    //   kabelwerk.config.token = run.token;

    //   kabelwerk.on(
    //       'disconnected',
    //       expectAsync1((event) {
    //         expect(event.runtimeType, equals(DisconnectedEvent));

    //         expect(kabelwerk.state, equals(ConnectionState.inactive));
    //       }, count: 1));

    //   kabelwerk.connect();
    // });

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

    test('ready event is emitted once', () {
      kabelwerk.config.token = 'connect-then-disconnect';
      kabelwerk.config.refreshToken =
          expectAsync1((_) => Future.value('valid-token'), count: 1);

      kabelwerk.on(
          'ready',
          expectAsync1((KabelwerkReadyEvent event) {
            expect(kabelwerk.state, equals(ConnectionState.online));
          }, count: 1));

      kabelwerk.connect();
    });

    test('connected event is emitted each time', () {
      kabelwerk.config.token = 'connect-then-disconnect';
      kabelwerk.config.refreshToken =
          expectAsync1((_) => Future.value('valid-token'), count: 1);

      kabelwerk.on(
          'connected',
          expectAsync1((ConnectedEvent event) {
            expect(event.connectionState, equals(ConnectionState.online));
            expect(kabelwerk.state, equals(ConnectionState.online));
          }, count: 2));

      kabelwerk.connect();
    });

    test('disconnect → disconnected event, inactive state', () async {
      kabelwerk.config.token = 'valid-token';

      kabelwerk.on(
          'disconnected',
          expectAsync1((DisconnectedEvent event) {
            expect(event.connectionState, equals(ConnectionState.inactive));
            expect(kabelwerk.state, equals(ConnectionState.inactive));
          }, count: 1));

      await kabelwerk.connect();
      kabelwerk.disconnect();
    });
  });

  group('user', () {
    late Kabelwerk kabelwerk;

    setUp(() {
      final completer = Completer();

      kabelwerk = Kabelwerk();
      kabelwerk.config.url = serverUrl;
      kabelwerk.config.token = 'valid-token';

      kabelwerk.on('ready', completer.complete);
      kabelwerk.connect();

      // return a future for async setUp
      return completer.future;
    });

    tearDown(() {
      kabelwerk.disconnect();
    });

    test('get user', () {
      expect(kabelwerk.user.runtimeType, equals(User));

      // see test/server/lib/server_web/channels/private_channel.ex
      expect(kabelwerk.user.id, equals(1));
      expect(kabelwerk.user.key, equals('test_user'));
      expect(kabelwerk.user.name, equals('Test User'));
    });

    test('update_user ok → future resolves, user_updated event', () {
      kabelwerk.on(
          'user_updated',
          expectAsync1((UserUpdatedEvent event) {
            expect(event.user.runtimeType, equals(User));
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

    test('update_user error → future rejected', () {
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

    setUp(() {
      final completer = Completer();

      kabelwerk = Kabelwerk();
      kabelwerk.config.url = serverUrl;
      kabelwerk.config.token = 'valid-token';

      kabelwerk.on('ready', completer.complete);
      kabelwerk.connect();

      // return a future for async setUp
      return completer.future;
    });

    tearDown(() {
      kabelwerk.disconnect();
    });

    test('update_device ok → future resolves', () {
      final future = kabelwerk.updateDevice(
          pushNotificationsToken: 'valid-token',
          pushNotificationsEnabled: true);

      future
          .then(expectAsync1((Device device) {
            // see test/server/lib/server_web/channels/private_channel.ex
            expect(device.id, equals(1));
            expect(device.pushNotificationsToken, equals('valid-token'));
            expect(device.pushNotificationsEnabled, equals(true));
          }, count: 1))
          .catchError(expectAsync1((error) {}, count: 0));
    });

    test('update_device error → future rejected', () {
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

    setUp(() {
      final completer = Completer();

      kabelwerk = Kabelwerk();
      kabelwerk.config.url = serverUrl;
      kabelwerk.config.token = 'valid-token';

      kabelwerk.on('ready', completer.complete);
      kabelwerk.connect();

      // return a future for async setUp
      return completer.future;
    });

    tearDown(() {
      kabelwerk.disconnect();
    });

    test('create_room ok → future resolves', () {
      final future = kabelwerk.createRoom(1);

      future
          .then(expectAsync1((int roomId) {
            // see test/server/lib/server_web/channels/private_channel.ex
            expect(roomId, equals(1));
          }, count: 1))
          .catchError(expectAsync1((error) {}, count: 0));
    });

    test('create_room error → future rejected', () {
      final future = kabelwerk.createRoom(2);

      future
          .then(expectAsync1((_) {}, count: 0))
          .catchError(expectAsync1((error) {
            expect(error.runtimeType, equals(ErrorEvent));
          }, count: 1));
    });
  });

  group('open inboxes and rooms', () {
    late Kabelwerk kabelwerk;

    setUp(() {
      final completer = Completer();

      kabelwerk = Kabelwerk();
      kabelwerk.config.url = serverUrl;
      kabelwerk.config.token = 'valid-token';

      kabelwerk.on('ready', completer.complete);
      kabelwerk.connect();

      // return a future for async setUp
      return completer.future;
    });

    tearDown(() {
      kabelwerk.disconnect();
    });

    test('init and connect an inbox', () {
      final inbox = kabelwerk.openInbox();

      inbox.on('ready', expectAsync1((InboxReadyEvent event) {}, count: 1));

      inbox.connect();
    });
  });
}
