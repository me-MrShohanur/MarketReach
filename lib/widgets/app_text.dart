import 'package:flutter/material.dart';

class AppText extends StatelessWidget {
  final String text;
  final double? size;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final Paint? background;
  final Color? backgroundColor;
  final double? letterSpacing;

  const AppText(
    this.text, {
    super.key,
    // required
    this.size,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.background,
    this.backgroundColor,
    this.letterSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontSize: size,
        fontWeight: fontWeight,
        color: color,
        background: background,
        backgroundColor: backgroundColor,
        letterSpacing: letterSpacing,
      ),
    );
  }
}
