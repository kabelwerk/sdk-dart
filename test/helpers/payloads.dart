class BaseObjects {
  // Returns a timestamp in ISO format.
  String timestamp() {
    return DateTime.now().toUtc().toIso8601String();
  }

  // Generates a hub object.
  Map<String, dynamic> hub() {
    return {
      'id': 1,
      'name': 'Test Hub',
      'slug': 'test_hub',
    };
  }

  // Generates a user object.
  Map<String, dynamic> user() {
    return {
      'id': 1,
      'key': 'test_user',
      'name': 'Test User',
    };
  }

  // Generates a message object.
  Map<String, dynamic> message() {
    return {
      'html': '<p>hello!</p>',
      'id': 1,
      'inserted_at': timestamp(),
      'room_id': 1,
      'text': 'hello!',
      'type': 'text',
      'updated_at': timestamp(),
      'upload': null,
      'user': user(),
    };
  }

  // Generates an upload object.
  Map<String, dynamic> upload() {
    return {};
  }

  // Generates a marker object.
  Map<String, dynamic> marker() {
    return {
      'message_id': 1,
      'room_id': 1,
      'updated_at': timestamp(),
      'user_id': 1,
    };
  }
}

class PrivateChannelPayloads extends BaseObjects {
  // Generates a user object.
  //
  // Note that the user objects used in private channel messages represent the
  // connected user and include more details than the base user object used in
  // other channels' messages.
  Map<String, dynamic> user() {
    return {
      'hub_id': null,
      'id': 1,
      'inserted_at': timestamp(),
      'key': 'test_user',
      'name': 'Test User',
      'updated_at': timestamp(),
    };
  }

  // Generates a private channel join response payload.
  Map<String, dynamic> joinOk() {
    return {
      'room_ids': [1, 2],
      'user': user(),
    };
  }

  // Generates an update_user response payload.
  Map<String, dynamic> updateUserOk() {
    return user();
  }

  // Generates an update_device response payload.
  Map<String, dynamic> updateDeviceOk() {
    return {
      'id': 1,
      'inserted_at': timestamp(),
      'push_notifications_enabled': false,
      'push_notifications_token': '',
      'updated_at': timestamp(),
    };
  }

  // Generates a create_room response payload.
  Map<String, dynamic> createRoomOk() {
    return {
      'id': 1,
      'hub_id': 1,
      'user_id': 1,
    };
  }

  // Generates a user_updated event payload.
  Map<String, dynamic> userUpdated() {
    return user();
  }
}

class RoomChannelPayloads extends BaseObjects {
  // Generates a room channel join response payload.
  Map<String, dynamic> joinOk() {
    return {
      'attributes': {'key': 'value'},
      'id': 1,
      'markers': [marker(), marker()],
      'messages': [message()],
      'user': user(),
    };
  }

  // Generates a list_messages response payload.
  Map<String, dynamic> listMessagesOk() {
    return {
      'messages': [message()],
    };
  }

  // Generates a move_marker response payload.
  Map<String, dynamic> moveMarkerOk() {
    return marker();
  }

  // Generates a post_message response payload.
  Map<String, dynamic> postMessageOK() {
    return message();
  }

  // Generates a delete_message response payload.
  Map<String, dynamic> deleteMessageOk() {
    return message();
  }

  // Generates a get_attributes response payload.
  Map<String, dynamic> getAttributesOk() {
    return {
      'attributes': {'key': 'value'},
      'id': 1,
      'user': user(),
    };
  }

  // Generates a set_attributes response payload.
  Map<String, dynamic> setAttributesOk() {
    return {
      'attributes': {'key': 'value'},
      'id': 1,
      'user': user(),
    };
  }

  // Generates a marker_moved event payload.
  Map<String, dynamic> markerMoved() {
    return marker();
  }

  // Generates a message_posted event payload.
  Map<String, dynamic> messagePosted() {
    return message();
  }

  // Generates a message_deleted event payload.
  Map<String, dynamic> messageDeleted() {
    return message();
  }
}

class InboxChannelPayloads extends BaseObjects {
  // Generates an inbox item object.
  Map<String, dynamic> inboxItem() {
    return {
      'marked_by': [1, 2],
      'message': message(),
      'room': {
        'hub': hub(),
        'id': 1,
      },
    };
  }

  // Generates an inbox channel join response payload.
  Map<String, dynamic> joinOk() {
    return {};
  }

  // Generates a list_rooms response payload.
  Map<String, dynamic> listRoomsOk() {
    return {
      'items': [inboxItem(), inboxItem()],
    };
  }

  // Generates an inbox_updated event payload.
  Map<String, dynamic> inboxUpdated() {
    return inboxItem();
  }
}

class NotifierChannelPayloads extends BaseObjects {
  // Generates a notifier channel join response payload.
  Map<String, dynamic> joinOk() {
    return {
      'messages': [message(), message()],
    };
  }

  // Generates a message_posted event payload.
  Map<String, dynamic> messagePosted() {
    return {
      'message': message(),
    };
  }
}

class Payloads {
  static final privateChannel = PrivateChannelPayloads();
  static final roomChannel = RoomChannelPayloads();
  static final inboxChannel = InboxChannelPayloads();
  static final notifierChannel = NotifierChannelPayloads();
}
