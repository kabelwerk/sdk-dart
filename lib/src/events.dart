import './payloads.dart';

class Event {}

class ErrorEvent extends Event {}

// Kabelwerk events

class KabelwerkReady extends Event {}

class Connected extends Event {}

class Disconnected extends Event {}

class Reconnected extends Event {}

class UserUpdated extends Event {
  final User user;

  UserUpdated(this.user);
}

// Inbox events

class InboxReady extends Event {}

class InboxUpdated extends Event {}

// Room events

class RoomReady extends Event {}

class MessagePosted extends Event {}
