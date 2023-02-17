# Kabelwerk

This is the [Kabelwerk](https://kabelwerk.io) SDK for Dart.


## Installation

Add [`kabelwerk`](https://pub.dev/packages/kabelwerk) as a dependency in your `pubspec.yaml`.


## Usage

### Connection

The entry point is to create and configure an instance of the `Kabelwerk` class, which opens and maintains the websocket connection to the Kabelwerk backend.

```dart
final kabelwerk = Kabelwerk();

kabelwerk.config(url: url, token: token);

kabelwerk.on('ready', (KabelwerkReadyEvent event) {
  // this event is fired once when the initial connection is established
  final inbox = kabelwerk.openInbox();
  final room = kabelwerk.openRoom();
});

kabelwerk.on('error', (ErrorEvent event) {
  // e.g. when the token is invalid
});

kabelwerk.connect();
```

A `Kabelwerk` instance takes care of automatically re-connecting when the connection drops, opening inboxes and rooms (see below), retrieving and updating user info.

Read more about [the Kabelwerk class](https://pub.dev/documentation/kabelwerk/latest/kabelwerk/Kabelwerk-class.html) in the docs.


### Inboxes

An inbox is a view on the rooms the user has access to; it maintains a list of rooms ordered by recency of their latest message.

```dart
final inbox = kabelwerk.openInbox();

inbox.on('ready', (InboxReadyEvent event) {
  // this event is fired once when the initial list of inbox items is loaded
});

inbox.on('updated', (InboxUpdatedEvent event) {
  // whenever a new message is posted, the list of inbox items is updated
  // accordingly and this event is fired
});

inbox.connect();
```

Read more about [the Inbox class](https://pub.dev/documentation/kabelwerk/latest/kabelwerk/Inbox-class.html) in the docs.


### Rooms

A room object handles posting and retrieving messages in a chat room.

```dart
final room = kabelwerk.openRoom(roomId);

room.on('ready', (RoomReadyEvent event) {
  // this event is fired once when the room is loaded
});

room.on('message_posted', (MessagePostedEvent event) {
  // this event is fired every time a new message is posted in this room
});

room.connect();

room.postMessage(text: text).then((message) {
  // you will also get the same message via the `message_posted` event
});
```

You can open as many rooms as you need. However, if you just want to listen for newly posted messages, then it is simpler to leverage the `InboxUpdatedEvent` event.

Read more about [the Room class](https://pub.dev/documentation/kabelwerk/latest/kabelwerk/Room-class.html) in the docs.


## Licence

Licensed under the [MIT](./LICENSE) licence.
