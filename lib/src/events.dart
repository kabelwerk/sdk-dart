import './connection_state.dart';
import './models.dart';

/// The base class for all events in the library.
class Event {}

/// An event fired when there is a problem establishing connection to the
/// server (e.g. because of a timeout).
class ErrorEvent extends Event {}

//
// connector and kabelwerk events
//

/// A [Kabelwerk] event fired when the connection to the server is first
/// established and the Kabelwerk instance is ready to be used.
///
/// This event is fired at most once per Kabelwerk instance.
class KabelwerkReadyEvent extends Event {
  /// The connected user.
  final User user;

  KabelwerkReadyEvent(this.user);
}

/// A [Kabelwerk] event fired when the connection to the server is first
/// established.
///
/// This could be either because [Kabelwerk.connect] was just invoked, or it
/// could be due to automatically re-establishing the connection after a
/// connection drop. In the former case, the Kabelwerk instance may not yet be
/// ready to be used as it may still have to fetch some data from the server
/// (such as the connected user's info).
///
/// Useful for displaying the connection's status to the user.
class ConnectedEvent extends Event {
  /// The new connection state.
  final ConnectionState connectionState;

  ConnectedEvent(this.connectionState);
}

/// A [Kabelwerk] event fired when the connection to the server is dropped.
///
/// Useful for displaying the connection's status to the user.
class DisconnectedEvent extends Event {
  /// The new connection state.
  final ConnectionState connectionState;

  DisconnectedEvent(this.connectionState);
}

/// A [Kabelwerk] event fired when the connected user's name has changed.
class UserUpdatedEvent extends Event {
  /// The up-to-date user.
  final User user;

  UserUpdatedEvent(this.user);
}

//
// inbox events
//

/// An [Inbox] event fired when the connection to the server is first
/// established and the Inbox instance is ready to be used.
///
/// This event is fired at most once per Inbox instance.
class InboxReadyEvent extends Event {
  /// The list of initially loaded inbox items.
  final List<InboxItem> items;

  InboxReadyEvent(this.items);
}

/// An [Inbox] event fired when any of the inbox items changes.
///
/// An inbox update is triggered by a new message posted in any of the rooms
/// (including rooms not yet loaded). Also, if the websocket connection drops,
/// the event is fired upon reconnecting if any update occurred while the
/// websocket was disconnected.
class InboxUpdatedEvent extends Event {
  /// The updated (and re-ordered) list of inbox items.
  final List<InboxItem> items;

  InboxUpdatedEvent(this.items);
}

//
// room events
//

/// A [Room] event fired when the connection to the server is first established
/// and the Room instance is ready to be used.
///
/// This event is fired at most once per Room instance.
class RoomReadyEvent extends Event {
  /// The list of the room's most recent messages (up to 100).
  final List<Message> messages;

  /// The connected user's marker in the room.
  final Marker? ownMarker;

  /// The latest hub-side marker in the room.
  final Marker? theirMarker;

  RoomReadyEvent(this.messages, this.ownMarker, this.theirMarker);
}

/// A [Room] event fired when there is a new message posted in the room (by any
/// user).
///
/// If the websocket connection drops, the event is fired upon reconnecting for
/// each message posted while the websocket was disconnected.
class MessagePostedEvent extends Event {
  /// The newly posted message.
  final Message message;

  MessagePostedEvent(this.message);
}

/// A [Room] event fired when a message is deleted from the room (by any user).
class MessageDeletedEvent extends Event {
  /// The deleted message.
  final Message message;

  MessageDeletedEvent(this.message);
}

/// A [Room] event fired when a marker in the room is updated or created (by
/// any user).
///
/// If the websocket connection drops, fired upon reconnecting for each marker
/// moved while the websocket was disconnected.
class MarkerMovedEvent extends Event {
  /// The updated marker.
  final Marker marker;

  MarkerMovedEvent(this.marker);
}

//
// notifier events
//

/// A [Notifier] event fired when the Notifier instance has first established
/// connection to the server and is ready to be used.
///
/// This event is fired at most once per Notifier instance.
///
/// You may wish to use this event to show a (potentially large) number of
/// notifications to the user upon opening the client.
class NotifierReadyEvent extends Event {
  /// A list of messages not yet marked by the connected user.
  final List<Message> messages;

  NotifierReadyEvent(this.messages);
}

/// A [Notifier] event fired when there is a new message posted in any of the
/// rooms that the connected user has access to.
///
/// If the websocket connection drops, fired upon reconnecting for each message
/// posted while the websocket was disconnected.
class NotifierUpdatedEvent extends Event {
  /// The new message.
  final Message message;

  NotifierUpdatedEvent(this.message);
}
