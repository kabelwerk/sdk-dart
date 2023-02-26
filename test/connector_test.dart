import 'package:test/test.dart';

import 'package:kabelwerk/src/config.dart';
import 'package:kabelwerk/src/connection_state.dart';
import 'package:kabelwerk/src/connector.dart';
import 'package:kabelwerk/src/dispatcher.dart';
import 'package:kabelwerk/src/events.dart';

import 'helpers/setup.dart';

void main() {
  late Config config;
  late Dispatcher dispatcher;
  late Connector connector;

  setUp(() {
    config = Config();
    config.url = serverUrl;

    dispatcher = Dispatcher(['error', 'connected', 'disconnected']);

    connector = Connector(config, dispatcher);
  });

  tearDown(() {
    connector.disconnect();
    dispatcher.off();
  });

  test('no token or refreshToken → error', () {
    connector.prepareSocket();

    expect(() => connector.connect(), throwsStateError);
  });

  test('call connect twice → state error', () async {
    config.token = 'valid-token';
    connector.prepareSocket();

    final future = connector.connect();

    expect(() => connector.connect(), throwsStateError);

    await future;
  });

  group('connect with token', () {
    test('socket connecting → connecting state', () async {
      config.token = 'valid-token';

      expect(connector.state, equals(ConnectionState.inactive));

      connector.prepareSocket();
      expect(connector.state, equals(ConnectionState.inactive));

      final future = connector.connect();
      expect(connector.state, equals(ConnectionState.connecting));

      // allows us to call connector.disconnect in the tearDown hook
      await future;
    });

    test('socket connection rejected → error event, connecting state', () {
      config.token = 'bad-token';

      dispatcher.on(
          'error',
          expectAsync1((ErrorEvent event) {
            expect(connector.state, equals(ConnectionState.connecting));
          }, count: 1));

      connector.prepareSocket();
      connector.connect();
    });

    test('socket connected → connected event, online state', () {
      config.token = 'valid-token';

      dispatcher.on(
          'connected',
          expectAsync1((ConnectedEvent event) {
            expect(event.connectionState, equals(ConnectionState.online));
            expect(connector.state, equals(ConnectionState.online));
          }, count: 1));

      connector.prepareSocket();
      connector.connect();
    });

    test('socket disconnected → disconnected event, connecting state', () {
      config.token = 'connect-then-disconnect';

      dispatcher.on(
          'disconnected',
          expectAsync1((DisconnectedEvent event) {
            expect(event.connectionState, equals(ConnectionState.connecting));
            expect(connector.state, equals(ConnectionState.connecting));
          }, count: 1));

      connector.prepareSocket();
      connector.connect();
    });

    // test('socket error → error event', () {});

    test('disconnect → disconnected event, inactive state', () async {
      config.token = 'valid-token';

      dispatcher.on(
          'disconnected',
          expectAsync1((DisconnectedEvent event) {
            expect(event.connectionState, equals(ConnectionState.inactive));
            expect(connector.state, equals(ConnectionState.inactive));
          }, count: 1));

      connector.prepareSocket();
      await connector.connect();

      connector.disconnect();
    });
  });

  group('connect with refreshToken', () {
    test('error obtaining initial token → error event, inactive state', () {
      config.refreshToken =
          expectAsync1((_) => Future.error(Exception('ops')), count: 1);

      dispatcher.on(
          'error',
          expectAsync1((ErrorEvent event) {
            expect(connector.state, equals(ConnectionState.inactive));
          }, count: 1));

      connector.prepareSocket();
      connector.connect();
    });

    test('socket connecting → connecting state', () async {
      config.refreshToken =
          expectAsync1((_) => Future.value('valid-token'), count: 1);

      expect(connector.state, equals(ConnectionState.inactive));

      connector.prepareSocket();
      expect(connector.state, equals(ConnectionState.inactive));

      final future = connector.connect();
      expect(connector.state, equals(ConnectionState.connecting));

      // allows us to call connector.disconnect in the tearDown hook
      await future;
    });

    test('socket connection rejected → error event, connecting state', () {
      // once to obtain the initial token, once when trying to reconnect
      config.refreshToken =
          expectAsync1((_) => Future.value('bad-token'), count: 2);

      dispatcher.on(
          'error',
          expectAsync1((ErrorEvent event) {
            expect(connector.state, equals(ConnectionState.connecting));
          }, count: 1));

      connector.prepareSocket();
      connector.connect();
    });

    test('socket connected → connected event, online state', () {
      config.refreshToken =
          expectAsync1((_) => Future.value('valid-token'), count: 1);

      dispatcher.on(
          'connected',
          expectAsync1((ConnectedEvent event) {
            expect(event.connectionState, equals(ConnectionState.online));
            expect(connector.state, equals(ConnectionState.online));
          }, count: 1));

      connector.prepareSocket();
      connector.connect();
    });

    test(
        'socket disconnected → disconnected event, refresh token, connecting state',
        () {
      config.refreshToken = expectAsync1(
          (prevToken) => Future.value(
              prevToken == '' ? 'connect-then-disconnect' : 'valid-token'),
          count: 2);

      dispatcher.on(
          'disconnected',
          expectAsync1((DisconnectedEvent event) {
            expect(event.connectionState, equals(ConnectionState.connecting));
            expect(connector.state, equals(ConnectionState.connecting));
          }, count: 1));

      connector.prepareSocket();
      connector.connect();
    });

    test('refresh token failed → error event, connecting state', () {
      // once to obtain the initial token, once when trying to reconnect
      config.refreshToken = expectAsync1(
          (prevToken) => prevToken == ''
              ? Future.value('connect-then-disconnect')
              : Future.error(Exception('ops!')),
          count: 2);

      dispatcher.on(
          'error',
          expectAsync1((ErrorEvent event) {
            expect(connector.state, equals(ConnectionState.connecting));
          }, count: 1));

      connector.prepareSocket();
      connector.connect();
    });

    // test('socket error → error event', () {});

    test('disconnect → disconnected event, inactive state', () async {
      config.refreshToken =
          expectAsync1((_) => Future.value('valid-token'), count: 1);

      dispatcher.on(
          'disconnected',
          expectAsync1((DisconnectedEvent event) {
            expect(event.connectionState, equals(ConnectionState.inactive));
            expect(connector.state, equals(ConnectionState.inactive));
          }, count: 1));

      connector.prepareSocket();
      await connector.connect();

      connector.disconnect();
    });
  });

  group('connect with token + refreshToken', () {
    test('socket connecting → connecting state', () async {
      config.token = 'valid-token';
      config.refreshToken =
          expectAsync1((_) => Future.error(Exception('ops')), count: 0);

      expect(connector.state, equals(ConnectionState.inactive));

      connector.prepareSocket();
      expect(connector.state, equals(ConnectionState.inactive));

      final future = connector.connect();
      expect(connector.state, equals(ConnectionState.connecting));

      // allows us to call connector.disconnect in the tearDown hook
      await future;
    });

    test('socket connection rejected → error event, connecting state', () {
      config.token = 'bad-token';

      // called when trying to reconnect
      config.refreshToken =
          expectAsync1((_) => Future.value('bad-token'), count: 1);

      dispatcher.on(
          'error',
          expectAsync1((ErrorEvent event) {
            expect(connector.state, equals(ConnectionState.connecting));
          }, count: 1));

      connector.prepareSocket();
      connector.connect();
    });

    test('socket connected → connected event, online state', () {
      config.token = 'valid-token';
      config.refreshToken =
          expectAsync1((_) => Future.error(Exception('ops')), count: 0);

      dispatcher.on(
          'connected',
          expectAsync1((ConnectedEvent event) {
            expect(event.connectionState, equals(ConnectionState.online));
            expect(connector.state, equals(ConnectionState.online));
          }, count: 1));

      connector.prepareSocket();
      connector.connect();
    });

    test('socket connection rejected → refreshToken → socket connected', () {
      config.token = 'bad-token';
      config.refreshToken =
          expectAsync1((_) => Future.value('valid-token'), count: 1);

      // connect with bad-token → error event
      dispatcher.on(
          'error',
          expectAsync1((ErrorEvent event) {
            expect(connector.state, equals(ConnectionState.connecting));
          }, count: 1));

      // connect with valid-token → connected event
      dispatcher.on(
          'connected',
          expectAsync1((ConnectedEvent event) {
            expect(event.connectionState, equals(ConnectionState.online));
            expect(connector.state, equals(ConnectionState.online));

            connector.disconnect();
          }, count: 1));

      connector.prepareSocket();
      connector.connect();
    });

    test(
        'socket disconnected → disconnected event, refresh token, connecting state',
        () {
      config.token = 'connect-then-disconnect';
      config.refreshToken =
          expectAsync1((_) => Future.value('valid-token'), count: 1);

      dispatcher.on(
          'disconnected',
          expectAsync1((DisconnectedEvent event) {
            expect(event.connectionState, equals(ConnectionState.connecting));
            expect(connector.state, equals(ConnectionState.connecting));
          }, count: 1));

      connector.prepareSocket();
      connector.connect();
    });

    test('refresh token failed → error event, connecting state', () {
      config.token = 'connect-then-disconnect';
      config.refreshToken =
          expectAsync1((_) => Future.error(Exception('ops')), count: 1);

      dispatcher.on(
          'error',
          expectAsync1((ErrorEvent event) {
            expect(connector.state, equals(ConnectionState.connecting));
          }, count: 1));

      connector.prepareSocket();
      connector.connect();
    });

    // test('socket error → error event', () {});

    test('disconnect → disconnected event, inactive state', () async {
      config.token = 'valid-token';
      config.refreshToken =
          expectAsync1((_) => Future.error(Exception('ops')), count: 0);

      dispatcher.on(
          'disconnected',
          expectAsync1((DisconnectedEvent event) {
            expect(event.connectionState, equals(ConnectionState.inactive));
            expect(connector.state, equals(ConnectionState.inactive));
          }, count: 1));

      connector.prepareSocket();
      await connector.connect();

      connector.disconnect();
    });
  });

  group('call api', () {
    test('bad auth token → future rejected', () {
      config.token = 'bad-token';

      final future = connector.callApi('GET', '/cables/204', {});

      future.catchError(expectAsync1((error) {}, count: 1));
    });

    test('bad response → future rejected', () {
      config.token = 'valid-token';

      final future = connector.callApi('GET', '/cables/400', {});

      future.catchError(expectAsync1((error) {}, count: 1));
    });

    test('good response → future resolves', () {
      config.token = 'valid-token';

      final future = connector.callApi('GET', '/cables/204', {});

      future.then(expectAsync1((error) {}, count: 1));
    });
  });
}
