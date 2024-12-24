import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class DriverWelcomedSheet extends StatelessWidget {
  final double initialChildSize;
  final String? userId;
  final String? destinationAddress;
  final Function onStart;

  DriverWelcomedSheet({
    required this.initialChildSize,
    required this.userId,
    this.destinationAddress,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users') // Tên collection trong Firestore
          .doc(userId) // ID của khách hàng
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
              'Đã xảy ra lỗi khi tải dữ liệu khách hàng.',
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
              'Không tìm thấy thông tin khách hàng.',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          );
        }

        // Lấy dữ liệu khách hàng từ snapshot
        var customerData = snapshot.data!.data() as Map<String, dynamic>;
        print('CUSTOMER DATA: ${customerData}');

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
                    'Đã đón khách hàng',
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
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundImage: customerData['image'] != null
                                    ? NetworkImage(customerData['image'])
                                    : AssetImage('assets/person.png')
                                        as ImageProvider, // URL hoặc ảnh mặc định
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customerData['name'] ?? 'Không có tên',
                                    style: GoogleFonts.inter(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    (customerData['phoneNumber'] as String)
                                            .replaceAll('+84', '0') ??
                                        'Không có số điện thoại',
                                    style: GoogleFonts.inter(
                                      fontSize: 20,
                                      color: AppColors.blueColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Text(
                        //   'Điểm đón: ${destinationAddress!}',
                        //   style: GoogleFonts.inter(
                        //     fontSize: 20,
                        //     color: AppColors.blueColor,
                        //     fontWeight: FontWeight.bold,
                        //   ),
                        // ),
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
                                onStart();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.blueColor, // Màu nền
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(25), // Bo góc
                                ),
                              ),
                              child: Text(
                                'Bắt đầu',
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
      },
    );
  }
}
