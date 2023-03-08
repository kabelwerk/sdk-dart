import 'dart:async';

import 'package:cross_file/cross_file.dart' show XFile;
import 'package:logging/logging.dart';
import 'package:phoenix_socket/phoenix_socket.dart'
    show PhoenixChannel, PushResponse;
import 'package:phoenix_socket/phoenix_socket.dart' as phoenix show Message;

import './connector.dart';
import './dispatcher.dart';
import './events.dart';
import './models.dart';

final _logger = Logger('kabelwerk.room');

/// A room is where chat messages are exchanged between an end user on one side
/// and your care team (hub users) on the other side.
///
///
/// ## List of events
///
/// - **`error`** → Fired when there is a problem establishing connection to
/// the server. The attached event listeners are called with an [ErrorEvent]
/// instance.
/// - **`ready`** → Fired at most once, when the connection to the server is
/// first established. The attached event listeners are called with a
/// [RoomReadyEvent] instance.
/// - **`message_posted`** → Fired when there is a new message posted in the
/// room (by any user). The attached event listeners are called with a
/// [MessagePostedEvent] instance.
/// - **`message_deleted`** → Fired when a message is deleted from the room (by
/// any user). The attached event listeners are called with a
/// [MessageDeletedEvent] instance.
/// - **`marker_moved`** → Fired when a marker in the room is updated or
/// created (by any user). The attached event listeners are called with a
/// [MarkerMovedEvent] instance.
class Room {
  //
  // private variables
  //

  final Connector _connector;
  final int _roomId;

  final Dispatcher _dispatcher = Dispatcher([
    'error',
    'ready',
    'message_posted',
    'message_deleted',
    'marker_moved',
  ]);

  final Map<String, int> _channelJoinParameters = {};

  late PhoenixChannel _channel;
  bool _connectHasBeenCalled = false;
  bool _ready = false;

  final Map<String, dynamic> _attributes = {};
  late User _user;

  int _firstMessageId = -1;
  int _lastMessageId = -1;

  late Marker? _ownMarker;
  late Marker? _theirMarker;

  //
  // constructors
  //

  /// Do not create instances directly — use [Kabelwerk.openRoom] instead.
  Room(this._connector, this._roomId);

  //
  // getters
  //

  /// The room's custom attributes.
  Map<String, dynamic> get attributes {
    _ensureReady();
    return _attributes;
  }

  /// The connected user's marker — or null if this does not exist yet.
  Marker? get ownMarker {
    _ensureReady();
    return _ownMarker;
  }

