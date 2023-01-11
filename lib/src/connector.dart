import 'package:phoenix_socket/phoenix_socket.dart';

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

  Future<Map<String, String>> _fetchParams() async {
    return {
      'token': _token,
      'agent': 'sdk-dart/0.1.0',
    };
  }

  // Inits the socket and attaches the event listeners.
  void setupSocket() {
    socket = PhoenixSocket(_config.url,
        socketOptions: PhoenixSocketOptions(dynamicParams: _fetchParams));

    socket.openStream.listen((PhoenixSocketOpenEvent event) {
      state = ConnectionState.online;
      _dispatcher.send('connected', Connected());
    });

    socket.closeStream.listen((PhoenixSocketCloseEvent event) {
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

    socket.errorStream.listen((PhoenixSocketErrorEvent event) {
      _dispatcher.send('error', ErrorEvent());
    });
  }

  // Sets the initial _token and calls socket.connect().
  connect() {
    _token = _config.token;

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
    state = ConnectionState.inactive;
    socket.close();
  }
}
