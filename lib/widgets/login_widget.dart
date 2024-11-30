import 'package:fl_country_code_picker/fl_country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thaga_taxi/utils/app_constants.dart';
import 'package:thaga_taxi/widgets/text_widget.dart';

Widget loginWidget(
    CountryCode countryCode, Function onCountryChange, Function onSubmit) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        textWidget(text: AppConstants.helloNiceToMeetYou, fontSize: 14),
        textWidget(
            text: AppConstants.getMovingWithThagaTaxi,
            fontSize: 22,
            fontWeight: FontWeight.bold),
        const SizedBox(
          height: 40,
        ),
        Container(
          width: double.infinity,
          height: 65,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 3,
                  blurRadius: 3)
            ],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: () => onCountryChange(),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Container(
                          child: countryCode.flagImage(),
                        ),
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      textWidget(text: countryCode.dialCode, fontSize: 13),
                      Icon(Icons.keyboard_arrow_down_rounded)
                    ],
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 55,
                color: Colors.black.withOpacity(0.2),
              ),
              Expanded(
                flex: 5,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: TextField(
                    onSubmitted: (String? input) => onSubmit(input),
                    decoration: InputDecoration(
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                      hintText: AppConstants.enterMobileNumber,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
        const SizedBox(
          height: 40,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
                style: GoogleFonts.inter(color: Colors.black, fontSize: 12),
                children: [
                  TextSpan(
                    text: AppConstants.byCreating + "\n",
                  ),
                  TextSpan(
                      text: AppConstants.termsOfService + " ",
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  TextSpan(
                    text: "và ",
                  ),
                  TextSpan(
                      text: AppConstants.privacyPolicy + " ",
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ]),
          ),
        )
      ],
    ),
  );
}
