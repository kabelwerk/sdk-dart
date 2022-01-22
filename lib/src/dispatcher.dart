class Callback {
  final String reference;
  final String event;
  final Function function;

  Callback(this.reference, this.event, this.function);
}

class Dispatcher {
  List<String> _eventNames = [];
  List<Callback> _callbacks = [];
  int _lastReference = -1;

  Dispatcher(this._eventNames);

  void _checkEventName(String eventName) {
    if (!_eventNames.contains(eventName)) {
      throw ArgumentError('Unknown event name: ${eventName}.');
    }
  }

  String _generateReference() {
    return (++_lastReference).toString();
  }

  void send(String event, dynamic params) {
    _checkEventName(event);

    _callbacks.forEach((callback) {
      if (callback.event == event) {
        callback.function(params);
      }
    });
  }

  String on(String event, Function function) {
    _checkEventName(event);

    var reference = _generateReference();
    var callback = Callback(reference, event, function);
    _callbacks.add(callback);

    return reference;
  }

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
}
