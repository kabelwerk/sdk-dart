import 'package:flutter/material.dart' hide ConnectionState;
import 'package:kabelwerk/kabelwerk.dart';

class KabelwerkContext extends ChangeNotifier {
  static const webSocketUrl =
      'wss://hubdemo.kabelwerk.io/socket/user/websocket';

  ConnectionState state = ConnectionState.inactive;

  String _token = '';
  late Kabelwerk _kabelwerk;

  void update({required String token}) {
    if (_token != token) {
      _token = token;

      if (_token == '') {
        _disconnect();
      } else {
        _connect();
      }
    }
  }

  void _connect() {
    _kabelwerk = Kabelwerk();

    _kabelwerk.config
      ..url = webSocketUrl
      ..token = _token;

    _kabelwerk.on('connected', (ConnectedEvent event) {
      state = event.connectionState;
      notifyListeners();
    });

    _kabelwerk.on('disconnected', (DisconnectedEvent event) {
      state = event.connectionState;
      notifyListeners();
    });

    _kabelwerk.on('ready', (KabelwerkReadyEvent event) {
      print('ready!');
    });

    _kabelwerk.on('error', (ErrorEvent event) {
      print('error!');
    });

    _kabelwerk.connect();
  }

  void _disconnect() {
    _kabelwerk.disconnect();
  }
}
