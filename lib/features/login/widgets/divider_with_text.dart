import 'package:flutter/material.dart';

class DividerWithText extends StatelessWidget {
  final String text;

  const DividerWithText({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(
          child: Divider(thickness: 1, color: Colors.grey, endIndent: 8),
        ),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontFamily: 'Inter',
          ),
        ),
        const Expanded(
          child: Divider(thickness: 1, color: Colors.grey, indent: 8),
        ),
      ],
    );
  }
}
