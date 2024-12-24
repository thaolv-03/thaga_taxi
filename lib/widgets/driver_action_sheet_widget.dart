import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class DriverActionSheet extends StatelessWidget {
  final double initialChildSize;
  final String? userId;
  final Function onArrived;

  DriverActionSheet({
    required this.initialChildSize,
    required this.userId,
    required this.onArrived,
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
                    'Đang trên đường đón',
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundImage: customerData['image'] !=
                                            null
                                        ? NetworkImage(customerData['image'])
                                        : AssetImage('assets/person.png')
                                            as ImageProvider, // URL hoặc ảnh mặc định
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                              GestureDetector(
                                onTap: () async {
                                  onArrived();
                                },
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.green,
                                  child: Icon(Icons.check_outlined,
                                      size: 40, color: AppColors.whiteColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Divider(thickness: 1, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildActionButton(
                              Icons.call_outlined,
                              'Gọi điện',
                              () {
                                // Gọi điện
                              },
                            ),
                            _buildActionButton(
                              Icons.message_outlined,
                              'Nhắn tin',
                              () {
                                // Nhắn tin
                              },
                            ),
                            _buildActionButton(
                              Icons.close,
                              'Hủy chuyến',
                              () {
                                // Hủy chuyến
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
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

  Widget _buildActionButton(
      IconData icon, String label, VoidCallback onPressed) {
    return Column(
      children: [
        GestureDetector(
          onTap: onPressed,
          child: CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.blueColor,
            child: Icon(icon, size: 32, color: AppColors.whiteColor),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
