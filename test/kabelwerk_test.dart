import 'package:test/test.dart';

import 'package:kabelwerk/src/connector.dart';
import 'package:kabelwerk/src/events.dart';
import 'package:kabelwerk/src/kabelwerk.dart';

import 'helpers/payloads.dart';
import 'helpers/server.dart';

void main() {
  group('connection', () {
    test('socket connecting → connecting state', () async {
      final run = await runServer([Connect()]);

      final kabelwerk = Kabelwerk();
      kabelwerk.config.url = run.url;
      kabelwerk.config.token = run.token;

      expect(kabelwerk.state, equals(ConnectionState.inactive));

      kabelwerk.connect();
      expect(kabelwerk.state, equals(ConnectionState.connecting));
    });

    test('socket connection rejected → connecting state', () async {
      final run = await runServer([Connect(accept: false)]);

      final kabelwerk = Kabelwerk();
      kabelwerk.config.url = run.url;
      kabelwerk.config.token = run.token;

      kabelwerk.connect();

      Future.delayed(
          Duration(milliseconds: 100),
          expectAsync0(() {
            expect(kabelwerk.state, equals(ConnectionState.connecting));
          }, count: 1));
    });

    test('socket connected → connected event, online state', () async {
      final run = await runServer([Connect(accept: true)]);

      final kabelwerk = Kabelwerk();
      kabelwerk.config.url = run.url;
      kabelwerk.config.token = run.token;

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

    test('join ok → ready event, online state', () async {
      final run = await runServer([
        Connect(),
        Join('private', {}, {'id': 1, 'key': 'test', 'name': 'Test'}),
      ]);

      final kabelwerk = Kabelwerk();
      kabelwerk.config.url = run.url;
      kabelwerk.config.token = run.token;

      kabelwerk.on(
          'ready',
          expectAsync1((event) {
            expect(event.runtimeType, equals(KabelwerkReady));

            expect(kabelwerk.state, equals(ConnectionState.online));
          }, count: 1));

      kabelwerk.connect();
    });

    test('socket disconnected → disconnected event, connecting state',
        () async {
      final run = await runServer([
        Connect(),
        Join('private', {}, {'id': 1, 'key': 'test', 'name': 'Test'}),
        Disconnect(),
      ]);

      final kabelwerk = Kabelwerk();
      kabelwerk.config.url = run.url;
      kabelwerk.config.token = run.token;

      kabelwerk.on(
          'disconnected',
          expectAsync1((event) {
            expect(event.runtimeType, equals(Disconnected));

            expect(kabelwerk.state, equals(ConnectionState.connecting));
          }, count: 1));

      kabelwerk.connect();
    });

    test('ready event is emitted once', () async {});

    test('connected event is emitted each time', () async {});

    // test('disconnect → disconnected event, inactive state', () async {
    //   final run = await runServer([Connect()]);

    //   final kabelwerk = Kabelwerk();
    //   kabelwerk.config.url = run.url;
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

  group('user info', () {});

  group('update device', () {});

  group('create room', () {});
}
