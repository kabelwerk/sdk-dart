import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:phoenix_socket/phoenix_socket.dart'
    show
        PhoenixSocket,
        PhoenixSocketOptions,
        PhoenixSocketErrorEvent,
        PhoenixSocketOpenEvent,
        PhoenixSocketCloseEvent;

import './config.dart';
import './connection_state.dart';
import './dispatcher.dart';
import './events.dart';

final _logger = Logger('kabelwerk.connector');

class Connector {
  //
  // public variables
  //

  /// The current connection state.
  ConnectionState state = ConnectionState.inactive;

  /// The phoenix_socket socket.
  late final PhoenixSocket socket;

  //
  // private variables
  //

  final Config _config;
  final Dispatcher _dispatcher;

  String _token = '';
  bool _tokenIsRefreshing = false;

  //
  // constructors
  //

  Connector(this._config, this._dispatcher);

  //
  // private methods
  //

  Future<Map<String, String>> _getParams() async {
    return {
      'token': _token,
      'agent': 'sdk-dart/0.1.0',
    };
  }

  //
  // public methods
  //

  /// Inits the socket and attaches the event listeners.
  void prepareSocket() {
    socket = PhoenixSocket(_config.url,
        socketOptions: PhoenixSocketOptions(dynamicParams: _getParams));

    socket.openStream.listen((PhoenixSocketOpenEvent event) {
      _logger.info('Socket connection opened.');

      state = ConnectionState.online;

      _dispatcher.send('connected', ConnectedEvent(state));
    });

    socket.closeStream.listen((PhoenixSocketCloseEvent event) {
      _logger.info('Socket connection closed.', event);

      if (state != ConnectionState.inactive) {
        state = ConnectionState.connecting;
      }

      _dispatcher.send('disconnected', DisconnectedEvent(state));

      if (state == ConnectionState.connecting &&
          _config.refreshToken != null &&
          _tokenIsRefreshing == false) {
        _tokenIsRefreshing = true;

        _config.refreshToken!(_token).then((String newToken) {
          _logger.info('Auth token refreshed.');

          _token = newToken;
          _tokenIsRefreshing = false;
        }).catchError((error) {
          _logger.severe('Failed to refresh the auth token.', error);

          _tokenIsRefreshing = false;
        });
      }
    });

    socket.errorStream.listen((PhoenixSocketErrorEvent event) {
      _logger.severe('Socket connection error.', event);
      _dispatcher.send('error', ErrorEvent());
    });
  }

  /// Sets the initial auth token and calls socket.connect().
  Future<PhoenixSocket?> connect() {
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
        _logger.info('Auth token obtained.');

        _token = newToken;

        return socket.connect();
      }).catchError((error) {
        _logger.severe('Failed to obtain an auth token.', error);

        state = ConnectionState.inactive;
        _dispatcher.send('error', ErrorEvent());

        return null;
      });
    }

    // if the connector is not configured properly
    throw StateError("Kabelwerk must be configured with either a token "
        "or a refreshToken function in order to connect to the server.");
  }

  void disconnect() {
    state = ConnectionState.inactive;
    socket.close();
  }

  /// Makes an API call to the Kabelwerk server.
  Future<dynamic> callApi(String method, String path, dynamic data) async {
    final client = http.Client();

    final request = http.Request(method, Uri.parse(path));
    request.headers['kabelwerk-token'] = _config.token;

    try {
      final response = await client.send(request);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      } else {
        throw ErrorEvent();
      }
    } finally {
      client.close();
    }
  }
}
