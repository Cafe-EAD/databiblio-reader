import 'package:flutter/material.dart';

class ParagraphText extends StatelessWidget {
  final String text;
  final int index;
  final Function(int) onParagraphDisplayed;

  const ParagraphText({
    Key? key,
    required this.text,
    required this.index,
    required this.onParagraphDisplayed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onParagraphDisplayed(index);
    });

    return Text(text);
  }
}
