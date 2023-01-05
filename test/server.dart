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

  final expectsMessage = false;

  Future<WebSocket?> run(HttpRequest request) async {
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

  final expectsMessage = true;

  Future<void> run(WebSocket webSocket, Message message) async {
    assert(message.topic == channel);
    assert(message.event == 'phx_join');
    // assert(message.payload == payload);

    if (accept == true) {
      webSocket.add(message.createReply(reply).toJson());
    }
  }
}

class Disconnect {
  final int code;

  Disconnect({this.code = 1000});

  final expectsMessage = false;

  Future<void> run(WebSocket webSocket) async {
    await webSocket.close(code);
  }
}

// A websocket server running in an isolate and listening on a localhost port.
class Server {
  final List<dynamic> actions;

  Server(this.actions);

  late final Uri url;
  late final HttpServer _httpServer;

  Future<void> setUp() async {
    // port 0 = the system will choose the port
    _httpServer = await HttpServer.bind('127.0.0.1', 0);

    url = Uri(scheme: 'ws', host: '127.0.0.1', port: _httpServer.port);
  }

  Future<void> handleRequest() async {
    final request = await _httpServer.first;

    // the first action should be a Connect instance
    final webSocket = await actions.first.run(request);

    if (webSocket == null) return;

    final Stream incomingMessages = webSocket!.asBroadcastStream();

    for (final action in actions.sublist(1)) {
      if (action.expectsMessage) {
        final rawMessage = await incomingMessages.take(1).last;
        final message = Message.fromJson(rawMessage);

        await action.run(webSocket, message);
      } else {
        await action.run(webSocket);
      }
    }
  }
}

// An object with info needed by tests about the run of a websocket server.
class ServerRun {
  final String url;
  final Future<dynamic> done;

  ServerRun(this.url, this.done);
}

// Spawns a websocket server in an isolate to run the given actions.
Future<ServerRun> runServer(List<dynamic> actions) async {
  final receivePorts = [ReceivePort(), ReceivePort()];

  Isolate.spawn((List<SendPort> sendPorts) async {
    final server = Server(actions);

    await server.setUp();
    sendPorts[0].send(server.url.toString());

    await server.handleRequest();
    Isolate.exit(sendPorts[1], true);
  }, receivePorts.map((port) => port.sendPort).toList());

  final url = await receivePorts[0].first;

  return ServerRun(url, receivePorts[1].single);
}
