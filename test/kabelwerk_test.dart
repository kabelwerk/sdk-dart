import 'dart:async';

import 'package:test/test.dart';

import 'package:kabelwerk/src/connection_state.dart';
import 'package:kabelwerk/src/events.dart';
import 'package:kabelwerk/src/kabelwerk.dart';
import 'package:kabelwerk/src/models.dart';

const serverUrl = 'ws://localhost:4000/socket/user/websocket';

void main() {
  group('connection', () {
    test('socket connecting → connecting state', () {
      final kabelwerk = Kabelwerk();
      kabelwerk.config.url = serverUrl;
      kabelwerk.config.token = 'valid-token';

      expect(kabelwerk.state, equals(ConnectionState.inactive));

      kabelwerk.connect();
      expect(kabelwerk.state, equals(ConnectionState.connecting));
    });

    test('socket connection rejected → error event, connecting state', () {
      final kabelwerk = Kabelwerk();
      kabelwerk.config.url = serverUrl;
      kabelwerk.config.token = 'bad-token';

      kabelwerk.on(
          'error',
          expectAsync1((event) {
            expect(event.runtimeType, equals(ErrorEvent));

            expect(kabelwerk.state, equals(ConnectionState.connecting));
          }, count: 1));

      kabelwerk.connect();
    });

    test('socket connected → connected event, online state', () {
      final kabelwerk = Kabelwerk();
      kabelwerk.config.url = serverUrl;
      kabelwerk.config.token = 'valid-token';

      kabelwerk.on(
          'connected',
          expectAsync1((event) {
            expect(event.runtimeType, equals(Connected));

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
    //         expect(event.runtimeType, equals(Disconnected));

    //         expect(kabelwerk.state, equals(ConnectionState.inactive));
    //       }, count: 1));

    //   kabelwerk.connect();
    // });

    // test('join timeout → error event, online state', () async {});

    test('join ok → ready event, online state', () {
      final kabelwerk = Kabelwerk();
      kabelwerk.config.url = serverUrl;
      kabelwerk.config.token = 'valid-token';

      kabelwerk.on(
          'ready',
          expectAsync1((event) {
            expect(event.runtimeType, equals(KabelwerkReady));

            expect(kabelwerk.state, equals(ConnectionState.online));
          }, count: 1));

      kabelwerk.connect();
    });

    // test('socket disconnected → disconnected event, connecting state',
    //     () async {
    //   final run = await runServer([
    //     Connect(),
    //     Join('private', {}, {'id': 1, 'key': 'test', 'name': 'Test'}),
    //     Disconnect(),
    //   ]);

    //   final kabelwerk = Kabelwerk();
    //   kabelwerk.config.url = run.url;
    //   kabelwerk.config.token = run.token;

    //   kabelwerk.on(
    //       'disconnected',
    //       expectAsync1((event) {
    //         expect(event.runtimeType, equals(Disconnected));

    //         expect(kabelwerk.state, equals(ConnectionState.connecting));
    //       }, count: 1));

    //   kabelwerk.connect();
    // });

    test('ready event is emitted once', () async {});

    test('connected event is emitted each time', () async {});

    // test('disconnect → disconnected event, inactive state', () {
    //   final kabelwerk = Kabelwerk();
    //   kabelwerk.config.url = serverUrl;
    //   kabelwerk.config.token = run.token;

    //   kabelwerk.on(
    //       'connected',
    //       expectAsync1((_) {
    //         kabelwerk.disconnect();
    //       }, count: 1));

    //   kabelwerk.on(
    //       'disconnected',
    //       expectAsync1((event) {
    //         expect(event.runtimeType, equals(Disconnected));

    //         expect(kabelwerk.state, equals(ConnectionState.inactive));
    //       }, count: 1));

    //   kabelwerk.connect();
    // });

    // test('disconnect removes the event listeners', () async {});
  });

  group('user info', () {
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

    test('update user ok → future resolves, user_updated event', () {
      kabelwerk.on(
          'user_updated',
          expectAsync1((UserUpdated event) {
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

    test('update user error → future rejected', () {
      final future = kabelwerk.updateUser(name: 'Invalid Name');

      future
          .then(expectAsync1((_) {}, count: 0))
          .catchError(expectAsync1((error) {
            expect(error.runtimeType, equals(ErrorEvent));
            expect(kabelwerk.user.name, equals('Test User'));
          }, count: 1));
    });
  });

  group('update device', () {});

  group('create room', () {});
}
