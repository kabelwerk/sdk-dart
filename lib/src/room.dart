import 'dart:async';

import 'package:phoenix_socket/phoenix_socket.dart' hide Message;

import './connector.dart';
import './dispatcher.dart';
import './events.dart';
import './models.dart';

/// A room is where chat messages are exchanged between an end user on one side
/// and your care team (hub users) on the other side.
class Room {
  final Connector _connector;
  final int _roomId;

  Room(this._connector, this._roomId);

  final Dispatcher _dispatcher = Dispatcher([
    'error',
    'ready',
    'marked_moved',
    'message_posted',
  ]);

  int _firstMessageId = -1;
  int _lastMessageId = -1;

  bool _connectHasBeenCalled = false;
  bool _ready = false;

  late PhoenixChannel _channel;

  final Map<String, dynamic> _attributes = Map();
  late User _user;

  //
  // getters
  //

  /// The room's custom attributes.
  Map<String, dynamic> get attributes {
    _ensureReady();
    return _attributes;
  }

  /// The room's end user.
  User get user {
    _ensureReady();
    return _user;
  }

  //
  // private methods
  //

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
    _channel = _connector.socket.addChannel(topic: 'room:${_roomId}');

    _channel.messages.listen((socketMessage) {
      if (socketMessage.event.value == 'message_posted') {
        final message = Message.fromPayload(socketMessage.payload!);

        if (message.id > _lastMessageId) {
          _lastMessageId = message.id;
        }

        _dispatcher.send('message_posted', MessagePosted(message));
      }
    });

    _channel.join()
      ..onReply('ok', (PushResponse pushResponse) {
        final roomJoin = RoomJoin.fromPayload(pushResponse.response);

        _attributes.clear();
        _attributes.addAll(roomJoin.attributes);

        _user = roomJoin.user;

        _updateFirstLastIds(roomJoin.messages);

        if (_ready) {
          for (final message in roomJoin.messages) {
            _dispatcher.send('message_posted', MessagePosted(message));
          }
        } else {
          _ready = true;
          _dispatcher.send('ready', RoomReady(roomJoin.messages));
        }
      })
      ..onReply('error', (error) {
        _dispatcher.send('error', ErrorEvent());
      })
      ..onReply('timeout', (error) {
        _dispatcher.send('error', ErrorEvent());
      });
  }

  void _ensureReady() {
    if (_ready == false) {
      throw StateError('This Room instance is not ready yet.');
    }
  }

  //
  // public methods
  //

  /// Establishes connection to the server.
  ///
  /// Usually all event listeners should be already attached when this method
  /// is invoked.
  void connect() {
    if (_connectHasBeenCalled != false) {
      throw StateError(
          "This Room instance's .connect() method was already called once.");
    }

    _connectHasBeenCalled = true;
    _setupChannel();
  }

  /// Closes the connection to the server.
  void disconnect() {
    if (_connectHasBeenCalled == true) {
      _channel.leave();
    }

    _attributes.clear();
    _firstMessageId = -1;
    _lastMessageId = -1;
    _ready = false;
  }

  /// Loads more messages from earlier in the chat history.
  ///
  /// A [Room] instance keeps track of the earliest message it has processed,
  /// so this method would usually just work when loading a chat room's
  /// history. Returns a [Future] which resolves into a list of messages.
  Future<List<Message>> loadEarlier() {
    _ensureReady();

    final Completer<List<Message>> completer = Completer();

    _channel.push('list_messages', {'before': _firstMessageId})
      ..onReply('ok', (PushResponse pushResponse) {
        final List<Message> messages = [
          for (final message in pushResponse.response['messages'])
            Message.fromPayload(message)
        ];

        _updateFirstLastIds(messages);

        completer.complete(messages);
      })
      ..onReply('error', (error) {
        completer.completeError(ErrorEvent());
      })
      ..onReply('timeout', (error) {
        completer.completeError(ErrorEvent());
      });

    return completer.future;
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
  /// can be then used to remove that event listener with [off].
  String on(String event, Function function) => _dispatcher.on(event, function);

  /// Attaches a one-time event listener.
  ///
  /// This method does the same as [on] except that the event listener will be
  /// automatically removed after being invoked — i.e. the listener is invoked
  /// at most once.
  String once(String event, Function function) =>
      _dispatcher.once(event, function);

  /// Posts a new message in the chat room.
  ///
  /// Returns a [Future] which resolves into the newly added [Message].
  Future<Message> postMessage({required String text}) {
    _ensureReady();

    final Completer<Message> completer = Completer();

    _channel.push('post_message', {'text': text})
      ..onReply('ok', (PushResponse pushResponse) {
        final message = Message.fromPayload(pushResponse.response);

        if (message.id > _lastMessageId) {
          _lastMessageId = message.id;
        }

        completer.complete(message);
      })
      ..onReply('error', (error) {
        completer.completeError(ErrorEvent());
      })
      ..onReply('timeout', (error) {
        completer.completeError(ErrorEvent());
      });

    return completer.future;
  }

  /// Sets the room's custom attributes.
  ///
  /// Returns a [Future] which resolves into the updated attributes.
  Future<Map> updateAttributes(Map newAttributes) {
    _ensureReady();

    final Completer<Map> completer = Completer();

    _channel.push('set_attributes', {'attributes': newAttributes})
      ..onReply('ok', (PushResponse pushResponse) {
        final attributes = pushResponse.response['attributes'];

        _attributes.clear();
        _attributes.addAll(attributes);

        completer.complete(attributes);
      })
      ..onReply('error', (error) {
        completer.completeError(ErrorEvent());
      })
      ..onReply('timeout', (error) {
        completer.completeError(ErrorEvent());
      });

    return completer.future;
  }
}
