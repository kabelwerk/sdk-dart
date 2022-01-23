import 'package:test/test.dart';

import 'package:kabelwerk/src/payloads.dart';

const inboxItemPayload = {
  'room': {
    'hub_id': 1,
    'id': 2,
  },
  'message': {
    'id': 42,
    'room_id': 2,
    'text': 'Hello world!',
    'type': 'text',
    'inserted_at': '2022-01-22T18:39:21.820Z',
    'updated_at': '2022-01-22T18:39:21.820Z',
    'user': {
      'id': 5,
      'key': 'bot',
      'name': 'Bot',
    },
  },
  'marked_by': [5],
};

void main() {
  final user = User(id: 5, key: 'bot', name: 'Bot');

  test('inbox item from payload', () {
    var item = InboxItem.fromPayload(inboxItemPayload, user);

    expect(item.room.id, equals(2));
    expect(item.room.hubId, equals(1));

    expect(item.message?.id, equals(42));
    expect(item.message?.text, equals('Hello world!'));
    expect(item.message?.insertedAt,
        equals(DateTime.utc(2022, 1, 22, 18, 39, 21, 820)));
    expect(item.message?.updatedAt,
        equals(DateTime.utc(2022, 1, 22, 18, 39, 21, 820)));
    expect(item.message?.user?.id, equals(5));

    expect(item.isNew, equals(false));
  });
}
