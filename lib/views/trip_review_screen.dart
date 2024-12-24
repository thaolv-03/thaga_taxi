import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:thaga_taxi/controller/booking_controller.dart';
import 'package:thaga_taxi/widgets/rating_star_widget.dart';

import '../utils/app_colors.dart';
import '../widgets/thaga_intro_widget.dart';
import 'home_screen.dart';

class TripReviewScreen extends StatefulWidget {
  const TripReviewScreen(
      {super.key, required this.driverId, required this.checkBooking});

  final String driverId;
  final Booking checkBooking;

  @override
  State<TripReviewScreen> createState() => _TripReviewScreenState();
}

class _TripReviewScreenState extends State<TripReviewScreen> {
  final ValueNotifier<int> _ratingNotifier = ValueNotifier<int>(0); // Khởi tạo ValueNotifier
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users') // Tên collection trong Firestore
          .doc(widget.driverId) // ID của tài xế
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

        String calculateTripTime(Timestamp? startTime, Timestamp? finishTime) {
          // Chuyển đổi Timestamp sang DateTime
          DateTime arrivedDateTime = startTime!.toDate();
          DateTime finishDateTime = finishTime!.toDate();

          // Tính khoảng thời gian
          Duration duration = finishDateTime.difference(arrivedDateTime);

          // Chuyển đổi Duration thành chuỗi
          if (duration.inMinutes < 60) {
            return '${duration.inMinutes} phút';
          } else {
            int hours = duration.inHours;
            int minutes = duration.inMinutes % 60;
            return minutes > 0 ? '$hours giờ $minutes phút' : '$hours giờ';
          }
        }

// Sử dụng hàm trong widget
        String tripTime = calculateTripTime(
            widget.checkBooking.startTime, widget.checkBooking.finishTime);

        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  height: Get.height * 0.44,
                  child: Stack(
                    children: [
                      thagaIntroWidgetWithoutLogos("Đánh giá chuyến đi", ""),
                      Positioned(
                        top: 60,
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
                      Positioned(
                        top: 60,
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
                                  image: driverData.isNotEmpty
                                      ? NetworkImage(driverData['image'])
                                      : AssetImage('assets/person.png')
                                          as ImageProvider,
                                  fit: BoxFit.cover,
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
                                'Tài xế',
                                style: GoogleFonts.inter(
                                  // color: Colors.white.withOpacity(0.8),
                                  color: AppColors.blackColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                driverData['name'],
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

                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildInfoItem(
                              Icons.timer_outlined,
                              tripTime,
                              'Thời gian',
                            ),
                            _buildInfoItem(
                              Icons.paid_outlined,
                              formatCurrency(widget.checkBooking.price),
                              'Số tiền',
                            ),
                            _buildInfoItem(
                              Icons.moving,
                              '${widget.checkBooking.distance}km',
                              'Quãng đường',
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Chuyến đi của bạn thế nào?",
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 15),
                      ValueListenableBuilder<int>(
                        valueListenable: _ratingNotifier,
                        builder: (context, rating, child) {
                          return RatingStarWidget(ratingNotifier: _ratingNotifier);
                        },
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: _commentController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: "Bình luận bổ sung",
                          hintStyle: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black26,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Colors.blue), // Màu xanh cho viền
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Colors.blue, width: 2), // Viền khi focus
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                                color: Colors.blue), // Viền khi không focus
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Confirm Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    child: SizedBox(
                      width: Get.width, // Chiều rộng của nút
                      height: 50, // Chiều cao của nút
                      child: ElevatedButton(
                        onPressed: () async {
                          var bookingController = Get.find<BookingController>();
                          await FirebaseFirestore.instance
                              .collection('bookings') // Tên collection của bạn
                              .doc(widget
                                  .checkBooking.id) // ID của booking đầu tiên
                              .update({
                            'ratingStar': _ratingNotifier.value,
                            'tripComment': _commentController.text,
                            'tripTime': tripTime,
                          });

                          var saveBooking = widget.checkBooking.copyWith(
                            ratingStar: _ratingNotifier.value,
                            tripComment: _commentController.text,
                            tripTime: tripTime,
                          );

                          await bookingController.saveBooking(saveBooking);

                          // Xóa booking khỏi Firestore
                          await FirebaseFirestore.instance
                              .collection('bookings')
                              .doc(widget.checkBooking.id) // ID của booking
                              .delete();

                          Get.off(() => HomeScreen());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blueColor, // Màu nền
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25), // Bo góc
                          ),
                        ),
                        child: Text(
                          'Xác nhận',
                          style: GoogleFonts.inter(
                            color: Colors.white, // Màu chữ
                            fontWeight: FontWeight.bold, // Đậm chữ
                            fontSize: 16, // Kích thước chữ
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30),
              ],
            ),
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
