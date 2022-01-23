import 'dart:async';

import 'package:phoenix_wings/phoenix_wings.dart';

import './dispatcher.dart';
import './events.dart';
import './payloads.dart';

/// A room is where chat messages are exchanged between an end user on one side
/// and your care team (hub users) on the other side.
class Room {
  final User _user;

  final Dispatcher _dispatcher = Dispatcher([
    'error',
    'ready',
    'marked_moved',
    'message_posted',
  ]);

  final int _roomId;
  User? _roomUser;
  Map? _roomAttributes;

  int _firstMessageId = -1;
  int _lastMessageId = -1;
  bool _ready = false;

  final PhoenixSocket _socket;
  PhoenixChannel? _channel;

  Room(this._socket, this._user, this._roomId);

  void _updateFirstLastIds(List<Message> messages) {
    if (messages.isNotEmpty) {
      if (messages.first.id < _firstMessageId || _firstMessageId < 0) {
        _firstMessageId = messages.first.id;
      }

      if (messages.last.id > _lastMessageId) {
        _lastMessageId = messages.last.id;
      }
    }
  }

  void _setupChannel() {
    _channel = _socket.channel('room:${_roomId}');

    _channel?.on('message_posted', (Map? payload, ref, joinRef) {
      if (payload == null) {
        throw Error();
      }

      final message = Message.fromPayload(payload);

      if (message.id > _lastMessageId) {
        _lastMessageId = message.id;
      }

      _dispatcher.send('message_posted', MessagePosted(message));
    });

    var push = _channel?.join();

    push?.receive('ok', (Map? payload) {
      if (payload == null) {
        throw Error();
      }

      final roomJoin = RoomJoin.fromPayload(payload);
      _roomUser = roomJoin.user;
      _roomAttributes = roomJoin.attributes;
      _updateFirstLastIds(roomJoin.messages);

      if (_ready) {
        for (final message in roomJoin.messages) {
          _dispatcher.send('message_posted', MessagePosted(message));
        }
      } else {
        _ready = true;

        _dispatcher.send('ready', RoomReady(roomJoin.messages));
      }
    });

    push?.receive('error', (error) {
      _dispatcher.send('error', ErrorEvent());
    });

    push?.receive('timeout', (error) {
      _dispatcher.send('error', ErrorEvent());
    });
  }

  /// Establishes connection to the server.
  ///
  /// Usually all event listeners should be already attached when this method
  /// is invoked.
  void connect() {
    if (_channel != null) {
      throw Error();
    }

    _setupChannel();
  }

  /// Removes all previously attached event listeners and closes the connection
  /// to the server.
  void disconnect() {
    _dispatcher.off();

    _channel?.leave();
    _channel = null;

    _firstMessageId = -1;
    _lastMessageId = -1;
    _ready = false;
  }

  /// Removes one or more previously attached event listeners.
  ///
  /// Both parameters are optional: if no [reference] is given, all listeners
  /// for the given event are removed; if no [event] is given, then all event
  /// listeners attached to the instance are removed.
  void off([String? event, String? reference]) =>
      _dispatcher.off(event, reference);

  /// Attaches an event listener.
  ///
  /// Returns a short string identifying the attached listener — which string
  /// can be then used to remove that event listener with [Room.off()].
  String on(String event, Function function) => _dispatcher.on(event, function);

  /// Posts a new message in the chat room.
  Future<dynamic> postMessage({required String text}) {
    final completer = Completer();
    final push = _channel?.push(event: 'post_message', payload: {'text': text});

    push?.receive('ok', (Map? payload) {
      if (payload == null) {
        throw Error();
      }

      final message = Message.fromPayload(payload);

      if (message.id > _lastMessageId) {
        _lastMessageId = message.id;
      }

      completer.complete(message);
    });

    push?.receive('error', (error) {
      completer.completeError(ErrorEvent());
    });

    push?.receive('timeout', (error) {
      completer.completeError(ErrorEvent());
    });

    return completer.future;
  }
}
