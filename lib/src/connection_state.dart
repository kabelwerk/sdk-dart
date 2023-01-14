/// The possible states of the websocket connection to the Kabelwerk backend.
///
/// <img src="https://raw.githubusercontent.com/kabelwerk/sdk-js/master/docs/connection-states.jpg" alt="Connection states" width="100%" />
enum ConnectionState {
  /// There is no connection established to the Kabelwerk backend, nor it is
  /// attempted. This is the state before calling [Kabelwerk.connect] or after
  /// calling [Kabelwerk.disconnect].
  inactive,

  /// The Kabelwerk instance is actively trying to establish connection to the
  /// Kabelwerk backend. This is the state right after calling
  /// [Kabelwerk.connect] before the connection is established. This is also
  /// the state after a connection drop, before it gets re-established.
  connecting,

  /// The Kabelwerk instance is connected to the backend.
  online,
}
