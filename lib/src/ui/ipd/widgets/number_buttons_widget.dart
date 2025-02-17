import 'package:flutter/material.dart';

class NumbersButtonsWidget extends StatefulWidget {
  final Map<String, dynamic> andares;
  final double width;
  final double height;
  final Function(int) selectAndar;

  const NumbersButtonsWidget({
    super.key,
    required this.andares,
    required this.width,
    required this.height,
    required this.selectAndar,
  });

  @override
  State<NumbersButtonsWidget> createState() => _NumbersButtonsWidgetState();
}

class _NumbersButtonsWidgetState extends State<NumbersButtonsWidget> {
  int selectedButtonIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Wrap(
        spacing: 72 * widget.width,
        runSpacing: 40 * widget.height,
        children: List.generate(widget.andares.length, (index) {
          return GestureDetector(
            onTap: () {
              widget.selectAndar(index + 1);
              setState(() {
                selectedButtonIndex = index + 1;
              });
            },
            child: SizedBox(
              width: 218 * widget.width,
              height: 218 * widget.height,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  shape: BoxShape.circle,
                  border: (index + 1) != selectedButtonIndex
                      ? null
                      : Border.all(
                          //#1C75BC
                          color: const Color(0xFF1C75BC), // Cor da borda
                          width: 9.0, // Largura da borda
                        ),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.andares[(index + 1).toString()]['andar'].toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 122.24 * widget.width,
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
