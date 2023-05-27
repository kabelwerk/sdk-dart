import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import './auth.dart';

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
