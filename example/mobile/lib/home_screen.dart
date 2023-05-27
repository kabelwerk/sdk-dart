import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './auth_context.dart';

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
                onPressed: () {
                  Navigator.pushNamed(context, '/room');
                },
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
                  Provider.of<AuthContext>(context, listen: false).logout();
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
