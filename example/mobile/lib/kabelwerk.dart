import 'package:flutter/material.dart' hide ConnectionState;
import 'package:kabelwerk/kabelwerk.dart';

/// The socket URL of the Kabelwerk backend to connect to.
const webSocketUrl = 'wss://hubdemo.kabelwerk.io/socket/user/websocket';

class KabelwerkContext extends ChangeNotifier {
  //
  // public variables
  //

  /// The [Kabelwerk] instance.
  Kabelwerk kabelwerk = Kabelwerk();

  //
  // getters
  //

  ConnectionState get state => kabelwerk.state;

  User get user => kabelwerk.user;

  //
  // private methods
  //

  /// Set up the Kabelwerk connection.
  void _connect(String token) {
    kabelwerk = Kabelwerk();

    kabelwerk.config
      ..url = webSocketUrl
      ..token = token
      ..ensureRoomsOnAllHubs = true;

    kabelwerk.on('connected', (ConnectedEvent event) {
      notifyListeners();
    });

    kabelwerk.on('disconnected', (DisconnectedEvent event) {
      notifyListeners();
    });

    kabelwerk.on('ready', (KabelwerkReadyEvent event) {
      notifyListeners();
    });

    kabelwerk.on('error', (ErrorEvent event) {
      notifyListeners();
    });

    kabelwerk.connect();
  }

  /// Tear down the Kabelwerk connection.
  void _disconnect() {
    kabelwerk.disconnect();
  }

  //
  // public methods
  //

  void handleAuthChange({required String token}) {
    if (kabelwerk.config.token != token) {
      if (token == '') {
        _disconnect();
      } else {
        _connect(token);
      }
    }
  }
}
