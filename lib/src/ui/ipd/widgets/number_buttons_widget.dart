import 'package:flutter/material.dart';

class NumbersButtonsWidget extends StatelessWidget {
  final int numberOfButtons;
  final double width;
  final double height;
  final Function(int) goToAndar;

  const NumbersButtonsWidget({
    super.key,
    required this.numberOfButtons,
    required this.width,
    required this.height,
    required this.goToAndar
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Wrap(
        spacing: 72 * width,
        runSpacing: 40 * height,
        children: List.generate(numberOfButtons, (index) {
          return GestureDetector(
            onTap: (){
              goToAndar(index+1);
            },
            child: SizedBox(
              width: 218 * width,
              height: 218 * height,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '0${index + 1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 122.24 * width,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
