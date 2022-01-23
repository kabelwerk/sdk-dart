import 'package:phoenix_wings/phoenix_wings.dart';

import './dispatcher.dart';
import './events.dart';
import './payloads.dart';

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

  void connect() {
    if (_channel != null) throw Error();

    _setupChannel();
  }

  void disconnect() {
    _dispatcher.off();

    _channel?.leave();
    _channel = null;

    _items.clear();
    _ready = false;
  }

  List<InboxItem> listItems() {
    final list = List<InboxItem>.from(_items.values);

    list.sort((InboxItem itemA, InboxItem itemB) {
      DateTime a = itemA.message?.insertedAt ?? DateTime(0);
      DateTime b = itemB.message?.insertedAt ?? DateTime(0);

      return a.compareTo(b);
    });

    return list;
  }

  void off([String? event, String? reference]) =>
      _dispatcher.off(event, reference);

  String on(String event, Function function) => _dispatcher.on(event, function);
}
