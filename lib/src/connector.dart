import 'dart:async';
import 'dart:convert' show json;

import 'package:cross_file/cross_file.dart' show XFile;
import 'package:http/http.dart'
    show Request, MultipartRequest, MultipartFile, Response, StreamedResponse;
import 'package:http_parser/http_parser.dart' show MediaType;
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

const _userAgent = 'sdk-dart/0.2.1';

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

  bool _connectHasBeenCalled = false;

  //
  // constructors
  //

  Connector(this._config, this._dispatcher);

  //
  // private methods
  //

  Future<Map<String, String>> _getSocketParams() async {
    return {
      'token': _token,
      'agent': _userAgent,
    };
  }

  // run socket.connect() in a zone
  Future<ConnectionState> _connectSocket() {
    final Completer<ConnectionState> completer = Completer();

    runZoned(() {
      return socket.connect();
    }, onError: (error, stackTrace) {
      _logger.severe(
          'The Zone in which PhoenixSocket.connect is run caught an unhandled exception.',
          error,
          stackTrace);
    }).then((PhoenixSocket? phoenixSocket) {
      completer.complete(state);
    }).catchError((error, stackTrace) {
      _logger.severe(
          'The Future returned by PhoenixSocket.connect failed to resolve.',
          error,
          stackTrace);

      completer.complete(state);
    });

    return completer.future;
  }

  Future<StreamedResponse> _sendApiRequest(
      String method, String path, XFile? file, String token) async {
    final uri = Uri.parse(_config.getApiUrl() + path);

    final request =
        file == null ? Request(method, uri) : MultipartRequest(method, uri);

    request.headers['kabelwerk-token'] = token;
    request.headers['user-agent'] = _userAgent;

    if (file != null) {
      final multipartRequest = request as MultipartRequest;

      if (file.mimeType == null) {
        throw StateError('File uploads must have their MIME type set.');
      }

      // both the filename and contentType must be set
      final multipartFile = MultipartFile.fromBytes(
          'file', await file.readAsBytes(),
          filename: file.name.isNotEmpty ? file.name : 'file',
          contentType: MediaType.parse(file.mimeType!));

      multipartRequest.files.add(multipartFile);
    }

    _logger.fine('Sending a request $method $uri.');

    return request.send();
  }

  //
  // public methods
  //

  /// Inits the socket and attaches the event listeners.
  void prepareSocket() {
    socket = PhoenixSocket(_config.getSocketUrl(),
        socketOptions: PhoenixSocketOptions(dynamicParams: _getSocketParams));

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

          _dispatcher.send('error', ErrorEvent());
        });
      }
    });

    socket.errorStream.listen((PhoenixSocketErrorEvent event) {
      _logger.severe('Socket connection error.', event);
      _dispatcher.send('error', ErrorEvent());
    });
  }

  /// Sets the initial auth token and calls socket.connect().
  Future<ConnectionState> connect() {
    if (_connectHasBeenCalled != false) {
      throw StateError(
          "This Connector instance's .connect() method has already been called once.");
    }

    _connectHasBeenCalled = true;
    _token = _config.token;

    // if the connector is configured with a token — use it, regardless of
    // whether it is also configured with a refreshToken function
    if (_token != '') {
      state = ConnectionState.connecting;

      return _connectSocket();
    }

    // if the connector is not configured with a token — call refreshToken
    // to obtain the initial token
    if (_config.refreshToken != null) {
      state = ConnectionState.connecting;

      return _config.refreshToken!(_token).then((String newToken) {
        _logger.info('Auth token obtained.');

        _token = newToken;

        return _connectSocket();
      }).catchError((error) {
        _logger.severe('Failed to obtain an auth token.', error);

        state = ConnectionState.inactive;
        _dispatcher.send('error', ErrorEvent());

        return Future.value(state);
      });
    }

    // if the connector is not configured properly
    throw StateError("Kabelwerk must be configured with either a token "
        "or a refreshToken function in order to connect to the server.");
  }

  /// Closes the connection to the server.
  void disconnect() {
    state = ConnectionState.inactive;

    if (_connectHasBeenCalled == true) {
      socket.close();
    }
  }

  /// Makes an API call to the Kabelwerk server.
  ///
  /// Note that this method can be used only after [connect] has been called,
  /// otherwise the _token would not be set.
  Future<Map<String, dynamic>> callApi(String method, String path,
      {XFile? file}) async {
    if (_connectHasBeenCalled != true) {
      throw StateError(
          "This Connector instance's connect() method has not been called yet.");
    }

    StreamedResponse response =
        await _sendApiRequest(method, path, file, _token);

    // if the request is rejected with 401, assume that the token has expired,
    // refresh it, and try again
    if (response.statusCode == 401 &&
        _config.refreshToken != null &&
        _tokenIsRefreshing == false) {
      final String newToken = await _config.refreshToken!(_token);

      // use the opportunity to update _token — unless there already is another
      // refresh under way
      if (_tokenIsRefreshing == false) {
        _logger.info('Auth token refreshed.');
        _token = newToken;
      }

      // this call here is the reason why the method needs the fourth parameter
      response = await _sendApiRequest(method, path, file, newToken);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final fullResponse = await Response.fromStream(response);
      final Map<String, dynamic> payload = {};

      if (fullResponse.body.isNotEmpty) {
        payload.addAll(json.decode(fullResponse.body));
      }

      return payload;
    } else {
      throw ErrorEvent();
    }
  }
}
