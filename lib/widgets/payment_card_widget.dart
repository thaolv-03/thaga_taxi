import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget buildPaymentCardWidget() {
  return Container(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkWell(
          onTap: () {
            // Thêm logic khi nhấn nút ở đây
            print('Button pressed!');
          },
          splashColor: Colors.grey.withOpacity(0.3), // Màu hiệu ứng khi nhấn
          highlightColor: Colors.grey.withOpacity(0.1), // Màu sáng khi giữ nút
          borderRadius: BorderRadius.circular(8), // Định hình hiệu ứng
          child: Row(
            children: [
              Image.asset(
                'assets/cash_blue.png',
                width: 30,
              ),
              SizedBox(
                width: 10,
              ),
              Text(
                'Tiền mặt',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(
                width: 5,
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.black,
                size: 30,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
