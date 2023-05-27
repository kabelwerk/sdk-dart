import 'package:flutter/material.dart';
import 'package:kabelwerk/kabelwerk.dart' as kabelwerk;
import 'package:provider/provider.dart';

import './auth.dart';
import './home_screen.dart';
import './kabelwerk_context.dart';
import './no_token_screen.dart';
import './room_screen.dart';

void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => Auth()),
      ChangeNotifierProxyProvider<Auth, KabelwerkContext>(
        create: (context) => KabelwerkContext(),
        update: (context, auth, kabelwerkContext) =>
            kabelwerkContext!..handleAuthChange(token: auth.token),
      ),
    ],
    child: const App(),
  ));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kabelwerk Demo',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      routes: {
        '/': (BuildContext context) => Consumer<KabelwerkContext>(
              builder: (context, kabelwerkContext, child) =>
                  kabelwerkContext.state == kabelwerk.ConnectionState.inactive
                      ? const NoTokenScreen()
                      : const HomeScreen(),
            ),
        '/no-token': (BuildContext context) => const NoTokenScreen(),
        '/home': (BuildContext context) => const HomeScreen(),
        '/room': (BuildContext context) => const RoomScreen(),
      },
      initialRoute: '/',
    );
  }
}
