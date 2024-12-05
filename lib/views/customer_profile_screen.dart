import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:thaga_taxi/controller/auth_controller.dart';
import 'package:thaga_taxi/utils/app_colors.dart';
import 'package:thaga_taxi/views/home_screen.dart';
import 'package:thaga_taxi/views/login_screen.dart';
import 'package:thaga_taxi/widgets/thaga_intro_widget.dart';

class CustomerProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Obx(() {
      final user = authController.userData;
      // authController.fetchUserData();
      User? userr = FirebaseAuth.instance.currentUser;
      String phoneNumber = userr?.phoneNumber ?? 'Không có số điện thoại';

      if (user.isEmpty) {
        return Center(child: Text('Không tìm thấy thông tin người dùng'));
      }

      String avatarUrl = user['image'];
      String name = user['name'];
      print("phone ${phoneNumber}");
      String email = user['email'];
      String home = user['home'];
      String job = user['job'];
      String company = user['company'];

      return Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Background and Avatar
              Container(
                height: Get.height * 0.44,
                // color: Color(0xFF007BFF),
                child: Stack(
                  children: [
                    thagaIntroWidgetWithoutLogos("Hồ sơ khách hàng", ""),
                    Positioned(
                      top: 80,
                      left: 30,
                      child: InkWell(
                        onTap: () {
                          Get.off(() => HomeScreen());
                        },
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          // width: Get.width,
                          child: Container(
                            width: 120,
                            height: 120,
                            margin: EdgeInsets.only(bottom: 70),
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: avatarUrl.isNotEmpty
                                    ? NetworkImage(avatarUrl)
                                    : AssetImage('assets/person.png')
                                        as ImageProvider,
                                fit: BoxFit.fill,
                              ),
                              shape: BoxShape.circle,
                              color: Color.fromARGB(255, 255, 255, 255),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  spreadRadius: 3,
                                  blurRadius: 3,
                                )
                              ],
                            ),
                          ),
                        )),
                    Align(
                      child: Container(
                        width: Get.width,
                        // color: Colors.black,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Khách hàng',
                              style: GoogleFonts.inter(
                                // color: Colors.white.withOpacity(0.8),
                                color: AppColors.blackColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              name,
                              style: GoogleFonts.inter(
                                color: AppColors.blueColor,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Details Section
              Container(
                padding: EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                child: Column(
                  children: [
                    buildProfileItem(
                        'Số điện thoại', phoneNumber.replaceFirst('+84', '0')),
                    buildProfileItem('Email', email),
                    buildProfileItem('Địa chỉ', home),
                    buildProfileItem('Công việc', job),
                    buildProfileItem('Công ty', company),
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () async {
                        await AuthController().signOut();
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blueColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Đăng xuất',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget buildProfileItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$title',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black.withOpacity(0.6),
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.blueColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.left,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
