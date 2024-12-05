import 'package:flutter/material.dart';

class CustomDialog extends StatelessWidget {
  String title = '';
  String textContent = '';
  Function onPrimaryPressed = () {};
  Function onSecondaryPressed = () {};

  CustomDialog(
      {super.key,
      required this.title,
      required this.textContent,
      required this.onPrimaryPressed,
      required this.onSecondaryPressed});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              textContent,
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => onSecondaryPressed(),
          child: Text("Voltar"),
        ),
        TextButton(
          onPressed: () => onPrimaryPressed(),
          child: Text("Confirmar"),
        ),
      ],
    );
  }
}
