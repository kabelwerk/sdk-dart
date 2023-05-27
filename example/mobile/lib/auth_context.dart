import 'dart:convert' show json;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// The endpoint on Kabelwerk's demo backend for generating users.
const generateUserUrl = 'https://hubdemo.kabelwerk.io/api/demo-users';

class AuthContext extends ChangeNotifier {
  //
  // public variables
  //

  String token = '';

  //
  // public methods
  //

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
    notifyListeners();
  }

  void logout() {
    token = '';
    notifyListeners();
  }
}
