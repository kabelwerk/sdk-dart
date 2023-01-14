import 'dart:async';

import 'package:phoenix_socket/phoenix_socket.dart';

import './config.dart';
import './connection_state.dart';
import './connector.dart';
import './dispatcher.dart';
import './events.dart';
// import './inbox.dart';
import './payloads.dart';
// import './room.dart';
import './utils.dart';

/// A Kabelwerk instance opens and maintains a websocket connection to the
/// Kabelwerk backend; it is also used for retrieving and updating the
/// connected user's info, opening inboxes, and creating and opening rooms.
class Kabelwerk {
  final config = Config();

  final _dispatcher = Dispatcher([
    'error',
    'ready',
    'connected',
    'disconnected',
    'user_updated',
  ]);

  Connector? _connector;
  PhoenixChannel? _privateChannel;

  User? _user;
  bool _ready = false;

  /// The current connection state.
  ConnectionState get state =>
      (_connector != null) ? _connector!.state : ConnectionState.inactive;

  void _setupPrivateChannel() {
    _privateChannel = _connector!.socket.addChannel(topic: 'private');

    // _privateChannel?.on('user_updated', (payload, _ref, _joinRef) {});

    _dispatcher.on('connected', (_event) {
      var push = _privateChannel?.join();

      push?.onReply('ok', (PushResponse response) {
        var user = User.fromPayload(throwIfNull(response.response));

        if (_user != null) {
          _dispatcher.send('user_updated', UserUpdated(user));
        }

        _user = user;

        if (!_ready) {
          _ready = true;
          _dispatcher.send('ready', KabelwerkReady());
        }
      });

      push?.onReply('error', (error) {
        _dispatcher.send('error', ErrorEvent());
      });

      push?.onReply('timeout', (error) {
        _dispatcher.send('error', ErrorEvent());
      });
    });
  }

  void _ensureReady() {
    if (!_ready) {
      throw StateError('This Kabelwerk instance is not ready yet.');
    }
  }

  /// Establishes connection to the server.
  ///
  /// Usually all event listeners should be already attached when this method
  /// is invoked.
  void connect() {
    if (_connector != null) {
      throw StateError('Kabelwerk is already ${_connector!.state}.');
    }

    _connector = Connector(config, _dispatcher);
    _connector!.setupSocket();

    _setupPrivateChannel();

    _connector!.connect();
  }

  /// Creates a chat room between the connected user and a hub.
  ///
  /// Returns a Future resolving into the ID of the newly created room.
  Future<dynamic> createRoom(int hubId) {
    _ensureReady();

    final privateChannel = throwIfNull(_privateChannel);
    final completer = Completer();

    privateChannel.push(event: 'create_room', payload: {'hub': hubId})
      ..receive('ok', (Map? payload) {
        final int roomId = throwIfNull(payload)['id'];
        completer.complete(roomId);
      })
      ..receive('error', (error) {
        completer.completeError(ErrorEvent());
      })
      ..receive('timeout', (error) {
        completer.completeError(ErrorEvent());
      });

    return completer.future;
  }

  /// Removes all previously attached event listeners and closes the connection
  /// to the server.
  void disconnect() {
    _dispatcher.off();

    _privateChannel?.leave();
    _privateChannel = null;

    _connector?.disconnect();
    _connector = null;

    _user = null;
    _ready = false;
  }

  /// Returns the connected user's info.
  User getUser() {
    _ensureReady();
    return throwIfNull(_user);
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
  /// can be then used to remove that event listener with [Kabelwerk.off()].
  String on(String event, Function function) => _dispatcher.on(event, function);

  /// Initialises and returns an [Inbox] instance.
  // Inbox openInbox() {
  //   _ensureReady();

  //   final socket = throwIfNull(_connector);
  //   final user = throwIfNull(_user);

  //   return Inbox(socket, user);
  // }

  /// Initialises and returns a [Room] instance for the chat room with the
  /// given ID.
  // Room openRoom(int roomId) {
  //   _ensureReady();

  //   final socket = throwIfNull(_connector);
  //   final user = throwIfNull(_user);

  //   return Room(socket, user, roomId);
  // }

  /// Updates the connected user's info.
  Future<dynamic> updateUser({required String name}) {
    _ensureReady();

    final privateChannel = throwIfNull(_privateChannel);
    final completer = Completer();

    privateChannel.push(event: 'update_user', payload: {'name': name})
      ..receive('ok', (Map? payload) {
        final user = User.fromPayload(throwIfNull(payload));
        _user = user;
        completer.complete(user);
      })
      ..receive('error', (error) {
        completer.completeError(ErrorEvent());
      })
      ..receive('timeout', (error) {
        completer.completeError(ErrorEvent());
      });

    return completer.future;
  }
}
