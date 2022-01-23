import './payloads.dart';

/// The base class for all events in the library.
class Event {}

/// An event fired when there is a problem establishing connection to the
/// server (e.g. because of a timeout).
class ErrorEvent extends Event {}

// Kabelwerk events

/// A [Kabelwerk] event fired when the connection to the server is first
/// established and the Kabelwerk instance is ready to be used.
///
/// This event is fired at most once per Kabelwerk instance.
class KabelwerkReady extends Event {}

/// A [Kabelwerk] event fired when the connection to the server is first
/// established.
///
/// At this point the Kabelwerk instance is not ready to be used as it yet has
/// to exchange some data with the server (such as fetching the connected
/// user's info). However, this event may be useful for displaying the
/// connection's status.
///
/// This event is fired at most once per Kabelwerk instance.
class Connected extends Event {}

/// A [Kabelwerk] event fired when the connection to the server is dropped.
///
/// Useful for displaying the connection's status to the user.
class Disconnected extends Event {}

/// A [Kabelwerk] event fired when the connection to the server is
/// automatically re-established after a disconnect.
///
/// Useful for displaying the connection's status to the user.
class Reconnected extends Event {}

/// A [Kabelwerk] event fired when the connected user's attributes are changed.
class UserUpdated extends Event {
  /// The up-to-date user attributes.
  final User user;

  UserUpdated(this.user);
}

// Inbox events

/// An [Inbox] event fired when the connection to the server is first
/// established.
///
/// This event is fired at most once per inbox instance.
class InboxReady extends Event {
  /// The list of initially loaded inbox items.
  final List<InboxItem> items;

  InboxReady(this.items);
}

/// An [Inbox] event fired when any of the inbox items changes.
///
/// An inbox update is triggered by a new message posted in any of the rooms
/// (including rooms not yet loaded). Also, if the websocket connection drops,
/// the event is fired upon reconnect if any update occurred while the
/// websocket was disconnected.
class InboxUpdated extends Event {
  /// The updated (and re-ordered) list of inbox items.
  final List<InboxItem> items;

  InboxUpdated(this.items);
}

// Room events

class RoomReady extends Event {}

class MessagePosted extends Event {}
