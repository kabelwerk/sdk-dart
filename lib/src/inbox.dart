import 'dart:async';

import 'package:phoenix_socket/phoenix_socket.dart';

import './connector.dart';
import './dispatcher.dart';
import './events.dart';
import './models.dart';

/// An inbox is a view on the rooms the user has access to; it maintains a list
/// of rooms ordered by recency of their latest message.
class Inbox {
  final Connector _connector;
  final int _userId;

  Inbox(this._connector, this._userId);

  final Dispatcher _dispatcher = Dispatcher([
    'error',
    'ready',
    'updated',
  ]);

  final Map<int, InboxItem> _items = Map();

  bool _connectHasBeenCalled = false;
  bool _ready = false;

  late PhoenixChannel _channel;

  //
  // getters
  //

  /// The list of inbox items already loaded by the inbox.
  ///
  /// The list is sorted by the rooms' latest messages (the room with the most
  /// recent message comes first).
  List<InboxItem> get items {
    final list = List<InboxItem>.from(_items.values);

    list.sort((InboxItem itemA, InboxItem itemB) {
      DateTime a = itemA.message?.insertedAt ?? DateTime(0);
      DateTime b = itemB.message?.insertedAt ?? DateTime(0);

      return a.compareTo(b);
    });

    return list;
  }

  //
  // private methods
  //

  void _setupChannel() {
    _channel = _connector.socket.addChannel(topic: 'user_inbox:${_userId}');

    _channel.messages.listen((message) {
      if (message.event.value == 'inbox_updated') {
        final inboxItem = InboxItem.fromPayload(message.payload!, _userId);
        _items[inboxItem.roomId] = inboxItem;
        _dispatcher.send('updated', InboxUpdatedEvent(items));
      }
    });

    _channel.join()
      ..onReply('ok', (PushResponse pushResponse) {
        _loadItemsOnJoin();
      })
      ..onReply('error', (error) {
        _dispatcher.send('error', ErrorEvent());
      })
      ..onReply('timeout', (error) {
        _dispatcher.send('error', ErrorEvent());
      });
  }

  void _loadItemsOnJoin() {
    _channel.push('list_rooms', {})
      ..onReply('ok', (PushResponse pushResponse) {
        for (final item in pushResponse.response['items']) {
          final inboxItem = InboxItem.fromPayload(item, _userId);
          _items[inboxItem.roomId] = inboxItem;
        }

        if (_ready == false) {
          _ready = true;
          _dispatcher.send('ready', InboxReadyEvent(items));
        } else {
          _dispatcher.send('updated', InboxUpdatedEvent(items));
        }
      })
      ..onReply('error', (error) {
        _dispatcher.send('error', ErrorEvent());
      })
      ..onReply('timeout', (error) {
        _dispatcher.send('error', ErrorEvent());
      });
  }

  //
  // public methods
  //

  /// Establishes connection to the server.
  ///
  /// Usually all event listeners should be already attached when this method
  /// is invoked.
  void connect() {
    if (_connectHasBeenCalled != false) {
      throw StateError(
          "This Inbox instance's .connect() method has already been called once.");
    }

    _connectHasBeenCalled = true;
    _setupChannel();
  }

  /// Closes the connection to the server.
  void disconnect() {
    _channel.leave();

    _items.clear();
    _ready = false;
  }

  /// Loads more inbox items.
  ///
  /// Returns a [Future] which resolves into the updated list of inbox items.
  Future<List<InboxItem>> loadMore() {
    final Completer<List<InboxItem>> completer = Completer();

    _channel.push('list_rooms', {'offset': _items.length})
      ..onReply('ok', (PushResponse pushResponse) {
        for (final item in pushResponse.response['items']) {
          final inboxItem = InboxItem.fromPayload(item, _userId);
          _items[inboxItem.roomId] = inboxItem;
        }

        completer.complete(items);
      })
      ..onReply('error', (error) {
        completer.completeError(ErrorEvent());
      })
      ..onReply('timeout', (error) {
        completer.completeError(ErrorEvent());
      });

    return completer.future;
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
  /// can be then used to remove that event listener with [off].
  String on(String event, Function function) => _dispatcher.on(event, function);

  /// Attaches a one-time event listener.
  ///
  /// This method does the same as [on] except that the event listener will be
  /// automatically removed after being invoked — i.e. the listener is invoked
  /// at most once.
  String once(String event, Function function) =>
      _dispatcher.once(event, function);
}
