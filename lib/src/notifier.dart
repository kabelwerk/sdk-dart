import 'dart:async';

import 'package:phoenix_socket/phoenix_socket.dart'
    show PhoenixChannel, PushResponse;
import 'package:phoenix_socket/phoenix_socket.dart' as phoenix show Message;

import './connector.dart';
import './dispatcher.dart';
import './events.dart';
import './models.dart';

/// A notifier emits events intended to be used for implementing client-side
/// notifications.
///
/// A notifier will emit an `updated` event whenever there is a new message
/// posted in any of the rooms of the connected user (of course, excluding
/// messages authored by the latter). In case the websocket connection
/// temporarily drops, upon reconnecting the notifier will emit events for the
/// messages missed while the client was disconnected.
class Notifier {
  //
  // private variables
  //

  final Connector _connector;
  final int _userId;

  final Dispatcher _dispatcher = Dispatcher([
    'error',
    'ready',
    'updated',
  ]);

  final Map<String, int> _channelJoinParameters = {};

  late PhoenixChannel _channel;
  bool _connectHasBeenCalled = false;
  bool _ready = false;

  //
  // constructors
  //

  Notifier(this._connector, this._userId);

  //
  // private methods
  //

  void _updateChannelJoinParameters(List<Message> messages) {
    int max = -1;

    for (final message in messages) {
      if (message.id > max) {
        max = message.id;
      }
    }

    if (max != -1 &&
        (_channelJoinParameters.containsKey('after') == false ||
            max > _channelJoinParameters['after']!)) {
      _channelJoinParameters['after'] = max;
    }
  }

  void _handleJoinResponse(Map<String, dynamic> payload) {
    if (payload['status'] == 'ok') {
      final List<Message> messages = List.unmodifiable(payload['response']
              ['messages']
          .map((item) => Message.fromPayload(item)));

      _updateChannelJoinParameters(messages);

      if (_ready == false) {
        _ready = true;
        _dispatcher.send('ready', NotifierReadyEvent(messages));
      } else {
        for (final message in messages) {
          _dispatcher.send('updated', NotifierUpdatedEvent(message));
        }
      }
    } else {
      _dispatcher.send('error', ErrorEvent());
    }
  }

  Future<PushResponse> _setUpChannel() {
    _channel = _connector.socket.addChannel(
        topic: 'notifier:$_userId', parameters: _channelJoinParameters);

    _channel.messages.listen((phoenix.Message socketMessage) {
      if (socketMessage.event.value == 'phx_reply' &&
          socketMessage.ref == _channel.joinRef) {
        _handleJoinResponse(socketMessage.payload!);
      }

      if (socketMessage.event.value == 'message_posted') {
        final message = Message.fromPayload(socketMessage.payload!['message']);

        _updateChannelJoinParameters([message]);

        _dispatcher.send('updated', NotifierUpdatedEvent(message));
      }
    });

    return _channel.join().future;
  }

  //
  // public methods
  //

  /// Establishes connection to the server.
  ///
  /// Usually all event listeners should be already attached when this method
  /// is invoked.
  ///
  /// Returns a [Future] which resolves when the first connection attempt is
  /// carried out. However, note that connection may not always succeed on the
  /// first attempt — for state changes, do rely on the [NotifierReadyEvent]
  /// and [NotifierUpdatedEvent] events instead.
  Future<PushResponse> connect() {
    if (_connectHasBeenCalled != false) {
      throw StateError(
          "This Notifier instance's .connect() method was already called once.");
    }

    _connectHasBeenCalled = true;

    return _setUpChannel();
  }

  /// Closes the connection to the server.
  void disconnect() {
    if (_connectHasBeenCalled == true) {
      _channel.leave();
    }
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
