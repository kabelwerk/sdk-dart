import 'dart:convert' show json;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// The endpoint on Kabelwerk's demo backend for generating users.
const generateUserUrl = 'https://hubdemo.kabelwerk.io/api/demo-users';

class AuthContext extends ChangeNotifier {
  //
  // private variables
  //

  final _storage = const FlutterSecureStorage();

  //
  // public variables
  //

  String token = '';

  //
  // public methods
  //

  Future<void> load() async {
    final value = await _storage.read(key: 'auth_token');

    if (value == null) {
      token = '';
    } else {
      token = value;
      notifyListeners();
    }
  }

  Future<void> generateUser() async {
    final uri = Uri.parse(generateUserUrl);
    final response = await http.post(
      uri,
      headers: {'content-type': 'application/json'},
      body: json.encode({}),
    );

    if (response.statusCode != 201) {
      throw StateError('Could not generate a user!');
    }

    final payload = json.decode(response.body);

    token = payload['token'];
    await _storage.write(key: 'auth_token', value: token);

    notifyListeners();
  }

  Future<void> logout() async {
    token = '';
    await _storage.delete(key: 'auth_token');

    notifyListeners();
  }
}
