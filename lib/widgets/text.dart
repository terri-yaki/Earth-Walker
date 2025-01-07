import 'package:flutter/material.dart';
import '../utils/constants.dart'; // Assuming you have a constants file for styles

class customText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const customText({
    Key? key,
    required this.text,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return customText(
      text: text,
      style: style ?? AppTextStyles.defaultTextStyle,
      textAlign: textAlign ?? TextAlign.left,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
