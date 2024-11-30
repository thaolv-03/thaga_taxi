import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget textWidget(
    {required String text,
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.black}) {
  return Text(
    text,
    style: GoogleFonts.inter(
        fontSize: fontSize, fontWeight: fontWeight, color: color),
  );
}
