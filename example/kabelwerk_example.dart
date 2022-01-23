import 'dart:async';
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
  Inbox? inbox;
  Room? room;

  kabelwerk.config(url: parsed['url'], token: parsed['token']);

  kabelwerk.on('connected', (_) => stdout.writeln('connected'));
  kabelwerk.on('disconnected', (_) => stdout.writeln('disconnected'));
  kabelwerk.on('reconnected', (_) => stdout.writeln('reconnected'));

  kabelwerk.on('ready', (_) {
    stdout.writeln('ready');

    inbox = kabelwerk.openInbox()
      ..on('ready', (event) {
        room = kabelwerk.openRoom(event.items.first.room.id)
          ..on('ready', (event) {
            print(event.messages);

            room?.postMessage(text: 'hi from dart!');
          })
          ..on('message_posted', (event) {
            print(event.message);
          })
          ..connect();
      })
      ..on('updated', (event) {
        print(event.items);
      })
      ..connect();
  });

  kabelwerk.connect();

  void handleLine(line) {
    print(line);
  }

  stdin
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(handleLine);
}
