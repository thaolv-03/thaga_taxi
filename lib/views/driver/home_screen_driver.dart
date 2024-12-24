// import 'package:flutter/material.dart';
//
// class HomeScreenDriver extends StatefulWidget {
//   const HomeScreenDriver({super.key});
//
//   @override
//   State<HomeScreenDriver> createState() => _HomeScreenDriverState();
// }
//
// class _HomeScreenDriverState extends State<HomeScreenDriver> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           Text('Home Screen Driver'),
//         ],
//       ),
//     );
//   }
// }

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/routing.dart';
import 'package:here_sdk/search.dart';
import 'package:thaga_taxi/controller/booking_controller.dart';
import 'package:thaga_taxi/utils/app_colors.dart';
import 'dart:ui' as ui;
import 'package:geolocator/geolocator.dart';
import 'package:thaga_taxi/views/login_screen.dart';
import 'package:thaga_taxi/widgets/current_location_icon_widget.dart';
import 'package:thaga_taxi/widgets/driver_action_sheet_widget.dart';
import 'package:thaga_taxi/widgets/driver_moved_sheet_widget.dart';
import 'package:thaga_taxi/widgets/driver_welcomed_sheet_widget.dart';
import 'package:thaga_taxi/widgets/notification_icon_widget.dart';

import '../../widgets/booking_confirm_sheet_widget.dart';
import '../../widgets/booking_wait_sheet_widget.dart';
import '../../widgets/drawer_widget.dart';
import '../../widgets/profile_title.dart';
import '../../widgets/route_summary_card_widget.dart';

class HomeScreenDriver extends StatefulWidget {
  const HomeScreenDriver({super.key});
  @override
  State<HomeScreenDriver> createState() => _HomeScreenDriverState();
}

class _HomeScreenDriverState extends State<HomeScreenDriver> {
  late HereMapController _hereMapController;
  late SearchEngine _searchEngine;
  Map<GeoCoordinates, MapMarker> _mapMarkers = {};
  MapMarker? _currentLocationMarker;
  String _title = "";
  double _sheetChildSize = 0.6;
  double _sheetRideConfirmChildSize = 0.37;
  double _bookingWaitSheetChildSize = 0.25;
  double _bookingConfirmSheetChildSize = 0.37;
  double _driverActionSheetChildSize = 0.37;
  double _driverWelcomedSheetChildSize = 0.37;
  double _driverMovedSheetChildSize = 0.37;
  // double _sheet
  bool showSourceField = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  MapPolyline? _currentRoutePolyline;
  GeoCoordinates? _sourceGeoCoordinates;
  GeoCoordinates? _destinationGeoCoordinates;
  GeoCoordinates? driverCurrentLocation;
  bool showRouteSummary = false;

  double pricePerKm4Seats = 14000; // 15k cho xe 4 chỗ
  double pricePerKm4SeatsHC = 16000; // 15k cho xe 4 chỗ cao cấp
  double pricePerKm7Seats = 18000; // 20k cho xe 7 chỗ
  double pricePerKm7SeatsHC = 20000; // 20k cho xe 7 chỗ cao cấp

  bool showBookingConfirmSheet = false;
  List<Booking> checkedBookingList = [];
  Booking? booking;

  GeoCoordinates? sourceCheckBooking;
  GeoCoordinates? destinationCheckBooking;

  bool showDriverActionSheet = false;
  bool showDriverWelcomedSheet = false;
  bool showDriverMovedSheet = false;

  String destinationAddressReverse = '';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _initializeSearchEngine();
    _moveToCurrentLocation();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _initializeSearchEngine() {
    try {
      _searchEngine = SearchEngine();
    } on InstantiationException catch (e) {
      print('Error initializing SearchEngine: $e');
    }
  }

  void _onMapCreated(HereMapController hereMapController) {
    _hereMapController = hereMapController;
    hereMapController.mapScene.loadSceneForMapScheme(MapScheme.logisticsDay,
        (error) {
      if (error != null) {
        print('Error loading map scene: $error');
        _hereMapController.mapScene.loadSceneForMapScheme(MapScheme.logisticsDay, (_) {});
        return;
      }
      const double distanceToEarthInMeters = 5000;
      final mapMeasureZoom =
          MapMeasure(MapMeasureKind.distance, distanceToEarthInMeters);
      hereMapController.camera.lookAtPointWithMeasure(
          GeoCoordinates(15.9790873, 108.2491083), mapMeasureZoom);

      // addRoute(_hereMapController, GeoCoordinates(15.9787446, 108.2494105),
      //     GeoCoordinates(16.0712851, 108.2290538));
    });
  }

