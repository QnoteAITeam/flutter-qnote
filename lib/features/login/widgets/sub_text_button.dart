import 'package:flutter/material.dart';

class SubTextButton extends StatelessWidget {
  const SubTextButton({super.key, required this.text});

  final String text;
  @override
  Widget build(BuildContext context) {
    List<String> list = text.split(' ');

    List<TextSpan> content = [];
    for (int i = 0; i < list.length; i++) {
      content.add(
        TextSpan(
          text: list[i],
          style: TextStyle(
            color: Colors.black,
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.underline,
          ),
        ),
      );

      if (i + 1 != list.length)
        content.add(
          TextSpan(
            text: ' ',
            style: TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none,
            ),
          ),
        );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: RichText(text: TextSpan(children: content)),
    );
  }
}
