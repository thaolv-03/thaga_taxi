import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../utils/app_colors.dart';

List<Map<String, dynamic>> driverOptions = [];
int selectedRide = 0;

String formatCurrency(int amount) {
  int roundedAmount = (amount ~/ 1000) * 1000;

  final formatter = NumberFormat("#,###", "vi_VN");
  return "${formatter.format(roundedAmount)}đ";
}

Widget buildDriverList() {
  return Container(
    height: 90,
    width: Get.width,
    child: StatefulBuilder(
      builder: (context, set) {
        return ListView.builder(
          itemBuilder: (ctx, i) {
            return InkWell(
              onTap: () {
                set(() {
                  selectedRide = i;
                });
              },
              child: buildDriverCard(
                selected: selectedRide == i,
                title: driverOptions[i]['title'],
                price: driverOptions[i]['price'],
                seats: driverOptions[i]['seats'],
              ),
            );
          },
          itemCount: driverOptions.length,
          scrollDirection: Axis.horizontal,
        );
      },
    ),
  );
}

buildDriverCard(
    {required bool selected,
      required String title,
      required int price,
      required String seats}) {
  return Container(
    margin: EdgeInsets.only(right: 16, left: 0, top: 4, bottom: 4),
    height: 85,
    width: 165,
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: selected
              ? AppColors.blueColor.withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
          offset: Offset(0, 5),
          blurRadius: 5,
          spreadRadius: 1,
        ),
      ],
      borderRadius: BorderRadius.circular(12),
      color: selected ? AppColors.blueColor : Colors.grey,
    ),
    child: Stack(
      children: [
        Container(
          padding: EdgeInsets.only(left: 10, top: 10, bottom: 10, right: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(
                width: 10,
              ),
              Text(
                formatCurrency(price),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(
                width: 10,
              ),
              Text(
                seats,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: -20,
          top: 0,
          bottom: 0,
          child: Image.asset(
            'assets/car_image.png',
            width: 90,
          ),
        ),
      ],
    ),
  );
}