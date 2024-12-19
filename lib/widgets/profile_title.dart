import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/auth_controller.dart';
import '../utils/app_colors.dart'; // Đảm bảo đường dẫn đúng

class ProfileTitle extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const ProfileTitle({Key? key, required this.scaffoldKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Obx(
      () {
        final user = authController.userData;

        if (user.isEmpty) {
          return Center(child: Text('Không tìm thấy thông tin người dùng'));
        }

        String name = user['name'] ?? 'Tên người dùng';
        String profileImage = user['image'] ?? '';

        return Positioned(
          top: 60,
          left: 20,
          right: 20,
          child: Container(
            width: Get.width,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    scaffoldKey.currentState?.openDrawer();
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: profileImage.isNotEmpty
                            ? NetworkImage(profileImage)
                            : AssetImage('assets/person.png') as ImageProvider,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 15,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          color: AppColors.blueColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Di chuyển cùng Thaga Taxi',
                        style: GoogleFonts.inter(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
