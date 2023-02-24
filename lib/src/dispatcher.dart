import 'package:logging/logging.dart';

final _logger = Logger('kabelwerk.dispatcher');

class Callback {
  final String reference;
  final String event;
  final Function function;

  Callback(this.reference, this.event, this.function);
}

class Dispatcher {
  //
  // private variables
  //

  final List<String> _eventNames;
  final List<Callback> _callbacks = [];
  int _lastReference = -1;

  //
  // constructors
  //

  Dispatcher(this._eventNames);

  //
  // private methods
  //

  void _checkEventName(String eventName) {
    if (!_eventNames.contains(eventName)) {
      throw ArgumentError('Unknown event name: $eventName.');
    }
  }

  String _generateReference() {
    return (++_lastReference).toString();
  }

  //
  // public methods
  //

  /// Emits an event.
  ///
  /// Invoke the callbacks registered for the event with the given params.
  void send(String event, dynamic params) {
    _checkEventName(event);

    _logger.fine('Emitting an $event event.', params);

    // separate list to prevent concurrent modification of _callbacks because
    // of one-time callbacks
    final List<Callback> relevantCallbacks = [];

    for (final callback in _callbacks) {
      if (callback.event == event) {
        relevantCallbacks.add(callback);
      }
    }

    for (final callback in relevantCallbacks) {
      callback.function(params);
    }
  }

  /// Registers a callback for an event.
  ///
  /// Whenever the event is emitted, the callback is invoked with the params
  /// provided to [send].
  ///
  /// Returns a reference which can be used to clear the callback without
  /// affecting the other callbacks attached to the event.
  String on(String event, Function function) {
    _checkEventName(event);

    final reference = _generateReference();
    final callback = Callback(reference, event, function);
    _callbacks.add(callback);

    return reference;
  }

  /// Removes a registered callback.
  ///
  /// If no reference to a particular callback is provided, clears all
  /// callbacks registered with the event.
  ///
  /// If no event is specified, clears all registered callbacks.
  void off([String? event, String? reference]) {
    if (event != null) {
      _checkEventName(event);

      _callbacks.removeWhere((callback) {
        if (callback.event == event) {
          if (reference != null) {
            return callback.reference == reference;
          } else {
            return true;
          }
        }

        return false;
      });
    } else {
      _callbacks.clear();
    }
  }

  /// Registers a one-time callback for event.
  ///
  /// The callback is automatically removed after the first time the event is
  /// emitted.
  ///
  /// Just as [on], returns a reference which can be used to clear the callback
  /// before it has been invoked.
  String once(String event, Function function) {
    _checkEventName(event);

    final reference = _generateReference();

    final callback = Callback(reference, event, (params) {
      function(params);
      off(event, reference);
    });
    _callbacks.add(callback);

    return reference;
  }
}