  Future<String> _reverseGeocodeLocation(GeoCoordinates geoCoordinates) async {
    final reverseGeocodeOptions = SearchOptions()
      ..languageCode = LanguageCode.enUs
      ..maxItems = 1;

    final completer = Completer<String>();

    _searchEngine.searchByCoordinates(geoCoordinates, reverseGeocodeOptions,
        (error, places) {
      if (error != null) {
        print("Reverse geocoding error: $error");
        completer.complete("Unknown location"); // Trả về lỗi nếu có
      } else if (places != null && places.isNotEmpty) {
        completer
            .complete(places.first.address.addressText ?? "Unknown location");
      } else {
        completer.complete("Unknown location");
      }
    });

    return completer.future;
  }

  void _removeAllMarkers(HereMapController _hereMapController) {
    if (_mapMarkers.isNotEmpty) {
      _mapMarkers.forEach((key, marker) {
        _hereMapController.mapScene.removeMapMarker(marker);
      });
      _mapMarkers.clear(); // Xóa tất cả các Marker trong danh sách
    }
  }

  void addRoute(HereMapController _hereMapController, GeoCoordinates source,
      GeoCoordinates destination) async {
    // Xóa tất cả các Marker hiện tại
    _removeAllMarkers(_hereMapController);

    // Nếu có Polyline cũ, xóa nó
    if (_currentRoutePolyline != null) {
      print("Removing existing polyline: $_currentRoutePolyline");
      _hereMapController.mapScene.removeMapPolyline(_currentRoutePolyline!);
      _currentRoutePolyline = null; // Reset polyline cũ
    } else {
      print("No polyline to remove.");
    }

    RoutingEngine routingEngine = RoutingEngine();
    Waypoint sourceWaypoint = Waypoint.withDefaults(source);
    Waypoint destinationWaypoint = Waypoint.withDefaults(destination);
    List<Waypoint> wayPoints = [sourceWaypoint, destinationWaypoint];

    routingEngine.calculateCarRoute(
      wayPoints,
      CarOptions(
          avoidanceOptions: AvoidanceOptions(), routeOptions: RouteOptions()),
      (error, routing) {
        if (error == null) {
          var route = routing!.first;
          GeoPolyline geoPolyline = route.geometry;

          MapPolylineRepresentation representation =
              MapPolylineSolidRepresentation(
            MapMeasureDependentRenderSize.withSingleSize(
                RenderSizeUnit.pixels, 20),
            AppColors.blueColor,
            LineCap.round,
          );

          // Thêm Polyline mới
          _currentRoutePolyline =
              MapPolyline.withRepresentation(geoPolyline, representation);
          _hereMapController.mapScene.addMapPolyline(_currentRoutePolyline!);

          _zoomOutToShowRoute(_hereMapController, source, destination);
        }
      },
    );

    // Thêm Marker mới
    await _addMarkers(_hereMapController, source, destination);
  }

  void _zoomOutToShowRoute(HereMapController _hereMapController,
      GeoCoordinates source, GeoCoordinates destination) {
    // Tính toán các giá trị tọa độ của góc Đông Bắc và Tây Nam
    double minLatitude = source.latitude < destination.latitude
        ? source.latitude
        : destination.latitude;
    double maxLatitude = source.latitude > destination.latitude
        ? source.latitude
        : destination.latitude;
    double minLongitude = source.longitude < destination.longitude
        ? source.longitude
        : destination.longitude;
    double maxLongitude = source.longitude > destination.longitude
        ? source.longitude
        : destination.longitude;

    // Tính khoảng cách giữa hai điểm
    double latDiff = maxLatitude - minLatitude;
    double lonDiff = maxLongitude - minLongitude;

    // Tự động điều chỉnh padding dựa trên khoảng cách giữa hai điểm
    double dynamicPadding = (latDiff > lonDiff ? latDiff : lonDiff) * 0.5;

    // Thêm padding để zoom out rộng hơn
    GeoCoordinates northEast = GeoCoordinates(
      maxLatitude + dynamicPadding,
      maxLongitude + dynamicPadding,
    );
    GeoCoordinates southWest = GeoCoordinates(
      minLatitude - dynamicPadding,
      minLongitude - dynamicPadding,
    );

    // Dịch chuyển trung tâm xuống dưới (giảm giá trị latitude)
    double centerShift = latDiff * 1; // Tỷ lệ dịch chuyển dựa trên khoảng cách
    GeoCoordinates shiftedSouthWest =
        GeoCoordinates(southWest.latitude - centerShift, southWest.longitude);

    // Tạo GeoBox với các giá trị đã điều chỉnh
    GeoBox shiftedGeoBox = GeoBox(shiftedSouthWest, northEast);

    // Cập nhật camera tới GeoBox đã điều chỉnh
    const double defaultHeading = 0; // Camera nhìn về phía Bắc
    const double defaultTilt = 0; // Không nghiêng camera
    GeoOrientationUpdate orientationUpdate =
        GeoOrientationUpdate(defaultHeading, defaultTilt);

    // Điều chỉnh camera với GeoBox đã được dịch
    _hereMapController.camera
        .lookAtAreaWithGeoOrientation(shiftedGeoBox, orientationUpdate);
  }

