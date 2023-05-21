import 'package:flutter/foundation.dart';

class Auth extends ChangeNotifier {
  String token = '';

  void generateUser() {
    token = 'token';
    notifyListeners();
  }

  void logout() {
    token = '';
    notifyListeners();
  }
}
