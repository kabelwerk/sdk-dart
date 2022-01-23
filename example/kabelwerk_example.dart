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

  kabelwerk.config(url: parsed['url'], token: parsed['token']);

  kabelwerk.on('connected', (_) => stdout.writeln('connected'));
  kabelwerk.on('disconnected', (_) => stdout.writeln('disconnected'));
  kabelwerk.on('reconnected', (_) => stdout.writeln('reconnected'));

  kabelwerk.on('ready', (_) {
    stdout.writeln('ready');

    inbox = kabelwerk.openInbox()
      ..on('ready', (event) {
        print(event.items);
      });

    inbox?.on('updated', (event) {
      print(event.items);
    });

    inbox?.connect();
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
