import 'package:phoenix_wings/phoenix_wings.dart';

import './dispatcher.dart';
import './events.dart';
import './inbox.dart';
import './payloads.dart';

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

  void config({String? url, String? token}) {
    if (url != null) {
      _url = url;
    }

    if (token != null) {
      _token = token;
    }
  }

  void connect() {
    if (_socket != null) {
      throw Error();
    }

    _setupSocket();
    _setupPrivateChannel();

    _socket?.connect();
  }

  void disconnect() {
    _dispatcher.off();

    _privateChannel?.leave();
    _privateChannel = null;

    _socket?.disconnect();
    _socket = null;

    _user = null;
    _ready = false;
  }

  bool isConnected() {
    return _socket?.isConnected ?? false;
  }

  void off([String? event, String? reference]) =>
      _dispatcher.off(event, reference);

  String on(String event, Function function) => _dispatcher.on(event, function);

  Inbox openInbox() {
    var socket = _socket;
    var user = _user;

    if (socket == null || user == null) {
      throw Error();
    }

    return Inbox(socket, user);
  }
}
