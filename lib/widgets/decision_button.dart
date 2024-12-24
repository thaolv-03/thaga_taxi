import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thaga_taxi/utils/app_colors.dart';

import '../utils/app_icons.dart';

Widget DecisionButton(
    String icon, String text, Function onPressed, double width,
    {double height = 50}) {
  return InkWell(
    onTap: () => onPressed(),
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              spreadRadius: 1,
            )
          ]),
      child: Row(
        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 65,
            height: height,
            decoration: BoxDecoration(
              color: AppColors.blueColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
            child: Center(child: Icon(
              getIconFromString(icon),
              color: AppColors.whiteColor,
              size: 27,
            ),),
          ),
          const SizedBox(
            width: 30,
          ),
          Text(
            text,
            style: GoogleFonts.inter(
              color: AppColors.blackColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
