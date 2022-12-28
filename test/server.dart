import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

// A phoenix websocket message.
class Message {
  final String joinRef;
  final String ref;
  final String topic;
  final String event;
  final Map payload;

  Message(this.joinRef, this.ref, this.topic, this.event, this.payload);

  static Message fromJson(String input) {
    final list = json.decode(input);
    return Message(list[0], list[1], list[2], list[3], list[4]);
  }

  String toJson() {
    return json.encode([joinRef, ref, topic, event, payload]);
  }

  Message createReply(Map payload) {
    return Message(joinRef, ref, topic, 'phx_reply',
        {'status': 'ok', 'response': payload});
  }
}

class Connect {
  final bool accept;

  Connect({this.accept = true});

  Future<WebSocket?> run(HttpServer httpServer) async {
    final request = await httpServer.first;

    if (accept) {
      final webSocket = await WebSocketTransformer.upgrade(request);
      return webSocket;
    } else {
      request.response.statusCode = 403;
      request.response.close();
      return null;
    }
  }
}

class Join {
  final String channel;
  final bool accept;
  final Map payload;
  final Map reply;

  Join(this.channel, this.payload, this.reply, {this.accept = true});

  run(WebSocket webSocket) async {
    final message = Message.fromJson(await webSocket.first);

    assert(message.topic == channel);
    assert(message.event == 'phx_join');
    // assert(message.payload == payload);

    if (accept == true) {
      webSocket.add(message.createReply(reply).toJson());
    }
  }
}

// A websocket server running in an isolate and listening on a localhost port.
class Server {
  final Uri url;
  final List<dynamic> actions;

  Server(this.url, this.actions);

  HttpServer? _httpServer;
  WebSocket? _webSocket;

  run() async {
    _httpServer = await HttpServer.bind(url.host, url.port);

    // the first action should be a Connect instance
    _webSocket = await actions.first.run(_httpServer!);

    for (final action in actions.sublist(1)) {
      await action.run(_webSocket);
    }
  }
}

// An object with info needed by tests about the run of a websocket server.
class ServerRun {
  final String url;
  final Future<dynamic> done;

  ServerRun(this.url, this.done);
}

// A singleton that takes care of spawning servers in isolates.
class ServerSpawner {
  static const host = '127.0.0.1';
  static int nextPort = 42000;

  static ServerRun spawn(List<dynamic> actions) {
    final receivePort = ReceivePort();

    final url = Uri(scheme: 'ws', host: host, port: nextPort++);
    final server = Server(url, actions);

    Isolate.spawn((SendPort sendPort) async {
      await server.run();

      Isolate.exit(sendPort, true);
    }, receivePort.sendPort);

    return ServerRun(server.url.toString(), receivePort.first);
  }
}

// Spawn a websocket server in an isolate to run the given actions.
ServerRun runServer(List<dynamic> actions) {
  return ServerSpawner.spawn(actions);
}
