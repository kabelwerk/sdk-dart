import 'package:test/test.dart';

import 'package:kabelwerk/src/connector.dart';
import 'package:kabelwerk/src/events.dart';
import 'package:kabelwerk/src/kabelwerk.dart';

import 'server.dart';

void main() {
  test('connection rejected', () async {
    final run = await runServer([Connect(accept: false)]);

    final kabelwerk = Kabelwerk();
    kabelwerk.config.url = run.url;
    kabelwerk.config.token = 'token';
    kabelwerk.connect();
  });

  test('connected event', () async {
    final run = await runServer([Connect(accept: true)]);

    final kabelwerk = Kabelwerk();
    kabelwerk.config.url = run.url;
    kabelwerk.config.token = 'token';

    kabelwerk.on(
        'connected',
        expectAsync1((event) {
          expect(event.runtimeType, equals(Connected));

          expect(kabelwerk.state, equals(ConnectionState.online));
        }, count: 1));

    kabelwerk.connect();
  });

  test('ready event', () async {
    final run = await runServer([
      Connect(),
      Join('private', {}, {'id': 1, 'key': 'test', 'name': 'Test'}),
    ]);

    final kabelwerk = Kabelwerk();
    kabelwerk.config.url = run.url;
    kabelwerk.config.token = 'token';

    kabelwerk.on(
        'ready',
        expectAsync1((event) {
          expect(event.runtimeType, equals(KabelwerkReady));

          expect(kabelwerk.state, equals(ConnectionState.online));
        }, count: 1));

    kabelwerk.connect();
  });
}
