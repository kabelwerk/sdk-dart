import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:kabelwerk/kabelwerk.dart';

void main(List<String> arguments) {
  final parsed = parseArguments(arguments);

  final kabelwerk = Kabelwerk();
  late Room room;

  kabelwerk.config
    ..url = parsed['url']
    ..token = parsed['token'];

  kabelwerk.on('connected',
      (ConnectedEvent event) => printStatus('Kabelwerk — connected'));
  kabelwerk.on('disconnected',
      (DisconnectedEvent event) => printStatus('Kabelwerk — disconnected'));

  kabelwerk.on('ready', (KabelwerkReadyEvent event) {
    printStatus('Kabelwerk — ready');

    kabelwerk.openInbox()
      ..on('ready', (InboxReadyEvent event) {
        printStatus('Inbox — ready');

        if (event.items.isEmpty) {
          kabelwerk.createRoom(1).then((roomId) {
            room = setupRoom(kabelwerk, roomId);
          });
        } else {
          room = setupRoom(kabelwerk, event.items.first.roomId);
        }
      })
      ..on('updated', (InboxUpdatedEvent event) {
        printStatus('Inbox — updated');
      })
      ..connect();
  });

  kabelwerk.connect();

  void handleLine(line) {
    if (line.startsWith('/name ')) {
    } else {
      room.postMessage(text: line);
    }
  }

  stdin
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(handleLine);
}

Room setupRoom(Kabelwerk kabelwerk, int roomId) {
  return kabelwerk.openRoom(roomId)
    ..on('ready', (RoomReadyEvent event) {
      printStatus('Room — ready');

      for (final message in event.messages) {
        printMessage(message);
      }
    })
    ..on('message_posted', (MessagePostedEvent event) {
      printMessage(event.message);
    })
    ..connect();
}

ArgResults parseArguments(List<String> arguments) {
  final parser = ArgParser()
    ..addOption('url', mandatory: true)
    ..addOption('token', mandatory: true);

  return parser.parse(arguments);
}

void printStatus(String status) {
  stdout.writeln('* $status');
}

void printMessage(Message message) {
  stdout.writeln(
      '[${message.insertedAt}] <${message.user.name}> ${message.text}');
}
