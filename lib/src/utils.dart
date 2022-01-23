dynamic throwIfNull(dynamic thing) {
  if (thing == null) {
    throw StateError('A variable could not be null and yet it was.');
  } else {
    return thing;
  }
}
