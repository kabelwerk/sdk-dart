/// The configuration of a [Kabelwerk] instance.
class Config {
  /// The URL of the Kabelwerk backend to connect to.
  String url = 'wss://hub.kabelwerk.io/socket/user';

  /// A [JWT](https://datatracker.ietf.org/doc/html/rfc7519) token to
  /// authenticate the connection.
  ///
  /// The token has to:
  ///
  /// - be signed by an RSA key the public counterpart of which is known to the
  /// Kabelwerk backend you are connecting to;
  /// - include a `sub` claim identifying the user on behalf of whom the
  /// connection is established;
  /// - include a valid `exp` claim.
  ///
  /// The value of the `sub` claim is stored on the Kabelwerk backend as the
  /// respective user's key.
  String token = '';

  /// A function to refresh rejected tokens.
  ///
  /// If this setting is provided, it must be a function that takes as argument
  /// the current authentication token and returns a [Future] resolving into a
  /// new authentication token (or perhaps the same token if no refresh is
  /// needed).
  ///
  /// If you provide only a `token`, it will be used both for the initial
  /// connection and then again each time when reconnecting. If you provide
  /// only a `refreshToken` function, it will be called to obtain the initial
  /// connection token, and then it will be called again each time when
  /// reconnecting. If you provide both a `token` and a `refreshToken`
  /// function, then the former will be used for the initial connection, and
  /// the latter each time when reconnecting.
  Future<String> Function(String)? refreshToken;

  /// A list of hubs on which to create rooms, if these do not exist already,
  /// for the connected user.
  ///
  /// The value has to be a list of hub slugs.
  ///
  /// If Kabelwerk fails to ensure that the connected user has a room on each
  /// of the specified hubs (e.g. because a slug is wrong), an [ErrorEvent] is
  /// emitted and the connection is terminated.
  List<String> ensureRoomsOn = [];

  /// Whether to ensure that the connected user has rooms on all hubs.
  ///
  /// This is a shortcut for setting [ensureRoomsOn] to a list containing all
  /// hub slugs.
  bool ensureRoomsOnAllHubs = false;
}
