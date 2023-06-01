/// The configuration of a [Kabelwerk] instance.
class Config {
  //
  // public variables
  //

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

  //
  // constructors
  //

  /// Do not create instances directly — use [Kabelwerk.config] instead.
  Config();

  //
  // private methods
  //

  RegExpMatch _parseUrl() {
    final regex = RegExp(
        r'^(?<scheme>wss?:\/\/)?(?<host>[0-9a-z.:-]+)\/?(?<path>[a-z\/]+)?$');

    final match = regex.firstMatch(url);

    if (match == null) {
      throw StateError('$url is not a valid Kabelwerk URL.');
    }

    return match;
  }

  //
  // public methods
  //

  /// Returns the websocket URL.
  String getSocketUrl() {
    final match = _parseUrl();

    final scheme = match.namedGroup('scheme') ?? 'wss://';
    final host = match.namedGroup('host')!;

    // note that unlike its js counterpart, phoenix_socket does not append the
    // transport (+ '/websocket') and thus requires the full path
    final path = '/${match.namedGroup('path') ?? 'socket/user/websocket'}';

    return scheme + host + path;
  }

  /// Returns the API URL.
  String getApiUrl() {
    final match = _parseUrl();

    final scheme =
        match.namedGroup('scheme') == 'ws://' ? 'http://' : 'https://';
    final host = match.namedGroup('host')!;
    final path = '/api';

    return scheme + host + path;
  }
}
