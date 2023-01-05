import 'package:phoenix_wings/phoenix_wings.dart';

import './config.dart';
import './dispatcher.dart';
import './events.dart';

enum ConnectionState {
  inactive,
  connecting,
  online,
}

class Connector {
  final Config _config;
  final Dispatcher _dispatcher;

  Connector(this._config, this._dispatcher);

  ConnectionState state = ConnectionState.inactive;
  late PhoenixSocket socket;

  String _token = '';
  bool _tokenIsRefreshing = false;

  // Init the _socket and attach the event listeners.
  void _setupSocket() {
    socket = PhoenixSocket(_config.url,
        socketOptions: PhoenixSocketOptions(params: {
          'token': _config.token,
          'agent': 'sdk-dart/0.1.0',
        }));

    socket.onOpen(() {
      state = ConnectionState.online;
      _dispatcher.send('connected', Connected());
    });

    socket.onClose((_) {
      if (state != ConnectionState.inactive) {
        state = ConnectionState.connecting;
      }

      _dispatcher.send('disconnected', Disconnected());

      if (state == ConnectionState.connecting &&
          _config.refreshToken != null &&
          _tokenIsRefreshing == false) {
        _tokenIsRefreshing = true;

        _config.refreshToken!(_token).then((String newToken) {
          _token = newToken;
          _tokenIsRefreshing = false;
        }).catchError((error) {
          _tokenIsRefreshing = false;
        });
      }
    });

    socket.onError((_) {
      _dispatcher.send('error', ErrorEvent());
    });
  }

  // set the _token, setup the socket and call socket.connect()
  connect() {
    _token = _config.token;
    _setupSocket();

    // if the connector is configured with a token — use it, regardless of
    // whether it is also configured with a refreshToken function
    if (_token != '') {
      state = ConnectionState.connecting;
      return socket.connect();
    }

    // if the connector is not configured with a token — call refreshToken
    // to obtain the initial token
    if (_config.refreshToken != null) {
      state = ConnectionState.connecting;

      return _config.refreshToken!(_token).then((String newToken) {
        _token = newToken;
        socket.connect();
      }).catchError((error) {
        state = ConnectionState.inactive;
        _dispatcher.send('error', ErrorEvent());
      });
    }

    throw StateError("Kabelwerk must be configured with either a token "
        "or a refreshToken function in order to connect to the server.");
  }

  void disconnect() {
    socket.disconnect();

    state = ConnectionState.inactive;

    // unlike its js counterpart, the phoenix_wings socket does not invoke its
    // onClose callbacks after .disconnect()
    _dispatcher.send('disconnected', Disconnected());
  }
}
