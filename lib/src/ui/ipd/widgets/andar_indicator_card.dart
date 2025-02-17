import 'package:flutter/material.dart';

// ignore: must_be_immutable
class AndarIndicatorCard extends StatelessWidget {
  String andarAtual;
  String description;
  AndarIndicatorCard(
      {super.key, required this.andarAtual, required this.description});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double widthRatio = screenWidth / 1200;
    double heightRatio = screenHeight / 1920;

    return Container(
      width: 413 * widthRatio,
      height: 628 * heightRatio,
      padding: EdgeInsets.symmetric(vertical: 32.05 * heightRatio),
      decoration: BoxDecoration(
        color: const Color.fromARGB(08, 255, 255, 255),
        borderRadius: BorderRadius.circular(16.0 * widthRatio),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.08),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            description,
            style: TextStyle(
                color: Colors.white,
                fontSize: 42.73 * widthRatio,
                fontWeight: FontWeight.w500),
          ),
          Text(
            andarAtual,
            style: TextStyle(
              color: Colors.white,
              fontSize: 340 * heightRatio,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
