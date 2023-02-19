import 'dart:async';

import 'package:kabelwerk/src/config.dart';
import 'package:kabelwerk/src/connector.dart';
import 'package:kabelwerk/src/dispatcher.dart';
import 'package:kabelwerk/src/events.dart';

const serverUrl = 'ws://localhost:4000/socket/user/websocket';

Future<Connector> setUpConnector(
    {String token = 'valid-token',
    Future<String> Function(String)? refreshToken}) {
  final Completer<Connector> completer = Completer();

  final config = Config();
  config.url = serverUrl;
  config.token = token;
  if (refreshToken != null) config.refreshToken = refreshToken;

  final dispatcher = Dispatcher(['error', 'connected', 'disconnected']);
  final connector = Connector(config, dispatcher);

  dispatcher.once('connected', (ConnectedEvent event) {
    completer.complete(connector);
  });

  connector.prepareSocket();
  connector.connect();

  return completer.future;
}
