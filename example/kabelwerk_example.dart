import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

import 'package:kabelwerk/kabelwerk.dart';

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addOption('url', mandatory: true)
    ..addOption('token', mandatory: true);

  final parsed = parser.parse(arguments);

  final kabelwerk = Kabelwerk();
  Room? room;

  kabelwerk.config(url: parsed['url'], token: parsed['token']);

  kabelwerk.on('connected', (_) => printStatus('Kabelwerk — connected'));
  kabelwerk.on('disconnected', (_) => printStatus('Kabelwerk — disconnected'));
  kabelwerk.on('reconnected', (_) => printStatus('Kabelwerk — reconnected'));

  kabelwerk.on('ready', (_) {
    printStatus('Kabelwerk — ­ready');

    kabelwerk.openInbox()
      ..on('ready', (event) {
        printStatus('Inbox — ready');

        if (event.items.isEmpty) {
          kabelwerk.createRoom(1).then((roomId) {
            room = setupRoom(kabelwerk, roomId);
          });
        } else {
          room = setupRoom(kabelwerk, event.items.first.room.id);
        }
      })
      ..on('updated', (event) {
        printStatus('Inbox — updated');
      })
      ..connect();
  });

  kabelwerk.connect();

  void handleLine(line) {
    if (line.startsWith('/name ')) {
    } else {
      room?.postMessage(text: line);
    }
  }

  stdin
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(handleLine);
}

Room setupRoom(Kabelwerk kabelwerk, int roomId) {
  return kabelwerk.openRoom(roomId)
    ..on('ready', (event) {
      printStatus('Room — ready');

      for (final message in event.messages) {
        printMessage(message);
      }
    })
    ..on('message_posted', (event) {
      printMessage(event.message);
    })
    ..connect();
}

void printStatus(String status) {
  stdout.writeln('* ${status}');
}

void printMessage(Message message) {
  stdout.writeln(
      '[${message.insertedAt}] <${message.user?.name}> ${message.text}');
}
