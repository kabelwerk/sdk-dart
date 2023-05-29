import 'dart:async';

import 'package:kabelwerk/src/config.dart';
import 'package:kabelwerk/src/connector.dart';
import 'package:kabelwerk/src/dispatcher.dart';
import 'package:kabelwerk/src/events.dart';
import 'package:kabelwerk/src/kabelwerk.dart';
import 'package:kabelwerk/src/room.dart';

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

Future<Kabelwerk> setUpKabelwerk({List<String>? ensureRoomsOn}) {
  final Completer<Kabelwerk> completer = Completer();
  final kabelwerk = Kabelwerk();

  kabelwerk.config.url = serverUrl;
  kabelwerk.config.token = 'valid-token';

  if (ensureRoomsOn != null) {
    kabelwerk.config.ensureRoomsOn = ensureRoomsOn;
  }

  kabelwerk.once('ready', (KabelwerkReadyEvent event) {
    completer.complete(kabelwerk);
  });

  kabelwerk.connect();

  return completer.future;
}

Future<Room> setUpRoom(Connector connector, {int roomId = 0}) {
  final Completer<Room> completer = Completer();

  final room = Room(connector, roomId);

  room.on('ready', (RoomReadyEvent event) {
    completer.complete(room);
  });

  room.connect();

  return completer.future;
}
