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

  //
  // getters
  //

  /// The current connection state.
  get state =>
      (_connector != null) ? _connector!.state : ConnectionState.inactive;

  /// The connected user.
  get user {
    _ensureReady();
    return _user;
  }

  //
  // private methods
  //

  void _setupPrivateChannel() {
    _privateChannel = _connector!.socket.addChannel(topic: 'private');

    _privateChannel!.messages.listen((message) {
      if (message.event.value == 'user_updated') {
        final user = User.fromPayload(message.payload!);
        _user = user;
        _dispatcher.send('user_updated', UserUpdated(user));
      }
    });

    _dispatcher.once('connected', (_event) {
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
  /// Returns a [Future] resolving into the ID of the newly created room.
  Future<int> createRoom(int hubId) {
    _ensureReady();

    final Completer<int> completer = Completer();

    _privateChannel!.push('create_room', {'hub': hubId})
      ..onReply('ok', (PushResponse response) {
        final int roomId = response.response['id'];
        completer.complete(roomId);
      })
      ..onReply('error', (error) {
        completer.completeError(ErrorEvent());
      })
      ..onReply('timeout', (error) {
        completer.completeError(ErrorEvent());
      });

    return completer.future;
  }

  /// Closes the connection to the server.
  void disconnect() {
    _privateChannel?.leave();
    _privateChannel = null;

    _connector?.disconnect();
    _connector = null;

    _user = null;
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
  /// can be then used to remove that event listener with [off].
  String on(String event, Function function) => _dispatcher.on(event, function);

  /// Attaches a one-time event listener.
  ///
  /// This method does the same as [on] except that the event listener will be
  /// automatically removed after being invoked — i.e. the listener is invoked
  /// at most once.
  String once(String event, Function function) =>
      _dispatcher.once(event, function);

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

  /// Sets and/or updates the push notifications settings for the currently
  /// connected device.
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
