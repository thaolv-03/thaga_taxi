import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thaga_taxi/widgets/thaga_intro_widget.dart';

import '../home_screen_driver.dart';

class VerificaitonPendingScreen extends StatefulWidget {
  const VerificaitonPendingScreen({Key? key}) : super(key: key);

  @override
  State<VerificaitonPendingScreen> createState() =>
      _VerificaitonPendingScreenState();
}

class _VerificaitonPendingScreenState extends State<VerificaitonPendingScreen> {

  @override
  void initState() {
    super.initState();
  }

  // Hàm kiểm tra trạng thái verified từ Firestore
  Stream<DocumentSnapshot> getUserVerificationStatus() {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          thagaIntroWidgetWithoutLogos('Xác minh!', ''),
          const SizedBox(
            height: 20,
          ),
          Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: getUserVerificationStatus(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Có lỗi xảy ra.'),
                      );
                    }

                    if (!snapshot.hasData) {
                      return Center(
                        child: Text('Không có dữ liệu.'),
                      );
                    }

                    // Kiểm tra trường verified
                    bool isVerified = snapshot.data!['verified'] ?? false;

                    // Nếu đã xác minh, điều hướng đến HomeScreenDriver
                    if (isVerified) {
                      Future.delayed(Duration.zero, () {
                        Get.offAll(() => HomeScreenDriver());
                      });
                    }

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Đang chờ xác minh',
                          style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.black),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Text(
                          'Tài liệu của bạn vẫn đang chờ xác minh. \nKhi mọi thứ đã được xác minh, bạn sẽ bắt đầu nhận được chuyến đi. Vui lòng chờ đợi!',
                          style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Color(0xff7D7D7D)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              )),
          const SizedBox(
            height: 40,
          ),
        ],
      ),
    );
  }
}