  /// The latest hub-side marker — or null if this does not exist yet.
  Marker? get theirMarker {
    _ensureReady();
    return _theirMarker;
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
        _channelJoinParameters['after'] = _lastMessageId;
      }
    }
  }

  void _handleJoinResponse(Map<String, dynamic> payload) {
    if (payload['status'] == 'ok') {
      _logger.info('Joined the room:$_roomId channel.');

      final roomJoin = RoomJoin.fromPayload(payload['response']);

      _attributes.clear();
      _attributes.addAll(roomJoin.attributes);

      _user = roomJoin.user;

      _updateFirstLastIds(roomJoin.messages);

      if (_ready == false) {
        // initial join

        _ready = true;

        _ownMarker = roomJoin.ownMarker;
        _theirMarker = roomJoin.theirMarker;

        _dispatcher.send(
            'ready',
            RoomReadyEvent(
                roomJoin.messages, roomJoin.ownMarker, roomJoin.theirMarker));
      } else {
        // rejoin

        for (final message in roomJoin.messages) {
          _dispatcher.send('message_posted', MessagePostedEvent(message));
        }

        if (roomJoin.ownMarker != null &&
            (_ownMarker == null ||
                _ownMarker!.messageId < roomJoin.ownMarker!.messageId)) {
          _ownMarker = roomJoin.ownMarker;
          _dispatcher.send(
              'marker_moved', MarkerMovedEvent(roomJoin.ownMarker!));
        }

        if (roomJoin.theirMarker != null &&
            (_theirMarker == null ||
                _theirMarker!.messageId < roomJoin.theirMarker!.messageId)) {
          _theirMarker = roomJoin.theirMarker;
          _dispatcher.send(
              'marker_moved', MarkerMovedEvent(roomJoin.theirMarker!));
        }
      }
    } else {
      _logger.severe('Failed to join the room:$_roomId channel.');
      _dispatcher.send('error', ErrorEvent());
    }
  }

  Future<PushResponse> _setUpChannel() {
    _channel = _connector.socket
        .addChannel(topic: 'room:$_roomId', parameters: _channelJoinParameters);

    _channel.messages.listen((phoenix.Message socketMessage) {
      if (socketMessage.event.value == 'phx_reply' &&
          socketMessage.ref == _channel.joinRef) {
        _handleJoinResponse(socketMessage.payload!);
      }

      if (socketMessage.event.value == 'message_posted') {
        final message = Message.fromPayload(socketMessage.payload!);

        if (message.id > _lastMessageId) {
          _lastMessageId = message.id;
          _channelJoinParameters['after'] = _lastMessageId;
        }

        _dispatcher.send('message_posted', MessagePostedEvent(message));
      }

      if (socketMessage.event.value == 'message_deleted') {
        final message = Message.fromPayload(socketMessage.payload!);

        _dispatcher.send('message_deleted', MessageDeletedEvent(message));
      }

      if (socketMessage.event.value == 'marker_moved') {
        final marker = Marker.fromPayload(socketMessage.payload!);

        if (marker.userId == _user.id) {
          _ownMarker = marker;
          _dispatcher.send('marker_moved', MarkerMovedEvent(marker));
        } else if (_theirMarker == null ||
            _theirMarker!.messageId < marker.messageId) {
          _theirMarker = marker;
          _dispatcher.send('marker_moved', MarkerMovedEvent(marker));
        }
      }
    });

    return _channel.join().future;
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
  ///
  /// Returns a [Future] which resolves when the first connection attempt is
  /// carried out. However, note that connection may not always succeed on the
  /// first attempt — for state changes, do rely on the [RoomReadyEvent] and
  /// the other room events instead.
  Future<PushResponse> connect() {
    if (_connectHasBeenCalled != false) {
      throw StateError(
          "This Room instance's .connect() method was already called once.");
    }

    _connectHasBeenCalled = true;

    return _setUpChannel();
  }

  /// Deletes a message from the room.
  ///
  /// The message must have been posted by the connected user — users can only
  /// delete their own messages.
  ///
  /// Returns a [Future] which resolves into the deleted message.
  Future<Message> deleteMessage(int messageId) {
    _ensureReady();

    final Completer<Message> completer = Completer();

    _channel.push('delete_message', {'message': messageId})
      ..onReply('ok', (PushResponse pushResponse) {
        final message = Message.fromPayload(pushResponse.response);

        completer.complete(message);
      })
      ..onReply('error', (PushResponse error) {
        _logger.severe('Failed to delete the message.', error);
        completer.completeError(ErrorEvent());
      })
      ..onReply('timeout', (PushResponse error) {
        completer.completeError(ErrorEvent());
      });

    return completer.future;
  }

  /// Closes the connection to the server.
  void disconnect() {
    if (_connectHasBeenCalled == true) {
      _channel.leave();
    }
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
      ..onReply('error', (PushResponse error) {
        _logger.severe('Failed to load earlier messages.', error);
        completer.completeError(ErrorEvent());
      })
      ..onReply('timeout', (PushResponse error) {
        completer.completeError(ErrorEvent());
      });

    return completer.future;
  }

  /// Moves the connected user's marker in the room, creating it if it does not
  /// exist yet.
  ///
  /// If provided, the optional parameter should be the ID of the [Message] to
  /// which to move the marker; the default value is the ID of the last message
  /// in the room that the client is aware of. Returns a [Future] which
  /// resolves into the updated [Marker].
  Future<Marker> moveMarker([int? messageId]) {
    _ensureReady();

    if (messageId == null) {
      if (_lastMessageId <= 0) {
        throw StateError(
            'There must be at least one message in the room before moving the marker.');
      }

      messageId = _lastMessageId;
    }

    final Completer<Marker> completer = Completer();

    _channel.push('move_marker', {'message': messageId})
      ..onReply('ok', (PushResponse pushResponse) {
        final marker = Marker.fromPayload(pushResponse.response);

        if (_ownMarker == null || _ownMarker!.messageId < marker.messageId) {
          _ownMarker = marker;
        }

        completer.complete(marker);
      })
      ..onReply('error', (PushResponse error) {
        _logger.severe('Failed to move the room marker.', error);
        completer.completeError(ErrorEvent());
      })
      ..onReply('timeout', (PushResponse error) {
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
          _channelJoinParameters['after'] = _lastMessageId;
        }

        completer.complete(message);
      })
      ..onReply('error', (PushResponse error) {
        _logger.severe('Failed to post the new message.', error);
        completer.completeError(ErrorEvent());
      })
      ..onReply('timeout', (PushResponse error) {
        completer.completeError(ErrorEvent());
      });

    return completer.future;
  }

  /// Uploads a file in the chat room.
  ///
  /// The parameter is expected to be an [XFile] — with its `mimeType` field
  /// set. Returns a [Future] which resolves into the newly created [Upload]
  /// (the ID of which can be then used to post an image or attachment
  /// message).
  Future<Upload> postUpload(XFile file) {
    _ensureReady();

    final Completer<Upload> completer = Completer();

    _connector
        .callApi('POST', '/rooms/$_roomId/uploads', file: file)
        .then((Map<String, dynamic> responsePayload) {
      final upload = Upload.fromPayload(responsePayload);
      completer.complete(upload);
    }).catchError((error) {
      completer.completeError(error);
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
      ..onReply('error', (PushResponse error) {
        _logger.severe("Failed to update the room's attributes.", error);
        completer.completeError(ErrorEvent());
      })
      ..onReply('timeout', (PushResponse error) {
        completer.completeError(ErrorEvent());
      });

    return completer.future;
  }
}
