import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

Widget thagaIntroWidget() {
  return Container(
    width: Get.width,
    decoration: BoxDecoration(
        image: DecorationImage(
            image: AssetImage('assets/mask_4.png'), fit: BoxFit.cover)),
    height: Get.height * 0.6,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: 60,// Thêm khoảng cách từ cạnh trên
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20), // Khoảng cách từ bên trái
          child: SvgPicture.asset('assets/thaga_taxi_logo_n2.svg', width: 270),
        ),

        const SizedBox(
          height: 10,
        ),
      ],
    ),
  );
}

Widget thagaIntroWidgetWithoutLogos(String title, String? subtitle) {
  return Container(
    width: Get.width,
    decoration: BoxDecoration(
      image: DecorationImage(
        image: AssetImage('assets/mask_5.png'),
        fit: BoxFit.fill,
      ),
    ),
    height: Get.height * 0.3,
    child: Container(
      height: Get.height * 0.1,
      width: Get.width,
      margin: EdgeInsets.only(bottom: Get.height * 0.035, left: 90),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
        ],
      ),
    ),
  );
}
