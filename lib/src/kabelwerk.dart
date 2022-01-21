import 'package:phoenix_wings/phoenix_wings.dart';

class Kabelwerk {
  // config
  String _url = '';
  String _token = '';

  // internal state
  bool _ready = false;
  PhoenixSocket? _socket;

  void _setupSocket() {
    _socket = PhoenixSocket(_url,
        socketOptions: PhoenixSocketOptions(params: {
          'token': _token,
          'agent': 'sdk-dart/0.0.0',
        }))
      ..onOpen(() {
        if (_ready) {
          // emit: reconnected
        } else {
          // emit: connected
        }
      })
      ..onClose((_) {
        // emit: disconnected
      })
      ..onError((_) {
        // emit: error
      });
  }

  void _setupPrivateChannel() {}

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

  void disconnect() {}

  bool isConnected() {
    return _socket?.isConnected ?? false;
  }
}
