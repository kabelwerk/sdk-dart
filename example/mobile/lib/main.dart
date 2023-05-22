import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './auth.dart';

void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => Auth()),
    ],
    child: const App(),
  ));
}

class App extends StatelessWidget {
  const App({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kabelwerk Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blueGrey,
      ),
      routes: {
        '/': (BuildContext context) => Consumer<Auth>(
              builder: (context, auth, child) =>
                  auth.token == '' ? const NoTokenScreen() : const HomeScreen(),
            ),
        '/no-token': (BuildContext context) => const NoTokenScreen(),
        '/home': (BuildContext context) => const HomeScreen(),
      },
      initialRoute: '/',
    );
  }
}

//
// screens
//

class NoTokenScreen extends StatelessWidget {
  const NoTokenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kabelwerk Demo')),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "You have been disconnected.\n",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              "This could be either because your device is offline "
              "and no demo user could be generated for you, "
              "or because you have reset your user.\n",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              "Please use the button below to generate a new demo user.\n",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  _handleGenerateUserButtonPress(context);
                },
                child: const Text('Generate user'),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  void _handleGenerateUserButtonPress(BuildContext context) {
    Provider.of<Auth>(context, listen: false)
        .generateUser()
        .catchError((error) {
      final snackBar = SnackBar(
        content: Text(error.toString()),
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kabelwerk Demo')),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Welcome to Kabelwerk's React Native demo app!\n",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              "You are connected as {name}. "
              "This user has been automatically generated for you "
              "and will be persisted on the device for a few days "
              "— unless you reset it before that.\n",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              "Feel free to send messages, upload images, "
              "and find ways to break the app!\n",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Open a chat room'),
              ),
            ),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Open inbox'),
              ),
            ),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Provider.of<Auth>(context, listen: false).logout();
                },
                child: const Text('Reset user'),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
