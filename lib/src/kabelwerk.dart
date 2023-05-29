import 'dart:async';

import 'package:phoenix_socket/phoenix_socket.dart'
    show PhoenixChannel, PhoenixSocket, PushResponse;
import 'package:phoenix_socket/phoenix_socket.dart' as phoenix show Message;

import './config.dart';
import './connection_state.dart';
import './connector.dart';
import './dispatcher.dart';
import './events.dart';
import './inbox.dart';
import './models.dart';
import './notifier.dart';
import './room.dart';

/// A Kabelwerk instance opens and maintains a websocket connection to the
/// Kabelwerk backend; it is also used for retrieving and updating the
/// connected user's info, opening inboxes and notifiers, and creating and
/// opening rooms.
///
///
/// ## List of events
///
/// - **`error`** → Fired when there is a problem establishing connection to
/// the server. The attached event listeners are called with an [ErrorEvent]
/// instance.
/// - **`ready`** → Fired when the connection to the server is first
/// established and the Kabelwerk instance is ready to be used. The attached
/// event listeners are called with a [KabelwerkReadyEvent] instance.
/// - **`connected`** → Fired when the connection to the server is established.
/// This could be either because [connect] was invoked, or it could be due to
/// automatically re-establishing the connection after a connection drop.
/// Useful for displaying the connection's status to the user. The attached
/// event listeners are called with a [ConnectedEvent] instance.
/// - **`disconnected`** → Fired when the connection to the server is dropped.
/// Useful for displaying the connection's status to the user. The attached
/// event listeners are called with a [DisconnectedEvent] instance.
/// - **`user_updated`** → Fired when the connected user's name has changed.
/// The attached event listeners are called with an [UserUpdatedEvent]
/// instance.
class Kabelwerk {
  //
  // public variables
  //

  /// The current configuration.
  final config = Config();

  //
  // private variables
  //

  final _dispatcher = Dispatcher([
    'error',
    'ready',
    'connected',
    'disconnected',
    'user_updated',
  ]);

  late final Connector _connector;
  late final PhoenixChannel _channel;

  bool _connectHasBeenCalled = false;
  bool _ready = false;

  late User _user;
  late List<int> _roomIdsAtJoin;

  //
  // constructors
  //

  Kabelwerk() {
    _connector = Connector(config, _dispatcher);
  }

  //
  // getters
  //

  /// The current connection state.
  ConnectionState get state => _connector.state;

  /// The connected user.
  User get user {
    _ensureReady();
    return _user;
  }

  //
  // private methods
  //

  Map<String, dynamic> _getChannelJoinParameters() {
    Map<String, dynamic> parameters = {};

    if (config.ensureRoomsOnAllHubs == true) {
      parameters['ensure_rooms'] = 'all';
    } else if (config.ensureRoomsOn.isNotEmpty) {
      parameters['ensure_rooms'] = config.ensureRoomsOn;
    }

    return parameters;
  }

  void _setUpChannel() {
    _channel = _connector.socket
        .addChannel(topic: 'private', parameters: _getChannelJoinParameters());

    _channel.messages.listen((phoenix.Message message) {
      if (message.event.value == 'phx_reply' &&
          message.ref == _channel.joinRef) {
        _handleJoinResponse(message.payload!);
      }

      if (message.event.value == 'user_updated') {
        final user = User.fromPayload(message.payload!);
        _user = user;
        _dispatcher.send('user_updated', UserUpdatedEvent(user));
      }
    });

    _dispatcher.once('connected', (ConnectedEvent event) {
      _channel.join();
    });
  }

  void _handleJoinResponse(Map<String, dynamic> payload) {
    if (payload['status'] == 'ok') {
      final privateJoin = PrivateJoin.fromPayload(payload['response']);

      _user = privateJoin.user;
      _roomIdsAtJoin = privateJoin.roomIds;

      if (_ready == false) {
        // initial join
        _ready = true;
        _dispatcher.send('ready', KabelwerkReadyEvent(privateJoin.user));
      } else {
        // rejoin
        _dispatcher.send('user_updated', UserUpdatedEvent(privateJoin.user));
      }
    } else {
      _dispatcher.send('error', ErrorEvent());

      // if we cannot (re)join the private channel, terminate the connection
      disconnect();
    }
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
    if (_connectHasBeenCalled != false) {
      throw StateError('Kabelwerk is already ${_connector.state}.');
    }

    _connectHasBeenCalled = true;

    _connector.prepareSocket();
    _setUpChannel();

    return _connector.connect();
  }

  /// Creates a chat room between the connected user and a hub.
  ///
  /// Returns a [Future] resolving into the ID of the newly created room.
  Future<int> createRoom(int hubId) {
    _ensureReady();

    final Completer<int> completer = Completer();

    _channel.push('create_room', {'hub': hubId})
      ..onReply('ok', (PushResponse pushResponse) {
        final int roomId = pushResponse.response['id'];
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
    if (_connectHasBeenCalled == true) {
      _channel.leave();
      _connector.disconnect();
    }
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
  Inbox openInbox() {
    _ensureReady();

    return Inbox(_connector, _user.id);
  }

  /// Initialises and returns a [Notifier] instance.
  Notifier openNotifier() {
    _ensureReady();

    return Notifier(_connector, _user.id);
  }

  /// Initialises and returns a [Room] instance for the chat room with the
  /// given ID.
  ///
  /// Alternatively, the method can be called without a parameter, in which
  /// case one of the rooms belonging to the connected user will be opened —
  /// useful when you have a single hub.
  Room openRoom([int roomId = 0]) {
    _ensureReady();

    if (roomId == 0) {
      if (_roomIdsAtJoin.isNotEmpty) {
        roomId = _roomIdsAtJoin[0];
      } else {
        throw StateError('The user does not have any rooms yet.');
      }
    }

    return Room(_connector, roomId);
  }

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

    _channel.push('update_device', {
      'push_notifications_token': pushNotificationsToken,
      'push_notifications_enabled': pushNotificationsEnabled
    })
      ..onReply('ok', (PushResponse pushResponse) {
        final device = Device.fromPayload(pushResponse.response);
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

    _channel.push('update_user', {'name': name})
      ..onReply('ok', (PushResponse pushResponse) {
        final user = User.fromPayload(pushResponse.response);
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
