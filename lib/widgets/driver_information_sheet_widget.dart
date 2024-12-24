import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thaga_taxi/views/home_screen.dart';
import '../utils/app_colors.dart';
import '../views/trip_review_screen.dart';

class DriverInformationSheet extends StatelessWidget {
  final double initialChildSize;
  final String driverId;
  final bool isArrived;
  final bool isMoved;

  DriverInformationSheet({
    required this.initialChildSize,
    required this.driverId,
    required this.isArrived,
    required this.isMoved,
  });

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users') // Tên collection trong Firestore
          .doc(driverId) // ID của tài xế
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.blueColor,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Đã xảy ra lỗi khi tải dữ liệu tài xế.',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Text(
              'Không tìm thấy thông tin tài xế.',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          );
        }

        // Lấy dữ liệu tài xế từ snapshot
        var driverData = snapshot.data!.data() as Map<String, dynamic>;

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
                  const SizedBox(height: 5),
                  Text(
                    () {
                      if (isArrived && isMoved) {
                        return 'Tài xế đang chở bạn tới điểm đến';
                      } else if (isArrived) {
                        return 'Tài xế đã đón bạn';
                      } else {
                        return 'Tài xế đang trên đường đến đón bạn';
                      }
                    }(),
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
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: driverData['image'] != null
                                  ? NetworkImage(driverData['image'])
                                  : AssetImage('assets/driver_avatar.png')
                                      as ImageProvider, // URL hoặc ảnh mặc định
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  driverData['name'] ?? 'Không có tên',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  driverData['vehicle_number'] ??
                                      'Không có biển số',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    color: AppColors.blueColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            CircleAvatar(
                              backgroundColor: AppColors.blueColor,
                              radius: 24,
                              child: IconButton(
                                icon: const Icon(Icons.phone,
                                    color: Colors.white),
                                onPressed: () {
                                  // Gọi điện thoại
                                  // print("Calling ${driverData['phone']}");
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Divider(thickness: 1, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildInfoItem(
                                Icons.local_taxi,
                                driverData['vehicle_make'] ??
                                    'Không có dữ liệu',
                                'Hãng xe'),
                            _buildInfoItem(
                                Icons.car_repair,
                                driverData['vehicle_model'] ??
                                    'Không có dữ liệu',
                                'Mẫu xe'),
                            _buildInfoItem(
                                Icons.local_taxi,
                                driverData['vehicle_type'] + ' người' ??
                                    'Không có dữ liệu',
                                'Số chỗ'),
                            _buildInfoItem(
                                Icons.invert_colors,
                                driverData['vehicle_color'] ??
                                    'Không có dữ liệu',
                                'Màu xe'),
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
      },
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label,
      {double width = 80}) {
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
