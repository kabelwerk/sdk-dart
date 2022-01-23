import 'package:phoenix_wings/phoenix_wings.dart';

import './dispatcher.dart';
import './events.dart';
import './inbox.dart';
import './payloads.dart';

/// A Kabelwerk instance opens and maintains a websocket connection to the
/// Kabelwerk backend; it is also used for retrieving and updating the
/// connected user's info, opening inboxes, and creating and opening rooms.
class Kabelwerk {
  // config
  String _url = '';
  String _token = '';

  // dispatcher
  Dispatcher _dispatcher = Dispatcher([
    'error',
    'ready',
    'connected',
    'disconnected',
    'reconnected',
    'user_updated',
  ]);

  // internal state
  bool _ready = false;
  User? _user;

  // phoenix
  PhoenixSocket? _socket;
  PhoenixChannel? _privateChannel;

  void _setupSocket() {
    _socket = PhoenixSocket(_url,
        socketOptions: PhoenixSocketOptions(params: {
          'token': _token,
          'agent': 'sdk-dart/0.0.0',
        }))
      ..onOpen(() {
        if (_ready) {
          _dispatcher.send('reconnected', Reconnected());
        } else {
          _dispatcher.send('connected', Connected());
        }
      })
      ..onClose((_) {
        _dispatcher.send('disconnected', Disconnected());
      })
      ..onError((_) {
        _dispatcher.send('error', ErrorEvent());
      });
  }

  void _setupPrivateChannel() {
    _privateChannel = _socket?.channel('private');

    _privateChannel?.on('user_updated', (payload, _ref, _joinRef) {});

    _dispatcher.on('connected', (_event) {
      var push = _privateChannel?.join();

      push?.receive('ok', (Map? payload) {
        if (payload == null) throw Error();

        var user = User.fromPayload(payload);

        if (_user != null) {
          _dispatcher.send('user_updated', UserUpdated(user));
        }

        _user = user;

        if (!_ready) {
          _ready = true;
          _dispatcher.send('ready', KabelwerkReady());
        }
      });

      push?.receive('error', (error) {
        _dispatcher.send('error', ErrorEvent());
      });

      push?.receive('timeout', (error) {
        _dispatcher.send('error', ErrorEvent());
      });
    });
  }

  /// Sets the configuration.
  ///
  /// - [url] → the URL of the Kabelwerk backend to connect to;
  /// - [token] → a JWT token identifying the user on behalf of whom the
  /// connection is established.
  ///
  /// The method can be called mutliple times — only the specified values are
  /// updated.
  void config({String? url, String? token}) {
    if (url != null) {
      _url = url;
    }

    if (token != null) {
      _token = token;
    }
  }

  /// Establishes connection to the server.
  ///
  /// Usually all event listeners should be already attached when this method
  /// is invoked.
  void connect() {
    if (_socket != null) {
      throw Error();
    }

    _setupSocket();
    _setupPrivateChannel();

    _socket?.connect();
  }

  /// Removes all previously attached event listeners and closes the connection
  /// to the server.
  void disconnect() {
    _dispatcher.off();

    _privateChannel?.leave();
    _privateChannel = null;

    _socket?.disconnect();
    _socket = null;

    _user = null;
    _ready = false;
  }

  /// Returns a boolean indicating whether the instance is currently connected
  /// to the server.
  bool isConnected() {
    return _socket?.isConnected ?? false;
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
  Inbox openInbox() {
    var socket = _socket;
    var user = _user;

    if (socket == null || user == null) {
      throw Error();
    }

    return Inbox(socket, user);
  }
}
