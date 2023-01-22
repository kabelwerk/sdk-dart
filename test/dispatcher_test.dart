import 'package:test/test.dart';

import 'package:kabelwerk/src/dispatcher.dart';

void main() {
  test('unknown event → error', () {
    final dispatcher = Dispatcher(['event']);

    expect(() => dispatcher.on('unknown', () {}), throwsArgumentError);

    expect(() => dispatcher.once('unknown', () {}), throwsArgumentError);

    expect(() => dispatcher.off('unknown'), throwsArgumentError);

    expect(() => dispatcher.send('unknown', 42), throwsArgumentError);
  });

  test('send → on', () {
    final dispatcher = Dispatcher(['answer']);

    var counter = 0;

    dispatcher.on('answer', (value) {
      expect(value, equals(42));
      counter++;
    });

    dispatcher.send('answer', 42);

    expect(counter, equals(1));
  });

  test('send → once', () {
    final dispatcher = Dispatcher(['answer']);

    var counter = 0;

    dispatcher.once('answer', (value) {
      expect(value, equals(42));
      counter++;
    });

    dispatcher.send('answer', 42); // 1 call
    dispatcher.send('answer', 42); // 0 calls

    expect(counter, equals(1));
  });

  test('off without a ref', () {
    final dispatcher = Dispatcher(['answer']);

    var counter = 0;

    dispatcher.on('answer', (_) => counter++);

    dispatcher.send('answer', 42); // 1 call
    dispatcher.off('answer');
    dispatcher.send('answer', 42); // 0 calls

    expect(counter, equals(1));
  });

  test('off with a ref', () {
    final dispatcher = Dispatcher(['answer']);

    var counter = 0;

    dispatcher.on('answer', (_) => counter++);

    final reference = dispatcher.on('answer', (_) => counter++);

    dispatcher.send('answer', 42); // 2 calls
    dispatcher.off('answer', reference);
    dispatcher.send('answer', 42); // 1 call

    expect(counter, equals(3));
  });

  test('off without an event', () {
    final dispatcher = Dispatcher(['answer']);

    var counter = 0;

    dispatcher.on('answer', (_) => counter++);

    dispatcher.send('answer', 42); // 1 call
    dispatcher.off();
    dispatcher.send('answer', 42); // 0 calls

    expect(counter, equals(1));
  });
}
