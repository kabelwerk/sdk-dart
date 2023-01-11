import 'package:test/test.dart';

import 'package:kabelwerk/src/config.dart';
import 'package:kabelwerk/src/connector.dart';
import 'package:kabelwerk/src/dispatcher.dart';
import 'package:kabelwerk/src/events.dart';

import 'helpers/server.dart';

void main() {
  late Config config;
  late Dispatcher dispatcher;
  late Connector connector;

  setUp(() {
    config = Config();
    dispatcher = Dispatcher(['error', 'connected', 'disconnected']);

    connector = Connector(config, dispatcher);
  });

  test('no token or refreshToken → error', () {
    connector.setupSocket();

    expect(() => connector.connect(), throwsStateError);
  });

  group('connect with token', () {
    test('socket connecting → connecting state', () async {
      final run = await runServer([Connect()]);
      config.url = run.url;
      config.token = run.token;

      expect(connector.state, equals(ConnectionState.inactive));

      connector.setupSocket();
      expect(connector.state, equals(ConnectionState.inactive));

      connector.connect();
      expect(connector.state, equals(ConnectionState.connecting));
    });

    // unlike its js counterpart, the phoenix_wings socket does not invoke its
    // onError callbacks when it fails to connect
    // test('socket connection rejected → connecting state', () async {
    //   final run = await runServer([Connect(accept: false)]);
    //   config.url = run.url;
    //   config.token = run.token;

    //   connector.setupSocket();
    //   connector.connect();

    //   Future.delayed(
    //       Duration(milliseconds: 100),
    //       expectAsync0(() {
    //         expect(connector.state, equals(ConnectionState.connecting));
    //       }, count: 1));
    // });

    test('socket connected → connected event, online state', () async {
      final run = await runServer([Connect()]);
      config.url = run.url;
      config.token = run.token;

      dispatcher.on(
          'connected',
          expectAsync1((event) {
            expect(event.runtimeType, equals(Connected));

            expect(connector.state, equals(ConnectionState.online));
          }, count: 1));

      connector.setupSocket();
      connector.connect();
    });

    // test('socket disconnected → disconnected event, connecting state',
    //     () async {
    //   final run = await runServer([Connect(), Disconnect()]);
    //   config.url = run.url;
    //   config.token = run.token;

    //   dispatcher.on(
    //       'disconnected',
    //       expectAsync1((event) {
    //         expect(event.runtimeType, equals(Disconnected));

    //         expect(connector.state, equals(ConnectionState.connecting));
    //       }, count: 1));

    //   connector.setupSocket();
    //   connector.connect();
    // });

    // test('socket error → error event', () {});

    test('disconnect → disconnected event, inactive state', () async {
      final run = await runServer([Connect()]);
      config.url = run.url;
      config.token = run.token;

      dispatcher.on(
          'connected',
          expectAsync1((_) {
            connector.disconnect();
          }, count: 1));

      dispatcher.on(
          'disconnected',
          expectAsync1((event) {
            expect(event.runtimeType, equals(Disconnected));

            expect(connector.state, equals(ConnectionState.inactive));
          }, count: 1));

      connector.setupSocket();
      connector.connect();
    });
  });

  group('connect with refreshToken', () {
    test('error obtaining initial token → error event, inactive state', () {
      config.refreshToken =
          expectAsync1((_) => Future.error(Exception('ops')), count: 1);

      dispatcher.on(
          'error',
          expectAsync1((event) {
            expect(event.runtimeType, equals(ErrorEvent));

            expect(connector.state, equals(ConnectionState.inactive));
          }, count: 1));

      connector.setupSocket();
      connector.connect();
    });

    test('socket connecting → connecting state', () async {
      final run = await runServer([Connect()]);
      config.url = run.url;
      config.refreshToken =
          expectAsync1((_) => Future.value(run.token), count: 1);

      expect(connector.state, equals(ConnectionState.inactive));

      connector.setupSocket();
      expect(connector.state, equals(ConnectionState.inactive));

      connector.connect();
      expect(connector.state, equals(ConnectionState.connecting));
    });

    // test('socket connection rejected → connecting state', () async {
    //   final run = await runServer([Connect(accept: false)]);
    //   config.url = run.url;

    //   // once to obtain the initial token, once when trying to reconnect
    //   config.refreshToken =
    //       expectAsync1((_) => Future.value(run.token), count: 2);

    //   connector.setupSocket();
    //   connector.connect();

    //   Future.delayed(
    //       Duration(milliseconds: 100),
    //       expectAsync0(() {
    //         expect(connector.state, equals(ConnectionState.connecting));
    //       }, count: 1));
    // });

    test('socket connected → connected event, online state', () async {
      final run = await runServer([Connect()]);
      config.url = run.url;
      config.refreshToken =
          expectAsync1((_) => Future.value(run.token), count: 1);

      dispatcher.on(
          'connected',
          expectAsync1((event) {
            expect(event.runtimeType, equals(Connected));

            expect(connector.state, equals(ConnectionState.online));
          }, count: 1));

      connector.setupSocket();
      connector.connect();
    });

    // test(
    //     'socket disconnected → disconnected event, refresh token, connecting state',
    //     () async {
    //   final run = await runServer([Connect(), Disconnect()]);
    //   config.url = run.url;
    //   config.refreshToken =
    //       expectAsync1((_) => Future.value(run.token), count: 2);

    //   dispatcher.on(
    //       'disconnected',
    //       expectAsync1((event) {
    //         expect(event.runtimeType, equals(Disconnected));

    //         expect(connector.state, equals(ConnectionState.connecting));
    //       }, count: 1));

    //   connector.setupSocket();
    //   connector.connect();
    // });

    // test('socket error → error event', () {});

    test('disconnect → disconnected event, inactive state', () async {
      final run = await runServer([Connect()]);
      config.url = run.url;
      config.refreshToken =
          expectAsync1((_) => Future.value(run.token), count: 1);

      dispatcher.on(
          'connected',
          expectAsync1((_) {
            connector.disconnect();
          }, count: 1));

      dispatcher.on(
          'disconnected',
          expectAsync1((event) {
            expect(event.runtimeType, equals(Disconnected));

            expect(connector.state, equals(ConnectionState.inactive));
          }, count: 1));

      connector.setupSocket();
      connector.connect();
    });
  });

  group('connect with token + refreshToken', () {
    test('socket connecting → connecting state', () async {
      final run = await runServer([Connect()]);
      config.url = run.url;
      config.token = run.token;
      config.refreshToken =
          expectAsync1((_) => Future.error(Exception('ops')), count: 0);

      expect(connector.state, equals(ConnectionState.inactive));

      connector.setupSocket();
      expect(connector.state, equals(ConnectionState.inactive));

      connector.connect();
      expect(connector.state, equals(ConnectionState.connecting));
    });

    // test('socket connection rejected → connecting state', () async {
    //   final run = await runServer([Connect(accept: false)]);
    //   config.url = run.url;
    //   config.token = run.token;

    //   // called when trying to reconnect
    //   config.refreshToken =
    //       expectAsync1((_) => Future.error(Exception('ops')), count: 1);

    //   connector.setupSocket();
    //   connector.connect();

    //   Future.delayed(
    //       Duration(milliseconds: 100),
    //       expectAsync0(() {
    //         expect(connector.state, equals(ConnectionState.connecting));
    //       }, count: 1));
    // });

    test('socket connected → connected event, online state', () async {
      final run = await runServer([Connect()]);
      config.url = run.url;
      config.token = run.token;
      config.refreshToken =
          expectAsync1((_) => Future.error(Exception('ops')), count: 0);

      dispatcher.on(
          'connected',
          expectAsync1((event) {
            expect(event.runtimeType, equals(Connected));

            expect(connector.state, equals(ConnectionState.online));
          }, count: 1));

      connector.setupSocket();
      connector.connect();
    });

    // test(
    //     'socket disconnected → disconnected event, refresh token, connecting state',
    //     () async {
    //   final run = await runServer([Connect(), Disconnect()]);
    //   config.url = run.url;
    //   config.token = run.token;
    //   config.refreshToken =
    //       expectAsync1((_) => Future.value(run.token), count: 1);

    //   dispatcher.on(
    //       'disconnected',
    //       expectAsync1((event) {
    //         expect(event.runtimeType, equals(Disconnected));

    //         expect(connector.state, equals(ConnectionState.connecting));
    //       }, count: 1));

    //   connector.setupSocket();
    //   connector.connect();
    // });

    // test('socket error → error event', () {});

    test('disconnect → disconnected event, inactive state', () async {
      final run = await runServer([Connect()]);
      config.url = run.url;
      config.token = run.token;
      config.refreshToken =
          expectAsync1((_) => Future.error(Exception('ops')), count: 0);

      dispatcher.on(
          'connected',
          expectAsync1((_) {
            connector.disconnect();
          }, count: 1));

      dispatcher.on(
          'disconnected',
          expectAsync1((event) {
            expect(event.runtimeType, equals(Disconnected));

            expect(connector.state, equals(ConnectionState.inactive));
          }, count: 1));

      connector.setupSocket();
      connector.connect();
    });
  });
}
