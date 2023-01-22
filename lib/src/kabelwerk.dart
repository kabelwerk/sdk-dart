import 'dart:async';

import 'package:phoenix_socket/phoenix_socket.dart';

import './config.dart';
import './connection_state.dart';
import './connector.dart';
import './dispatcher.dart';
import './events.dart';
// import './inbox.dart';
import './models.dart';
// import './room.dart';
import './utils.dart';

/// A Kabelwerk instance opens and maintains a websocket connection to the
/// Kabelwerk backend; it is also used for retrieving and updating the
/// connected user's info, opening inboxes, and creating and opening rooms.
class Kabelwerk {
  /// The current configuration.
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

  /// The connected user.
  get user => _user;

  void _setupPrivateChannel() {
    _privateChannel = _connector!.socket.addChannel(topic: 'private');

    _privateChannel!.messages.listen((message) {
      if (message.event.value == 'user_updated') {
        final user = User.fromPayload(message.payload!);
        _user = user;
        _dispatcher.send('user_updated', UserUpdated(user));
      }
    });

    _dispatcher.on('connected', (_event) {
      _privateChannel!.join()
        ..onReply('ok', (PushResponse response) {
          final user = User.fromPayload(response.response);

          if (_user != null) {
            _dispatcher.send('user_updated', UserUpdated(user));
          }

          _user = user;

          if (_ready == false) {
            _ready = true;
            _dispatcher.send('ready', KabelwerkReady());
          }
        })
        ..onReply('error', (error) {
          _dispatcher.send('error', ErrorEvent());
        })
        ..onReply('timeout', (error) {
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
  ///
  /// Returns a [Future] which resolves when the first connection attempt is
  /// carried out. However, note that connection may not always succeed on the
  /// first attempt — for state changes, do rely on the events instead.
  Future<PhoenixSocket?> connect() {
    if (_connector != null) {
      throw StateError('Kabelwerk is already ${_connector!.state}.');
    }

    _connector = Connector(config, _dispatcher);
    _connector!.prepareSocket();

    _setupPrivateChannel();

    return _connector!.connect();
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
  /// can be then used to remove that event listener with [Kabelwerk.off].
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

  /// Set and/or update push notifications settings for the currently connected
  /// device.
  ///
  /// If you do not want to have push notifications, you can safely ignore this
  /// method — in which case also no information about the currently connected
  /// device will be stored in the Kabelwerk database.
  Future<Device> updateDevice(
      {required String pushNotificationsToken,
      required bool pushNotificationsEnabled}) {
    _ensureReady();

    final Completer<Device> completer = Completer();

    _privateChannel!.push('update_device', {
      'push_notifications_token': pushNotificationsToken,
      'push_notifications_enabled': pushNotificationsEnabled
    })
      ..onReply('ok', (PushResponse response) {
        final device = Device.fromPayload(response.response);
        completer.complete(device);
      })
      ..onReply('error', (error) {
        completer.completeError(ErrorEvent());
      })
      ..onReply('timeout', (error) {
        completer.completeError(ErrorEvent());
      });

    return completer.future;
  }

  /// Updates the connected user's name.
  Future<User> updateUser({required String name}) {
    _ensureReady();

    final Completer<User> completer = Completer();

    _privateChannel!.push('update_user', {'name': name})
      ..onReply('ok', (PushResponse response) {
        final user = User.fromPayload(response.response);
        _user = user;
        completer.complete(user);
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
