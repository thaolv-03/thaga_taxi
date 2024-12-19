import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thaga_taxi/widgets/text_widget.dart';

import '../utils/app_colors.dart';

Widget buildDraggableRideConfirmSheet(
  double _sheetRideConfirmChildSize,
  bool showRideConfirmSheet,
  Function buildDriverList,
  Function buildPaymentCardWidget,
  VoidCallback setStateCallback,
) {
  return DraggableScrollableSheet(
    initialChildSize: _sheetRideConfirmChildSize,
    minChildSize: _sheetRideConfirmChildSize,
    maxChildSize: _sheetRideConfirmChildSize,
    builder: (BuildContext context, ScrollController scrollController) {
      return Container(
        width: Get.width,
        height: Get.height * 0.4,
        // padding: EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 4,
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Text(
              'Lựa chọn xe',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      setStateCallback();
                    },
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.blueColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            spreadRadius: 4,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: AppColors.whiteColor,
                        size: 23,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quay lại chọn lộ trình',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  )
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.only(left: 20),
              child: Column(
                children: [
                  const SizedBox(
                    height: 5,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  buildDriverList(),
                  const SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Divider(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: buildPaymentCardWidget(),
                        ),
                        MaterialButton(
                          onPressed: () {},
                          child: textWidget(
                            text: 'Đặt xe',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          color: AppColors.blueColor,
                          shape: StadiumBorder(),
                          minWidth: 120,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: ListView(controller: scrollController)),
          ],
        ),
      );
    },
  );
}
