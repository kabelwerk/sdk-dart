import 'package:args/args.dart';

import 'package:kabelwerk/kabelwerk.dart';

void main(List<String> arguments) {
  var parser = ArgParser()
    ..addOption('url')
    ..addOption('token');

  var parsed = parser.parse(arguments);

  var kabelwerk = Kabelwerk();

  if (parsed['url'] != null) {
    kabelwerk.config(url: parsed['url']);
  }

  if (parsed['token'] != null) {
    kabelwerk.config(token: parsed['token']);
  }

  kabelwerk.connect();
}
