import 'package:test/test.dart';

import 'package:kabelwerk/src/config.dart';
import 'package:kabelwerk/src/connector.dart';
import 'package:kabelwerk/src/dispatcher.dart';
import 'package:kabelwerk/src/events.dart';

import 'server.dart';

void main() {
  test('no token or refreshToken → error', () {
    final config = Config();
    final dispatcher = Dispatcher(['error', 'connected', 'disconnected']);

    final connector = Connector(config, dispatcher);

    expect(() => connector.connect(), throwsStateError);
  });

  group('connect with token', () {
    late Config config;
    late Dispatcher dispatcher;
    late Connector connector;

    setUp(() {
      config = Config();
      dispatcher = Dispatcher(['error', 'connected', 'disconnected']);

      connector = Connector(config, dispatcher);
    });

    test('socket opening → connecting state', () async {
      final run = await runServer([Connect()]);
      config.url = run.url;
      config.token = 'token';

      expect(connector.state, equals(ConnectionState.inactive));

      connector.connect();
      expect(connector.state, equals(ConnectionState.connecting));

      await run.done;
    });

    test('socket opened → connected event, online state', () async {
      final run = await runServer([Connect()]);
      config.url = run.url;
      config.token = 'token';

      dispatcher.on(
          'connected',
          expectAsync1((event) {
            expect(event.runtimeType, equals(Connected));

            expect(connector.state, equals(ConnectionState.online));
          }, count: 1));

      connector.connect();
    });

    test('socket closed → disconnected event, connecting state', () async {
      final run = await runServer([Connect(), Disconnect()]);
      config.url = run.url;
      config.token = 'token';

      dispatcher.on(
          'disconnected',
          expectAsync1((event) {
            expect(event.runtimeType, equals(Disconnected));

            expect(connector.state, equals(ConnectionState.connecting));
          }, count: 1));

      connector.connect();
    });

    // test('socket error → error event', () {});
  });

  group('connect with refreshToken', () {
    late Config config;
    late Dispatcher dispatcher;
    late Connector connector;

    setUp(() {
      config = Config();
      dispatcher = Dispatcher(['error', 'connected', 'disconnected']);

      connector = Connector(config, dispatcher);
    });

    test('error obtaining initial token → error event, inactive state', () {
      config.refreshToken =
          expectAsync1((_) => Future.error(Exception('ops')), count: 1);

      dispatcher.on(
          'error',
          expectAsync1((event) {
            expect(event.runtimeType, equals(ErrorEvent));

            expect(connector.state, equals(ConnectionState.inactive));
          }, count: 1));

      connector.connect();
    });

    test('socket opening → connecting state', () async {
      final run = await runServer([Connect()]);
      config.url = run.url;
      config.refreshToken =
          expectAsync1((_) => Future.value('token'), count: 1);

      expect(connector.state, equals(ConnectionState.inactive));

      connector.connect();
      expect(connector.state, equals(ConnectionState.connecting));

      await run.done;
    });

    test('socket opened → connected event, online state', () async {
      final run = await runServer([Connect()]);
      config.url = run.url;
      config.refreshToken =
          expectAsync1((_) => Future.value('token'), count: 1);

      dispatcher.on(
          'connected',
          expectAsync1((event) {
            expect(event.runtimeType, equals(Connected));

            expect(connector.state, equals(ConnectionState.online));
          }, count: 1));

      connector.connect();
    });

    test('socket closed → disconnected event, refresh token, connecting state',
        () async {
      final run = await runServer([Connect(), Disconnect()]);
      config.url = run.url;
      config.refreshToken =
          expectAsync1((_) => Future.value('token'), count: 2);

      dispatcher.on(
          'disconnected',
          expectAsync1((event) {
            expect(event.runtimeType, equals(Disconnected));

            expect(connector.state, equals(ConnectionState.connecting));
          }, count: 1));

      connector.connect();
    });

    // test('socket error → error event', () {});
  });
}
