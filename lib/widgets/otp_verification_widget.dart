import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thaga_taxi/utils/app_constants.dart';
import 'package:thaga_taxi/widgets/pinput_widget.dart';
import 'package:thaga_taxi/widgets/text_widget.dart';

Widget otpVerificationWidget() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        textWidget(text: AppConstants.phoneVerification, fontSize: 14),
        textWidget(
            text: AppConstants.enterOtp,
            fontSize: 22,
            fontWeight: FontWeight.bold),
        const SizedBox(
          height: 40,
        ),
        Container(
          width: Get.width,
          height: 50,
          child: RoundedWithShadow(),
        ),
        const SizedBox(
          height: 40,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: RichText(
            textAlign: TextAlign.start,
            text: TextSpan(
                style: GoogleFonts.inter(color: Colors.black, fontSize: 12),
                children: [
                  TextSpan(
                    text: AppConstants.resendCode + " ",
                  ),
                  TextSpan(
                      text: "10 seconds",
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ]),
          ),
        )
      ],
    ),
  );
}
