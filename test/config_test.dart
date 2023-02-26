import 'package:test/test.dart';

import 'package:kabelwerk/src/config.dart';

void main() {
  group('urls', () {
    late Config config;

    setUp(() {
      config = Config();
    });

    test('bad urls', () {
      for (final badUrl in [
        '',
        'not a url',
        'http://example.com',
        'https://kabelwerk.io'
      ]) {
        config.url = badUrl;
        expect(() => config.getSocketUrl(), throwsStateError);
        expect(() => config.getApiUrl(), throwsStateError);
      }
    });

    test('good urls', () {
      config.url = 'kabelwerk.io';
      expect(config.getSocketUrl(),
          equals('wss://kabelwerk.io/socket/user/websocket'));
      expect(config.getApiUrl(), equals('https://kabelwerk.io/api'));

      config.url = 'ws://kabelwerk.io';
      expect(config.getSocketUrl(),
          equals('ws://kabelwerk.io/socket/user/websocket'));
      expect(config.getApiUrl(), equals('http://kabelwerk.io/api'));

      config.url = 'wss://kabelwerk.io/';
      expect(config.getSocketUrl(),
          equals('wss://kabelwerk.io/socket/user/websocket'));
      expect(config.getApiUrl(), equals('https://kabelwerk.io/api'));

      config.url = 'kabelwerk.io/socket/hub';
      expect(config.getSocketUrl(), equals('wss://kabelwerk.io/socket/hub'));
      expect(config.getApiUrl(), equals('https://kabelwerk.io/api'));
    });
  });
}
