import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:here_sdk/routing.dart';
import 'package:here_sdk/src/sdk/core/geo_coordinates.dart';
import 'package:intl/intl.dart';
import 'package:thaga_taxi/controller/booking_controller.dart';
import 'package:thaga_taxi/widgets/driver_list_widget.dart';
import 'package:thaga_taxi/widgets/text_widget.dart';

import '../utils/app_colors.dart';

Future<double> _calculateDistance(
    GeoCoordinates source, GeoCoordinates destination) async {
  // Tạo RoutingEngine để tính toán đường đi
  RoutingEngine routingEngine = RoutingEngine();

  // Tạo Waypoints từ tọa độ đầu và cuối
  Waypoint sourceWaypoint = Waypoint.withDefaults(source);
  Waypoint destinationWaypoint = Waypoint.withDefaults(destination);
  List<Waypoint> wayPoints = [sourceWaypoint, destinationWaypoint];

  double distanceInKm = 0.0;
  Completer<double> completer = Completer<double>();
  // Tính toán tuyến đường
  routingEngine.calculateCarRoute(
      wayPoints,
      CarOptions(
          avoidanceOptions: AvoidanceOptions(),
          routeOptions: RouteOptions()), (error, routing) {
    if (error == null) {
      var route = routing!.first;

      // Tính khoảng cách từ route
      distanceInKm = route.lengthInMeters / 1000; // Đổi từ mét sang km
      print(
          "Khoảng cách giữa hai điểm: ${distanceInKm.toStringAsFixed(2)} km");
      completer.complete(distanceInKm); // Trả về khoảng cách khi tính xong
    } else {
      print("Lỗi khi tính toán tuyến đường: $error");
      completer.completeError("Không thể tính khoảng cách");
    }
  });
  return completer.future; // Trả về khoảng cách
}

Widget buildDraggableDriverConfirmSheet(
  double _sheetDriverConfirmChildSize,
  bool showDriverConfirmSheet,
  bool showSearchDriverSheet,
  Function buildDriverList,
  Function buildPaymentCardWidget,
  VoidCallback setStateCallback, {
  required GeoCoordinates source,
  required GeoCoordinates destination,
  required Function(bool) updateSearchDriverSheetState,
  required Function(Booking, bool, String, bool, bool, bool) updateDriverInformationSheetState,
}) {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  _onConfirm() async {
    var bookingController = Get.find<BookingController>();
    final User? currentUser = _auth.currentUser; // Lấy người dùng hiện tại
    if (currentUser != null) {
      String uid = currentUser.uid;

      // Lấy thông tin từ driverOptions
      final selectedOption = driverOptions[selectedRide];
      final seats = selectedOption['seats'].toString().replaceAll(' người', '');
      final price = (((selectedOption['price']) ~/ 1000) * 1000);

      // Tính khoảng cách giữa source và destination
      double distance = await _calculateDistance(source, destination);

      bool isArrived = false;
      bool isMoved = false;
      bool isFinished = false;
      Timestamp? startTime;
      Timestamp? finishTime;
      int? ratingStar;

      String bookingId = await bookingController.booking(
          source,
          destination,
          seats,
          distance.toStringAsFixed(2), // Chuyển khoảng cách thành chuỗi
          price,
          uid,
          isArrived,
          isMoved,
          isFinished,
          startTime,
          finishTime,
          ratingStar,
      );

      print("Booking ID: $bookingId");

      var bookingStream = await bookingController.streamBooking(bookingId);
      bookingStream.listen(
            (data) {
          print(data?.driverId);
          if (data?.driverId == null) {
            updateSearchDriverSheetState(true);
          } else {
            updateSearchDriverSheetState(false);
            // update state để hiển thị UI thông tin của tài xế ở đây
            updateDriverInformationSheetState(data!, true, data!.driverId!, data!.isArrived, data!.isMoved, data!.isFinished);
          }

          if (data?.isArrived == true) {
            updateDriverInformationSheetState(data!, true, data!.driverId!, data!.isArrived, data!.isMoved, data!.isFinished);
          }

          if (data?.isMoved == true) {
            updateDriverInformationSheetState(data!, true, data!.driverId!, data!.isArrived, data!.isMoved, data!.isFinished);
          }

          if (data?.isFinished == true) {
            updateDriverInformationSheetState(data!, true, data!.driverId!, data!.isArrived, data!.isMoved, data!.isFinished);
          }
          print(data);
        },
      );
    }
  }

  return DraggableScrollableSheet(


    initialChildSize: _sheetDriverConfirmChildSize,
    minChildSize: _sheetDriverConfirmChildSize,
    maxChildSize: _sheetDriverConfirmChildSize,
    builder: (BuildContext context, ScrollController scrollController) {
      return Container(
        width: Get.width,
        height: Get.height * 0.4,
        // padding: EdgeInsets.only(left: 20),
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
            Text(
              'Lựa chọn xe',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      setStateCallback();
                    },
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.blueColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            spreadRadius: 4,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: AppColors.whiteColor,
                        size: 23,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quay lại chọn lộ trình',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  )
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.only(left: 20),
              child: Column(
                children: [
                  const SizedBox(
                    height: 5,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  buildDriverList(),
                  const SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Divider(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: buildPaymentCardWidget(),
                        ),
                        MaterialButton(
                          onPressed: _onConfirm,
                          child: textWidget(
                            text: 'Đặt xe',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          color: AppColors.blueColor,
                          shape: StadiumBorder(),
                          minWidth: 120,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: ListView(controller: scrollController)),
          ],
        ),
      );
    },
  );
}
