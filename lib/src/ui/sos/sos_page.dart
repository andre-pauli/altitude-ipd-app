import 'package:altitude_ipd_app/src/ui/sos/call_page.dart';
import 'package:flutter/material.dart';

class SosPage extends StatelessWidget {
  const SosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CallPage(),
                ),
              );
            },
            child: const Text('Chamar suporte'))
      ],
    ));
  }
}
