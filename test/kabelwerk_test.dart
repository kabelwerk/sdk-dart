import 'package:test/test.dart';

import 'package:kabelwerk/src/events.dart';
import 'package:kabelwerk/src/kabelwerk.dart';

import 'server.dart';

void main() {
  test('connection rejected', () async {
    final run = runServer([Connect(accept: false)]);

    final kabelwerk = Kabelwerk();
    kabelwerk.config(url: run.url);
    kabelwerk.connect();

    await run.done;
  });

  test('connected event', () async {
    final run = runServer([Connect(accept: true)]);

    final kabelwerk = Kabelwerk();
    kabelwerk.config(url: run.url);

    kabelwerk.on(
        'connected',
        expectAsync1((event) {
          expect(event.runtimeType, equals(Connected));
        }, count: 1));

    kabelwerk.connect();
  });

  test('ready event', () async {
    final run = runServer([
      Connect(),
      Join('private', {}, {'id': 1, 'key': 'test', 'name': 'Test'}),
    ]);

    final kabelwerk = Kabelwerk();
    kabelwerk.config(url: run.url);

    kabelwerk.on(
        'ready',
        expectAsync1((event) {
          expect(event.runtimeType, equals(KabelwerkReady));
        }, count: 1));

    kabelwerk.connect();
  });
}
