import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:thaga_taxi/controller/booking_controller.dart';

void main() {
  setUp(() async {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
  });

  test('', () {
    var bookingController = BookingController();

    var bookingsStream = bookingController.streamBookings();
    bookingsStream.listen((data) {
      expect(data.length, greaterThan(0));
      print(data);
    },);
  });
}