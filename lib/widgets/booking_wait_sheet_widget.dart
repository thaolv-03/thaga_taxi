import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/routing.dart';

import '../controller/auth_controller.dart';
import '../controller/booking_controller.dart';

class BookingWaitSheet extends StatefulWidget {
  final double bookingWaitSheetChildSize;
  final Widget buildNotificationIcon;
  final Widget buildCurrentLocationIcon;
  final Function(bool) updateBookingConfirmSheetState;
  final Function(bool) updateShowRouteSummaryState;
  final Function(List<Booking>, GeoCoordinates driverCurrentLocation) checkedBooking;

  const BookingWaitSheet({
    Key? key,
    required this.bookingWaitSheetChildSize,
    required this.buildNotificationIcon,
    required this.buildCurrentLocationIcon,
    required this.updateBookingConfirmSheetState,
    required this.updateShowRouteSummaryState,
    required this.checkedBooking,
  }) : super(key: key);

  @override
  State<BookingWaitSheet> createState() => _BookingWaitSheetState();
}

class _BookingWaitSheetState extends State<BookingWaitSheet> {
  final BookingController bookingController = BookingController();
  bool isCheckingBooking = false;
  final authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    checkBooking();
  }

  Future<double> _calculateDistance(GeoCoordinates driverCurrentLocation,
      GeoCoordinates customerSource) async {
    // Tạo RoutingEngine để tính toán đường đi
    RoutingEngine routingEngine = RoutingEngine();

    // Tạo Waypoints từ tọa độ đầu và cuối
    Waypoint driverCurrentLocationWaypoint =
        Waypoint.withDefaults(driverCurrentLocation);
    Waypoint customerSourceWaypoint = Waypoint.withDefaults(customerSource);
    List<Waypoint> wayPoints = [
      driverCurrentLocationWaypoint,
      customerSourceWaypoint
    ];

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

  Future<void> checkBooking() async {
    if (isCheckingBooking) return;
    setState(() {
      isCheckingBooking = true;
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services are disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print("Location permission denied.");
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      final user = authController.userData;
      print('USER DATA in CHECKBOOKING: ${user}');

      GeoCoordinates currentLocation =
          GeoCoordinates(position.latitude, position.longitude);

      String vehicleType = user['vehicle_type'];

      bookingController.streamBookings().listen(
        (data) async {
          // Lọc danh sách
          var filteredResult = data
              .where(
                (element) =>
                    (element.driverId == null) &&
                    (element.seats == vehicleType),
              )
              .toList();

          // Tính khoảng cách và sắp xếp
          List<Map<String, dynamic>> distancesWithBookings = await Future.wait(
            filteredResult.map((element) async {
              double distance = await _calculateDistance(
                currentLocation,
                GeoCoordinates(
                  element.source.latitude,
                  element.source.longitude,
                ),
              );
              return {'booking': element, 'distance': distance};
            }),
          );

          // Sắp xếp danh sách theo khoảng cách tăng dần
          distancesWithBookings.sort((a, b) {
            return a['distance'].compareTo(b['distance']);
          });

          // Chuyển đổi danh sách đã sắp xếp về dạng gốc
          var sortedResult =
              distancesWithBookings.map((e) => e['booking'] as Booking).toList();

          print('SORTED RESULT: $sortedResult');
          if (sortedResult.isNotEmpty) {
            widget.updateBookingConfirmSheetState(true);
            widget.updateShowRouteSummaryState(true);
            widget.checkedBooking(sortedResult, currentLocation);
          } else {
            widget.updateBookingConfirmSheetState(false);
            widget.updateShowRouteSummaryState(false);
            widget.checkedBooking([], currentLocation);
          }
        },
      );
    } catch (e) {
      print("Error while checking booking: $e");
    } finally {
      isCheckingBooking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: widget.bookingWaitSheetChildSize,
      minChildSize: widget.bookingWaitSheetChildSize,
      maxChildSize: widget.bookingWaitSheetChildSize,
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
                'Đang chờ khách hàng đặt xe',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Expanded(child: ListView(controller: scrollController)),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    widget.buildNotificationIcon,
                    widget.buildCurrentLocationIcon,
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
