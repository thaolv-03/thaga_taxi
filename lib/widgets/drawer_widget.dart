import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thaga_taxi/views/driver/driver_profile_screen.dart';
import 'package:thaga_taxi/views/driver/driver_profile_setup.dart';
import '../controller/auth_controller.dart';
import '../utils/app_colors.dart';
import '../views/customer_profile_screen.dart';
import '../views/login_screen.dart';
import '../views/profile_setting.dart'; // Đảm bảo import đúng đường dẫn

class DrawerWidget extends StatelessWidget {
  const DrawerWidget({Key? key}) : super(key: key);

  Widget buildDrawerItem({
    required String title,
    required Function onPressed,
    Color color = Colors.black,
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w700,
    double height = 45,
    bool isVisible = false,
  }) {
    return SizedBox(
      height: height,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 0),
        minVerticalPadding: 5,
        onTap: () => onPressed(),
        title: Row(
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: fontSize,
                fontWeight: fontWeight,
                color: color,
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            isVisible
                ? CircleAvatar(
                    backgroundColor: AppColors.blueColor,
                    radius: 13,
                    child: Text(
                      '1',
                      style: GoogleFonts.inter(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

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
        bool isDriver = user['isDriver'] ?? false;

        return Drawer(
          backgroundColor: Colors.white,
          child: Column(
            children: [
              Container(
                height: 150,
                child: DrawerHeader(
                  padding: EdgeInsets.symmetric(horizontal: 25),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: profileImage.isNotEmpty
                                ? NetworkImage(profileImage)
                                : AssetImage('assets/person.png')
                                    as ImageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 15,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Chào buổi sáng, ',
                              style: GoogleFonts.inter(
                                  color: Colors.black.withOpacity(0.28),
                                  fontSize: 16),
                            ),
                            Text(
                              name,
                              style: GoogleFonts.inter(
                                color: AppColors.blueColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              (isDriver == true) ?
              Container(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    buildDrawerItem(
                      title: 'Thiết lập hồ sơ',
                      onPressed: () => Get.to(() => DriverProfileSetup()),
                    ),
                    buildDrawerItem(
                      title: 'Hồ sơ khách hàng',
                      onPressed: () => Get.to(() => DriverProfileScreen()),
                    ),
                    buildDrawerItem(
                      title: 'Lịch sử hoạt động',
                      onPressed: () => {},
                      isVisible: true,
                    ),
                    buildDrawerItem(
                      title: 'Chỉnh sửa thông tin xe',
                      onPressed: () => {},
                    ),
                    buildDrawerItem(
                      title: 'Cài đặt',
                      onPressed: () => {},
                    ),
                    buildDrawerItem(
                      title: 'Khóa tài khoản',
                      onPressed: () => {},
                    ),
                    buildDrawerItem(
                      title: 'Hỗ trợ',
                      onPressed: () => {},
                    ),
                    buildDrawerItem(
                      title: 'Đăng xuất',
                      onPressed: () async {
                        await authController.signOut();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ) : Container(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    buildDrawerItem(
                      title: 'Thiết lập hồ sơ',
                      onPressed: () => Get.to(() => ProfileSettingScreen()),
                    ),
                    buildDrawerItem(
                      title: 'Hồ sơ khách hàng',
                      onPressed: () => Get.to(() => CustomerProfileScreen()),
                    ),
                    buildDrawerItem(
                      title: 'Lịch sử thanh toán',
                      onPressed: () => {},
                    ),
                    buildDrawerItem(
                      title: 'Lịch sử di chuyển',
                      onPressed: () => {},
                      isVisible: true,
                    ),
                    buildDrawerItem(
                      title: 'Cài đặt',
                      onPressed: () => {},
                    ),
                    buildDrawerItem(
                      title: 'Hỗ trợ',
                      onPressed: () => {},
                    ),
                    buildDrawerItem(
                      title: 'Đăng xuất',
                      onPressed: () async {
                        await authController.signOut();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

