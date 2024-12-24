import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:thaga_taxi/controller/booking_controller.dart';
import '../utils/app_colors.dart';

class DriverMovedSheet extends StatelessWidget {
  final double initialChildSize;
  final String? userId;
  final String? destinationAddress;
  final Function onFinish;
  final Booking checkBooking;

  DriverMovedSheet({
    required this.initialChildSize,
    required this.userId,
    this.destinationAddress,
    required this.onFinish,
    required this.checkBooking,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: initialChildSize,
      maxChildSize: initialChildSize,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          width: MediaQuery.of(context).size.width,
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
              const SizedBox(height: 5),
              Text(
                'Đang di chuyển tới điểm đến',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  children: [
                    const SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoItem(
                            Icons.paid,
                            formatCurrency(checkBooking.price),
                            'Số tiền',
                          ),
                          _buildInfoItem(
                            Icons.local_taxi,
                            '${checkBooking.seats} người',
                            'Loại xe',
                          ),
                          _buildInfoItem(
                            Icons.moving,
                            '${checkBooking.distance}km',
                            'Quãng đường',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text.rich(
                      TextSpan(
                        text: 'Điểm đến: ',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(
                            text: destinationAddress!,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.blueColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Center(
                      child: SizedBox(
                        width: Get.width, // Chiều rộng của nút
                        height: 50, // Chiều cao của nút
                        child: ElevatedButton(
                          onPressed: () async {
                            onFinish();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blueColor, // Màu nền
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25), // Bo góc
                            ),
                          ),
                          child: Text(
                            'Đã tới điểm đến',
                            style: GoogleFonts.inter(
                              color: Colors.white, // Màu chữ
                              fontWeight: FontWeight.bold, // Đậm chữ
                              fontSize: 16, // Kích thước chữ
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String formatCurrency(int amount) {
  int roundedAmount = (amount ~/ 1000) * 1000;
  final formatter = NumberFormat("#,###", "vi_VN");
  return "${formatter.format(roundedAmount)}đ";
}

Widget _buildInfoItem(IconData icon, String value, String label,
    {double width = 100}) {
  return SizedBox(
    width: width, // Đặt chiều rộng cho widget
    child: Column(
      children: [
        Icon(icon, size: 32, color: Colors.blue),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.center, // Canh giữa văn bản
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center, // Canh giữa văn bản
        ),
      ],
    ),
  );
}
