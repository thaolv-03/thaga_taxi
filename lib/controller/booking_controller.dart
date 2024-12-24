import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:here_sdk/core.dart';

class BookingController extends GetxController {
  CollectionReference bookingCollection =
      FirebaseFirestore.instance.collection('bookings');

  CollectionReference saveBookingCollection =
  FirebaseFirestore.instance.collection('save_bookings');

  Future<String> booking(
    GeoCoordinates source,
    GeoCoordinates destination,
    String seats,
    String distance,
    int price,
    String uid,
    bool isArrived,
    bool isMoved,
    bool isFinished,
    Timestamp? startTime,
    Timestamp? finishTime,
    int? ratingStar,
  ) async {
    GeoPoint sourceGeo = GeoPoint(source.latitude, source.longitude);
    GeoPoint destinationGeo =
        GeoPoint(destination.latitude, destination.longitude);

    Booking booking = Booking(
      source: sourceGeo,
      destination: destinationGeo,
      seats: seats,
      distance: distance,
      price: price,
      uid: uid,
      isArrived: isArrived,
      isMoved: isMoved,
      isFinished: isFinished,
      startTime: startTime,
      finishTime: finishTime,
      ratingStar: ratingStar,
    );

    var newBook = await bookingCollection.add(booking.toJson());

    await newBook.update({'id': newBook.id});

    return newBook.id;
  }

  Future<String> saveBooking(
      Booking booking,
      ) async {

    var newBooking = await saveBookingCollection.add(booking.toJson());

    await newBooking.update({'id': newBooking.id});

    return newBooking.id;
  }

  Stream<Booking?> streamBooking(String id) {
    return FirebaseFirestore.instance
        .collection('bookings')
        .doc(id)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return Booking.fromJson(snapshot.data()! as Map<String, dynamic>);
      } else {
        return null;
      }
    });
  }

  Stream<List<Booking>> streamBookings() {
    return bookingCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Booking.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }
}

class Booking {
  String? id;
  GeoPoint source;
  GeoPoint destination;
  String? driverId;
  String seats;
  String distance;
  int price;
  String? uid;
  bool isArrived;
  bool isMoved;
  bool isFinished;
  Timestamp? startTime;
  Timestamp? finishTime;
  int? ratingStar;
  String? tripTime;
  String? tripComment;

  Booking({
    this.id,
    required this.source,
    required this.destination,
    this.driverId,
    required this.seats,
    required this.distance,
    required this.price,
    this.uid,
    this.isArrived = false,
    this.isMoved = false,
    this.isFinished = false,
    this.startTime,
    this.finishTime,
    this.ratingStar,
    this.tripTime,
    this.tripComment,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      source: json['source'],
      destination: json['destination'],
      driverId: json['driverId'],
      seats: json['seats'] ?? '0',
      distance: json['distance'] ?? '0.0',
      price: json['price'] ?? '0.0',
      uid: json['uid'],
      isArrived: json['isArrived'] ?? false,
      isMoved: json['isMoved'] ?? false,
      isFinished: json['isFinished'] ?? false,
      startTime: json['startTime'],
      finishTime: json['finishTime'],
      ratingStar: json['ratingStar'],
      tripTime: json['tripTime'],
      tripComment: json['tripComment'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source,
        'destination': destination,
        'driverId': driverId,
        'seats': seats,
        'distance': distance,
        'price': price,
        'uid': uid,
        'isArrived': isArrived,
        'isMoved': isMoved,
        'isFinished': isFinished,
        'startTime': startTime,
        'finishTime': finishTime,
        'ratingStar': ratingStar,
        'tripTime': tripTime,
        'tripComment': tripComment,
      };

  @override
  String toString() {
    return 'Booking{id: $id, source: $source, destination: $destination, driverId: $driverId, seats: $seats, distance: $distance, price: $price, uid: $uid, isArrived: $isArrived, isMoved: $isMoved, isFinished: $isFinished, startTime: $startTime, finishTime: $finishTime, ratingStar: $ratingStar, tripTime: $tripTime, tripComment: $tripComment}';
  }

  Booking copyWith({
    String? id,
    GeoPoint? source,
    GeoPoint? destination,
    String? driverId,
    String? seats,
    String? distance,
    int? price,
    String? uid,
    bool? isArrived,
    bool? isMoved,
    bool? isFinished,
    Timestamp? startTime,
    Timestamp? finishTime,
    int? ratingStar,
    String? tripTime,
    String? tripComment,
  }) {
    return Booking(
      id: id ?? this.id,
      source: source ?? this.source,
      destination: destination ?? this.destination,
      driverId: driverId ?? this.driverId,
      seats: seats ?? this.seats,
      distance: distance ?? this.distance,
      price: price ?? this.price,
      uid: uid ?? this.uid,
      isArrived: isArrived ?? this.isArrived,
      isMoved: isMoved ?? this.isMoved,
      isFinished: isFinished ?? this.isFinished,
      startTime: startTime ?? this.startTime,
      finishTime: finishTime ?? this.finishTime,
      ratingStar: ratingStar ?? this.ratingStar,
      tripTime: tripTime ?? this.tripTime,
      tripComment: tripComment ?? this.tripComment,
    );
  }
}
