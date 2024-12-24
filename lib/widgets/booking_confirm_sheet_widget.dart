import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:thaga_taxi/controller/booking_controller.dart';

import '../controller/auth_controller.dart';

class BookingConfirmSheet extends StatelessWidget {
  final double initialChildSize;
  final List<dynamic> checkedBooking;
  final Function() onCheckedBooking;
  final Function(Booking) onAcceptBooking;

  BookingConfirmSheet({
    required this.initialChildSize,
    required this.checkedBooking,
    required this.onCheckedBooking, required this.onAcceptBooking,
  });

  @override
  Widget build(BuildContext context) {
    Booking checkedBookingFirstItem = checkedBooking.first;
    print('CHECKED BOOKING FIRST in BOOKING-CONFIRM-SHEET ${checkedBookingFirstItem}');

    onCheckedBooking();

    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: initialChildSize,
      maxChildSize: initialChildSize,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          width: Get.width,
          height: Get.height * 0.4,
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
              const SizedBox(
                height: 10,
              ),
              Text(
                'Chấp nhận chuyến xe',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              if (checkedBooking.isEmpty) {
                                Get.snackbar(
                                  'Lỗi',
                                  'Không có chuyến xe nào để cập nhật.',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                );
                                return;
                              }

                              // Lấy thông tin người dùng hiện tại
                              final User? currentUser = FirebaseAuth.instance.currentUser;

                              if (currentUser != null) {
                                String driverId = currentUser.uid;

                                var booking = checkedBooking.first;
                                // Cập nhật driverId vào Firebase
                                await FirebaseFirestore.instance
                                    .collection('bookings') // Tên collection của bạn
                                    .doc(booking.id) // ID của booking đầu tiên
                                    .update({'driverId': driverId});

                                // Hiển thị thông báo thành công
                                Get.snackbar(
                                  'Thành công',
                                  'Bạn đã chấp nhận chuyến xe.',
                                  snackPosition: SnackPosition.TOP,
                                  backgroundColor: Colors.green,
                                  colorText: Colors.white,
                                );

                                // Logic khác nếu cần
                                onAcceptBooking(booking);
                              } else {
                                // Nếu không tìm thấy người dùng hiện tại
                                Get.snackbar(
                                  'Lỗi',
                                  'Không thể lấy thông tin tài xế. Vui lòng đăng nhập lại.',
                                  snackPosition: SnackPosition.TOP,
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                );
                              }
                            } catch (e) {
                              // Hiển thị thông báo lỗi
                              print('Error: $e');
                              Get.snackbar(
                                'Lỗi',
                                'Không thể cập nhật chuyến xe. Vui lòng thử lại. Lỗi: $e',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Chấp nhận',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Xử lý logic từ chối ở đây
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Từ chối',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),

                  const SizedBox(height: 10),
                    Divider(thickness: 1, color: Colors.grey[300]),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoItem(
                          Icons.paid,
                          formatCurrency(checkedBookingFirstItem.price),
                          'Số tiền',
                        ),
                        _buildInfoItem(
                          Icons.local_taxi,
                          '${checkedBookingFirstItem.seats} người',
                          'Loại xe',
                        ),
                        _buildInfoItem(
                          Icons.moving,
                          '${checkedBookingFirstItem.distance}km',
                          'Quãng đường',
                        ),
                      ],
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
}
