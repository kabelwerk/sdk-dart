import 'package:phoenix_wings/phoenix_wings.dart';

import './dispatcher.dart';
import './events.dart';
import './payloads.dart';

/// An inbox is a view on the rooms the user has access to; it maintains a list
/// of rooms ordered by recency of their latest message.
class Inbox {
  // dispatcher
  final Dispatcher _dispatcher = Dispatcher([
    'error',
    'ready',
    'updated',
  ]);

  // internal state
  final User _user;
  final Map _items = Map();
  bool _ready = false;

  // phoenix
  final PhoenixSocket _socket;
  PhoenixChannel? _channel;

  Inbox(this._socket, this._user);

  void _setupChannel() {
    _channel = _socket.channel('user_inbox:${_user.id}');

    _channel?.on('inbox_updated', (Map? payload, _ref, _joinRef) {
      if (payload == null) {
        throw Error();
      }

      final inboxItem = InboxItem.fromPayload(payload, _user);

      _items[inboxItem.room.id] = inboxItem;

      _dispatcher.send('updated', InboxUpdated(listItems()));
    });

    var push = _channel?.join();

    push?.receive('ok', (Map? payload) {
      _loadItemsOnJoin();
    });

    push?.receive('error', (error) {
      _dispatcher.send('error', ErrorEvent());
    });

    push?.receive('timeout', (error) {
      _dispatcher.send('error', ErrorEvent());
    });
  }

  void _loadItemsOnJoin() {
    var push = _channel?.push(event: 'list_rooms', payload: Map());

    push?.receive('ok', (Map? payload) {
      if (payload == null) throw Error();

      for (var inboxItem in InboxItemsList.fromPayload(payload, _user).items) {
        _items[inboxItem.room.id] = inboxItem;
      }

      if (!_ready) {
        _ready = true;

        _dispatcher.send('ready', InboxReady(listItems()));
      } else {
        _dispatcher.send('updated', InboxUpdated(listItems()));
      }
    });

    push?.receive('error', (error) {
      _dispatcher.send('error', ErrorEvent());
    });

    push?.receive('timeout', (error) {
      _dispatcher.send('error', ErrorEvent());
    });
  }

  /// Establishes connection to the server.
  ///
  /// Usually all event listeners should be already attached when this method
  /// is invoked.
  void connect() {
    if (_channel != null) throw Error();

    _setupChannel();
  }

  /// Removes all previously attached event listeners and closes the connection
  /// to the server.
  void disconnect() {
    _dispatcher.off();

    _channel?.leave();
    _channel = null;

    _items.clear();
    _ready = false;
  }

  /// Returns the list of inbox items already loaded by the inbox.
  ///
  /// The list is sorted by the rooms' latest messages (the room with the most
  /// recent message comes first).
  List<InboxItem> listItems() {
    final list = List<InboxItem>.from(_items.values);

    list.sort((InboxItem itemA, InboxItem itemB) {
      DateTime a = itemA.message?.insertedAt ?? DateTime(0);
      DateTime b = itemB.message?.insertedAt ?? DateTime(0);

      return a.compareTo(b);
    });

    return list;
  }

  /// Removes one or more previously attached event listeners.
  ///
  /// Both parameters are optional: if no [reference] is given, all listeners
  /// for the given event are removed; if no [event] is given, then all event
  /// listeners attached to the instance are removed.
  void off([String? event, String? reference]) =>
      _dispatcher.off(event, reference);

  /// Attaches an event listener.
  ///
  /// Returns a short string identifying the attached listener — which string
  /// can be then used to remove that event listener with [Inbox.off()].
  String on(String event, Function function) => _dispatcher.on(event, function);
}
