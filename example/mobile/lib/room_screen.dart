import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_chat_types/flutter_chat_types.dart'
    as flutter_chat_types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart' as flutter_chat_ui;
import 'package:kabelwerk/kabelwerk.dart';
import 'package:provider/provider.dart';

import './kabelwerk.dart';

class RoomScreen extends StatefulWidget {
  final int roomId;

  const RoomScreen({
    super.key,
    this.roomId = 0,
  });

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  late final Room _room;

  bool _ready = false;
  List<Message> _messages = [];

  @override
  void initState() {
    super.initState();

    _room = Provider.of<KabelwerkContext>(context, listen: false)
        .kabelwerk
        .openRoom(widget.roomId);

    _room.on('ready', (RoomReadyEvent event) {
      setState(() {
        _messages = event.messages;
        _ready = true;
      });
    });

    _room.on('message_posted', (MessagePostedEvent event) {
      setState(() {
        _messages = [..._messages, event.message];
      });
    });

    _room.connect();
  }

  @override
  void dispose() {
    _room.off();
    _room.disconnect();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kabelwerk Chat')),
      body: flutter_chat_ui.Chat(
        messages: _messages.reversed.map(_convertMessage).toList(),
        onSendPressed: (flutter_chat_types.PartialText text) {
          _room.postMessage(text: text.text);
        },
        user: _convertUser(
            Provider.of<KabelwerkContext>(context, listen: false).user),
      ),
    );
  }

  flutter_chat_types.User _convertUser(User user) {
    return flutter_chat_types.User(
      id: user.id.toString(),
      firstName: user.name,
    );
  }

  flutter_chat_types.Message _convertMessage(Message message) {
    return flutter_chat_types.TextMessage(
      author: _convertUser(message.user),
      id: message.id.toString(),
      text: message.text,
    );
  }
}