  void _changeSheetSize(double size) {
    setState(() {
      _sheetChildSize = size;
    });
  }

  Future<void> _addMarkers(HereMapController _hereMapController,
      GeoCoordinates source, GeoCoordinates destination) async {
    // Tạo Marker cho điểm đến
    MapImage destinationMarkerImage = await _createDestinationMarkerImage();
    MapMarker destinationMarker =
        MapMarker(destination, destinationMarkerImage);
    _hereMapController.mapScene.addMapMarker(destinationMarker);
    _mapMarkers[destination] = destinationMarker; // Thêm vào Map

    // Tạo Marker cho điểm xuất phát
    MapImage sourceMarkerImage = await _createSourceMarkerImage();
    MapMarker sourceMarker = MapMarker(source, sourceMarkerImage);
    _hereMapController.mapScene.addMapMarker(sourceMarker);
    _mapMarkers[source] = sourceMarker; // Thêm vào Map
  }

  Future<GeoCoordinates> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (!serviceEnabled || permission == LocationPermission.denied) {
      // Yêu cầu quyền nếu chưa có quyền
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print("Location permission denied.");
    }

    // Lấy vị trí hiện tại
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
    // Di chuyển camera đến vị trí hiện tại
    GeoCoordinates currentLocation =
        GeoCoordinates(position.latitude, position.longitude);
    return currentLocation;
  }

  Future<void> _moveToCurrentLocation() async {
    // Kiểm tra quyền truy cập vị trí
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (!serviceEnabled || permission == LocationPermission.denied) {
      // Yêu cầu quyền nếu chưa có quyền
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print("Location permission denied.");
      return;
    }

    // Lấy vị trí hiện tại
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );

    const double offsetInDegrees = 0.001;
    // Di chuyển camera đến vị trí hiện tại
    GeoCoordinates currentLocation =
        GeoCoordinates(position.latitude, position.longitude);

    GeoCoordinates adjustedCurrentLocation =
        GeoCoordinates(position.latitude - offsetInDegrees, position.longitude);

    // Chuyển đổi tọa độ thành địa chỉ bằng Here Maps ReverseGeocoding
    try {
      String address = await _reverseGeocodeLocation(currentLocation);
      print("Current location address: $address");
      setState(() {
        // Gán địa chỉ vào trạng thái nếu cần
        // currentAddress = address;
      });
    } catch (e) {
      print("Failed to fetch address: $e");
    }

    _hereMapController.camera.lookAtPoint(adjustedCurrentLocation);
    const double distanceToEarthInMeters = 800; // Khoảng cách zoom
    MapMeasure mapMeasureZoom =
        MapMeasure(MapMeasureKind.distance, distanceToEarthInMeters);

    _hereMapController.camera
        .lookAtPointWithMeasure(adjustedCurrentLocation, mapMeasureZoom);

    if (_currentLocationMarker != null) {
      print("Current location marker already exists. Only moving camera.");
      return;
    }

    // Thêm marker vị trí hiện tại nếu chưa tồn tại
    final mapImage = await _createCurrentLocationMarkerImage();
    _currentLocationMarker = MapMarker(currentLocation, mapImage);
    _hereMapController.mapScene.addMapMarker(_currentLocationMarker!);

    // Xóa các marker tìm kiếm khác
    _mapMarkers.forEach((geoCoordinates, mapMarker) {
      _hereMapController.mapScene.removeMapMarker(mapMarker);
    });

    setState(() {
      // _sourceGeoCoordinates = currentLocation;
    });

    _mapMarkers.clear();
  }

  Future<MapImage> _createDestinationMarkerImage(
      {int width = 50, int height = 75}) async {
    ByteData imageData = await rootBundle.load('assets/marker.png');
    ui.Codec codec = await ui.instantiateImageCodec(
      imageData.buffer.asUint8List(),
      targetWidth: width,
      targetHeight: height,
    );
    ui.FrameInfo frameInfo = await codec.getNextFrame();
    ByteData resizedImageData = await frameInfo.image
        .toByteData(format: ui.ImageByteFormat.png) as ByteData;

    return MapImage.withPixelDataAndImageFormat(
      resizedImageData.buffer.asUint8List(),
      ImageFormat.png,
    );
  }

  Future<MapImage> _createSourceMarkerImage(
      {int width = 75, int height = 75}) async {
    ByteData imageData = await rootBundle.load('assets/pin_marker.png');
    ui.Codec codec = await ui.instantiateImageCodec(
      imageData.buffer.asUint8List(),
      targetWidth: width,
      targetHeight: height,
    );
    ui.FrameInfo frameInfo = await codec.getNextFrame();
    ByteData resizedImageData = await frameInfo.image
        .toByteData(format: ui.ImageByteFormat.png) as ByteData;

    return MapImage.withPixelDataAndImageFormat(
      resizedImageData.buffer.asUint8List(),
      ImageFormat.png,
    );
  }

  Future<MapImage> _createCurrentLocationMarkerImage(
      {int width = 100, int height = 100}) async {
    // Tải hình ảnh marker_current.png từ tài nguyên
    ByteData imageData = await rootBundle.load('assets/marker_current.png');
    ui.Codec codec = await ui.instantiateImageCodec(
      imageData.buffer.asUint8List(),
      targetWidth: width,
      targetHeight: height,
    );
    ui.FrameInfo frameInfo = await codec.getNextFrame();
    ByteData resizedImageData = await frameInfo.image
        .toByteData(format: ui.ImageByteFormat.png) as ByteData;

    // Tạo MapImage từ hình ảnh đã chỉnh sửa
    return MapImage.withPixelDataAndImageFormat(
      resizedImageData.buffer.asUint8List(),
      ImageFormat.png,
    );
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: DrawerWidget(),
      body: Stack(
        children: [
          Positioned(
            top: 130,
            left: 0,
            right: 0,
            bottom: 0,
            child: HereMap(
              onMapCreated: _onMapCreated,
            ),
          ),
          BookingWaitSheet(
            bookingWaitSheetChildSize: _bookingWaitSheetChildSize,
            buildNotificationIcon: buildNotificationIcon(),
            buildCurrentLocationIcon:
                buildCurrentLocationIcon(_moveToCurrentLocation),
            updateBookingConfirmSheetState: (bool isBookingConfirmVisible) {
              setState(
                () {
                  showBookingConfirmSheet = isBookingConfirmVisible;
                },
              );
            },
            updateShowRouteSummaryState: (bool isRouteSummaryVisible) {
              setState(
                () {
                  showRouteSummary = isRouteSummaryVisible;
                },
              );
            },
            checkedBooking:
                (List<Booking> checkedBooking, GeoCoordinates currentLocation) {
              setState(
                () {
                  checkedBookingList = checkedBooking;
                  if (checkedBookingList.isNotEmpty) {
                    sourceCheckBooking = GeoCoordinates(
                      checkedBookingList.first.source.latitude,
                      checkedBookingList.first.source.longitude,
                    );
                    destinationCheckBooking = GeoCoordinates(
                      checkedBookingList.first.destination.latitude,
                      checkedBookingList.first.destination.longitude,
                    );
                  }
                  driverCurrentLocation = currentLocation;
                  print('driverCurrentLocation: ${driverCurrentLocation}');
                },
              );
            },
          ),
          if (showBookingConfirmSheet)
            BookingConfirmSheet(
              initialChildSize: _bookingConfirmSheetChildSize,
              checkedBooking: checkedBookingList,
              onCheckedBooking: () {
                if (checkedBookingList.first.source != null &&
                    checkedBookingList.first.destination != null) {
                  addRoute(
                    _hereMapController,
                    GeoCoordinates(checkedBookingList.first.source.latitude,
                        checkedBookingList.first.source.longitude),
                    GeoCoordinates(
                        checkedBookingList.first.destination.latitude,
                        checkedBookingList.first.destination.longitude),
                  );
                }
              },
              onAcceptBooking: (Booking bookingOnAccept) {
                if (driverCurrentLocation != null) {
                  setState(() {
                    booking = bookingOnAccept;
                    showDriverActionSheet = true;
                    showRouteSummary = true;
                  });

                  _removeAllMarkers(_hereMapController);

                  if (_currentRoutePolyline != null) {
                    _hereMapController.mapScene
                        .removeMapPolyline(_currentRoutePolyline!);
                    _currentRoutePolyline = null; // Reset polyline cũ
                  } else {
                    print("No existing polyline to remove.");
                  }

                  addRoute(
                    _hereMapController,
                    driverCurrentLocation!,
                    GeoCoordinates(
                      bookingOnAccept.source.latitude,
                      bookingOnAccept.source.longitude,
                    ),
                  );
                } else {
                  Get.snackbar(
                    'Lỗi',
                    'Không thể thêm tuyến đường. Kiểm tra thông tin chuyến xe.',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              },
            ),
          if (showDriverActionSheet)
            DriverActionSheet(
              initialChildSize: _driverActionSheetChildSize,
              userId: booking!.uid,
              onArrived: () async {
                // Thêm trường isArrived (user lắng nghe nếu = true thì đổi title)
                await FirebaseFirestore.instance
                    .collection('bookings') // Tên collection của bạn
                    .doc(booking!.id) // ID của booking đầu tiên
                    .update({'isArrived': true});

                addRoute(
                  _hereMapController,
                  GeoCoordinates(
                    booking!.source.latitude,
                    booking!.source.longitude,
                  ),
                  GeoCoordinates(
                    booking!.destination.latitude,
                    booking!.destination.longitude,
                  ),
                );

                setState(() {
                  showRouteSummary = true;
                  showDriverWelcomedSheet = true;
                  showDriverActionSheet = false;
                });
              },
            ),
          if (showDriverWelcomedSheet)
            FutureBuilder(
              future: _reverseGeocodeLocation(
                GeoCoordinates(
                  booking!.destination.latitude,
                  booking!.destination.longitude,
                ),
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                if (snapshot.hasError) {
                  return Text("Error loading address");
                }

                if (snapshot.hasData) {
                  final destinationAddressReversed = snapshot.data as String;

                  return DriverWelcomedSheet(
                    initialChildSize: _driverWelcomedSheetChildSize,
                    userId: booking!.uid,
                    destinationAddress: destinationAddressReversed,
                    onStart: () async {
                      await FirebaseFirestore.instance
                          .collection('bookings') // Tên collection của bạn
                          .doc(booking!.id) // ID của booking đầu tiên
                          .update(
                              {'isMoved': true, 'startTime': Timestamp.now()});

                      setState(() {
                        showDriverMovedSheet = true;
                        showDriverWelcomedSheet = false;
                        showRouteSummary = true;
                      });
                    },
                  );
                }

                return Text("No address available");
              },
            ),
          if (showDriverMovedSheet)
            FutureBuilder(
              future: _reverseGeocodeLocation(
                GeoCoordinates(
                  booking!.destination.latitude,
                  booking!.destination.longitude,
                ),
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                if (snapshot.hasError) {
                  return Text("Error loading address");
                }

                if (snapshot.hasData) {
                  final destinationAddressReversed = snapshot.data as String;

                  return DriverMovedSheet(
                    initialChildSize: _driverMovedSheetChildSize,
                    userId: booking!.uid,
                    destinationAddress: destinationAddressReversed,
                    onFinish: () async {
                      await FirebaseFirestore.instance
                          .collection('bookings') // Tên collection của bạn
                          .doc(booking!.id) // ID của booking đầu tiên
                          .update(
                        {'isFinished': true, 'finishTime': Timestamp.now()},
                      );
                      setState(() {
                        _removeAllMarkers(_hereMapController);

                        if (_currentRoutePolyline != null) {
                          _hereMapController.mapScene
                              .removeMapPolyline(_currentRoutePolyline!);
                          _currentRoutePolyline = null; // Reset polyline cũ
                        } else {
                          print("No existing polyline to remove.");
                        }

                        _moveToCurrentLocation();
                        Get.offAll(() => HomeScreenDriver());

                        showDriverMovedSheet = false;
                      });
                    },
                    checkBooking: booking!,
                  );
                }

                return Text("No address available");
              },
            ),
          ProfileTitle(scaffoldKey: _scaffoldKey),
          if (showRouteSummary)
            Align(
              alignment: Alignment.topCenter,
              child: FutureBuilder(
                future: Future.wait([
                  _reverseGeocodeLocation(
                      sourceCheckBooking!), // Gọi trực tiếp hàm Future
                  _reverseGeocodeLocation(
                      destinationCheckBooking!), // Gọi trực tiếp hàm Future
                ]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  if (snapshot.hasError) {
                    return Text("Error loading addresses");
                  }

                  if (snapshot.hasData) {
                    final addresses = snapshot.data as List<String>;
                    final pickupAddress = addresses[0];
                    final destinationAddress = addresses[1];

                    return RouteSummaryCard(
                      pickupAddress: pickupAddress,
                      destinationAddress: destinationAddress,
                      onAddPressed: () {
                        print("Thêm điểm dừng");
                      },
                    );
                  }

                  return Text("No data available");
                },
              ),
            ),
        ],
      ),
    );
  }
}
