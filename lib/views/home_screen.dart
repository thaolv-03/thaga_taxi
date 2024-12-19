import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/routing.dart';
import 'package:here_sdk/search.dart';
import 'package:thaga_taxi/utils/app_colors.dart';
import 'dart:ui' as ui;
import 'package:geolocator/geolocator.dart';
import 'package:thaga_taxi/views/login_screen.dart';
import 'package:thaga_taxi/widgets/notification_icon_widget.dart';

import '../widgets/bottom_sheet_widget.dart';
import '../widgets/current_location_icon_widget.dart';
import '../widgets/drawer_widget.dart';
import '../widgets/driver_list_widget.dart';
import '../widgets/payment_card_widget.dart';
import '../widgets/profile_title.dart';
import '../widgets/ride_confirm_sheet_widget.dart';
import '../widgets/route_summary_card_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HereMapController _hereMapController;
  late SearchEngine _searchEngine;
  List<Suggestion> _suggestionsForSource = [];
  List<Suggestion> _suggestionsForDestination = [];
  Map<GeoCoordinates, MapMarker> _mapMarkers = {};
  MapMarker? _currentLocationMarker;
  final FocusNode sourceFocusNode = FocusNode();
  final FocusNode destinationFocusNode = FocusNode();
  TextEditingController sourceController = TextEditingController();
  TextEditingController destinationController = TextEditingController();
  String _title = "";
  String _sourceAddress = "Đang tải vị trí hiện tại...";
  String focusedField = "destination";
  double _sheetChildSize = 0.6;
  double _sheetRideConfirmChildSize = 0.37;
  bool showSourceField = true;
  bool isSourceFocused = false;
  bool isDestinationFocused = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _cameraUpdateTimer;
  MapPolyline? _currentRoutePolyline;
  GeoCoordinates? _sourceGeoCoordinates;
  GeoCoordinates? _destinationGeoCoordinates;
  bool showRouteSummary = false;

  double pricePerKm4Seats = 14000; // 15k cho xe 4 chỗ
  double pricePerKm4SeatsHC = 16000; // 15k cho xe 4 chỗ cao cấp
  double pricePerKm7Seats = 18000; // 20k cho xe 7 chỗ
  double pricePerKm7SeatsHC = 20000; // 20k cho xe 7 chỗ cao cấp

  bool showRideConfirmSheet = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();

    _title = "Điểm đến";

    Future.delayed(Duration.zero, () {
      FocusScope.of(context).requestFocus(destinationFocusNode);
    });
    _initializeSearchEngine();
    _moveToCurrentLocation();

    sourceFocusNode.addListener(() {
      setState(() {
        isSourceFocused = sourceFocusNode.hasFocus;
      });
    });
    destinationFocusNode.addListener(() {
      setState(() {
        isDestinationFocused = destinationFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    destinationFocusNode.dispose();
    destinationController.dispose();
    sourceFocusNode.dispose();
    sourceController.dispose();
    super.dispose();
  }

  void _initializeSearchEngine() {
    try {
      _searchEngine = SearchEngine();
    } on InstantiationException catch (e) {
      print('Error initializing SearchEngine: $e');
    }
  }

  void _getSuggestionsForSource(String query) {
    if (query.isEmpty) return;

    final centerGeoCoordinates = GeoCoordinates(15.9790873, 108.2491083);
    final queryArea = TextQueryArea.withCenter(centerGeoCoordinates);
    final searchOptions = SearchOptions()
      ..languageCode = LanguageCode.viVn
      ..maxItems = 5;

    _searchEngine
        .suggestByText(TextQuery.withArea(query, queryArea), searchOptions,
            (SearchError? error, List<Suggestion>? suggestions) {
      if (error != null) {
        print("Autosuggest Error: ${error.toString()}");
        return;
      }
      setState(() {
        _suggestionsForSource = suggestions ?? [];
      });
    });
  }

  void _getSuggestionsForDestination(String query) {
    if (query.isEmpty) return;

    final centerGeoCoordinates = GeoCoordinates(15.9790873, 108.2491083);
    final queryArea = TextQueryArea.withCenter(centerGeoCoordinates);
    final searchOptions = SearchOptions()
      ..languageCode = LanguageCode.viVn
      ..maxItems = 5;

    _searchEngine
        .suggestByText(TextQuery.withArea(query, queryArea), searchOptions,
            (SearchError? error, List<Suggestion>? suggestions) {
      if (error != null) {
        print("Autosuggest Error: ${error.toString()}");
        return;
      }
      setState(() {
        _suggestionsForDestination = suggestions ?? [];
      });
    });
  }

  void _handleSuggestionSourceTap(Suggestion suggestion) async {
    final place = suggestion.place;
    if (place != null) {
      final geoCoordinates = place.geoCoordinates;
      if (geoCoordinates != null) {
        _sourceGeoCoordinates = geoCoordinates;
        // Điều hướng camera tới tọa độ được chọn.
        // _hereMapController.camera.lookAtPoint(geoCoordinates);

        // Zoom vào địa điểm với mức độ gần hơn (khoảng cách camera gần hơn mặt đất)
        _cameraUpdateTimer = Timer(Duration(milliseconds: 500), () {
          const double offsetInDegrees = 0.0007;
          final adjustedGeoCoordinates = GeoCoordinates(
            geoCoordinates.latitude - offsetInDegrees,
            geoCoordinates.longitude,
          );

          _hereMapController.camera.lookAtPoint(adjustedGeoCoordinates);

          // Zoom vào địa điểm với mức độ gần hơn (khoảng cách camera gần hơn mặt đất)
          const double distanceToEarthInMeters = 500;
          MapMeasure mapMeasureZoom =
              MapMeasure(MapMeasureKind.distance, distanceToEarthInMeters);

          // Cập nhật lại camera sau khi di chuyển đến vị trí mới với mức zoom gần hơn
          _hereMapController.camera
              .lookAtPointWithMeasure(adjustedGeoCoordinates, mapMeasureZoom);
          // _animateCamera(adjustedGeoCoordinates, mapMeasureZoom);
        });
        // Xóa tất cả các marker trước đó (trừ marker vị trí hiện tại)
        _mapMarkers.forEach((key, marker) {
          _hereMapController.mapScene.removeMapMarker(marker);
        });
        _mapMarkers.clear();

        // Tạo marker mới từ asset
        final mapImage = await _createSourceMarkerImage();

        // Thêm marker mới tại vị trí tìm kiếm
        final mapMarker = MapMarker(geoCoordinates, mapImage);
        _hereMapController.mapScene.addMapMarker(mapMarker);

        // Lưu lại mapMarker và geoCoordinates
        _mapMarkers[geoCoordinates] = mapMarker;

        setState(() {
          _sourceAddress = suggestion.title;
          sourceController.text = suggestion.title;
          // _sheetChildSize = 0.37;
          _suggestionsForSource = []; // Xóa danh sách gợi ý sau khi chọn.
        });
        // FocusScope.of(context).unfocus();
      }
    }
  }

  void _handleSuggestionDestinationTap(Suggestion suggestion) async {
    // Hủy Timer cũ nếu đang chạy
    _cameraUpdateTimer?.cancel();

    final place = suggestion.place;
    if (place != null) {
      final geoCoordinates = place.geoCoordinates;
      if (geoCoordinates != null) {
        _destinationGeoCoordinates = geoCoordinates;

        // Khởi tạo Timer mới để chỉ cập nhật camera sau 500ms
        _cameraUpdateTimer = Timer(Duration(milliseconds: 500), () {
          const double offsetInDegrees = 0.0007;
          final adjustedGeoCoordinates = GeoCoordinates(
            geoCoordinates.latitude - offsetInDegrees,
            geoCoordinates.longitude,
          );

          _hereMapController.camera.lookAtPoint(adjustedGeoCoordinates);

          // Zoom vào địa điểm với mức độ gần hơn (khoảng cách camera gần hơn mặt đất)
          const double distanceToEarthInMeters = 500;
          MapMeasure mapMeasureZoom =
              MapMeasure(MapMeasureKind.distance, distanceToEarthInMeters);

          // Cập nhật lại camera sau khi di chuyển đến vị trí mới với mức zoom gần hơn
          _hereMapController.camera
              .lookAtPointWithMeasure(adjustedGeoCoordinates, mapMeasureZoom);
          // _animateCamera(adjustedGeoCoordinates, mapMeasureZoom);
        });
        // Xóa tất cả các marker trước đó (trừ marker vị trí hiện tại)
        _mapMarkers.forEach((key, marker) {
          _hereMapController.mapScene.removeMapMarker(marker);
        });
        _mapMarkers.clear();

        // Tạo marker mới từ asset
        final mapImage = await _createDestinationMarkerImage();

        // Thêm marker mới tại vị trí tìm kiếm
        final mapMarker = MapMarker(geoCoordinates, mapImage);
        _hereMapController.mapScene.addMapMarker(mapMarker);

        // Lưu lại mapMarker và geoCoordinates
        _mapMarkers[geoCoordinates] = mapMarker;

        setState(() {
          // _sourceAddress = suggestion.title;
          if (_sheetChildSize != 0.37) {
            _sheetChildSize = 0.37;
          }
          destinationController.text = suggestion.title;
          _suggestionsForDestination = []; // Xóa danh sách gợi ý sau khi chọn.
        });

        FocusScope.of(context).unfocus();
        _sheetChildSize = 0.37;
      }
    }
  }

  void _onMapCreated(HereMapController hereMapController) {
    _hereMapController = hereMapController;
    hereMapController.mapScene.loadSceneForMapScheme(MapScheme.logisticsDay,
        (error) {
      if (error != null) {
        print('Error loading map scene: $error');
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

  void _reverseGeocodeLocation(GeoCoordinates geoCoordinates) {
    final reverseGeocodeOptions = SearchOptions()
      ..languageCode = LanguageCode.enUs
      ..maxItems = 1;

    _searchEngine.searchByCoordinates(geoCoordinates, reverseGeocodeOptions,
        (error, places) {
      if (error != null) {
        print("Reverse geocoding error: $error");
        return;
      }

      if (places != null && places.isNotEmpty) {
        setState(() {
          sourceController.text = places.first.address.addressText;
        });
      }
    });
  }

  void _removeAllMarkers(HereMapController _hereMapController) {
    // Duyệt qua tất cả các marker và xóa chúng khỏi bản đồ
    _mapMarkers.forEach((key, marker) {
      _hereMapController.mapScene.removeMapMarker(marker);
    });
    _mapMarkers.clear(); // Xóa tất cả các marker trong map
  }

  void addRoute(HereMapController _hereMapController, GeoCoordinates source,
      GeoCoordinates destination) async {
    // Xóa tất cả các marker hiện tại
    _removeAllMarkers(_hereMapController);
    // Nếu có route cũ, xóa nó
    if (_currentRoutePolyline != null) {
      _hereMapController.mapScene.removeMapPolyline(_currentRoutePolyline!);
      _currentRoutePolyline = null; // Reset polyline cũ
    }

    RoutingEngine routingEngine = RoutingEngine();
    Waypoint sourceWaypoint = Waypoint.withDefaults(source);
    Waypoint destinationWaypoint = Waypoint.withDefaults(destination);
    List<Waypoint> wayPoints = [sourceWaypoint, destinationWaypoint];

    print("added Route");
    print("sourceWaypoint: ${sourceWaypoint}");
    print("destinationWaypoint: ${destinationWaypoint}");

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

          _currentRoutePolyline =
              MapPolyline.withRepresentation(geoPolyline, representation);
          _hereMapController.mapScene.addMapPolyline(_currentRoutePolyline!);

          _zoomOutToShowRoute(_hereMapController, source, destination);
        }
      },
    );

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
    // Tạo marker cho điểm đến
    MapImage destinationMarkerImage = await _createDestinationMarkerImage();
    MapMarker destinationMarker =
        MapMarker(destination, destinationMarkerImage);
    _hereMapController.mapScene.addMapMarker(destinationMarker);
    _mapMarkers[destination] = destinationMarker; // Thêm vào Map

    // Tạo marker cho điểm xuất phát
    MapImage sourceMarkerImage = await _createSourceMarkerImage();
    MapMarker sourceMarker = MapMarker(source, sourceMarkerImage);
    _hereMapController.mapScene.addMapMarker(sourceMarker);
    _mapMarkers[source] = sourceMarker; // Thêm vào Map
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
    _reverseGeocodeLocation(currentLocation);
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
      _sourceGeoCoordinates = currentLocation;
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

  Future<void> _loadDriverOptions(
      GeoCoordinates source, GeoCoordinates destination) async {
    double distance = await _calculateDistance(source, destination);

    setState(() {
      driverOptions = [
        {
          "title": "Nhanh chóng",
          "price": (distance * pricePerKm4Seats).toInt(),
          "seats": "4 người",
        },
        {
          "title": "Rộng rãi",
          "price": (distance * pricePerKm7Seats).toInt(),
          "seats": "7 người",
        },
        {
          "title": "Tiện lợi - Cao cấp",
          "price": (distance * pricePerKm4SeatsHC).toInt(),
          "seats": "4 người",
        },
        {
          "title": "Rộng rãi - Cao cấp",
          "price": (distance * pricePerKm7SeatsHC).toInt(),
          "seats": "7 người",
        }
      ];
    });
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
          DraggableBottomSheet(
            sheetChildSize: _sheetChildSize,
            title: _title,
            changeSheetSize: _changeSheetSize,
            sourceAddress: _sourceAddress,
            sourceFocusNode: sourceFocusNode,
            sourceController: sourceController,
            isSourceFocused: isSourceFocused,
            onSourceChanged: (value) {
              if (value.isEmpty) {
                setState(() {
                  _suggestionsForSource = [];
                });
              } else {
                _getSuggestionsForSource(value);
              }
            },
            onSourceSubmitted: () {
              setState(() {
                _changeSheetSize(0.37);
              });
            },
            onSourceTap: () {
              setState(() {
                sourceController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: sourceController.text.length,
                );
                _title = "Điểm đón";
                _changeSheetSize(0.6);
              });
            },
            suggestionsForSource: _suggestionsForSource,
            onSourceSuggestionTap: (Suggestion suggestion) {
              _handleSuggestionSourceTap(suggestion);
            },
            destinationFocusNode: destinationFocusNode,
            destinationController: destinationController,
            isDestinationFocused: isDestinationFocused,
            onDestinationChanged: (value) {
              if (value.isEmpty) {
                setState(() {
                  _suggestionsForDestination = [];
                });
              } else {
                _getSuggestionsForDestination(value);
              }
            },
            onDestinationSubmitted: () {
              setState(() {
                _changeSheetSize(0.37);
              });
            },
            onDestinationTap: () {
              setState(() {
                destinationController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: destinationController.text.length,
                );
                _title = "Điểm đến";
                _changeSheetSize(0.6);
              });
            },
            suggestionsForDestination: _suggestionsForDestination,
            onDestinationSuggestionTap: (Suggestion suggestion) {
              _handleSuggestionDestinationTap(suggestion);
            },
            onContinuePressed: () {
              FocusScope.of(context).unfocus();

              print(
                  "Điểm đón đã xác nhận: ${sourceController.text} - ${_sourceGeoCoordinates}");
              print(
                  "Điểm đến đã xác nhận: ${destinationController.text} - ${_destinationGeoCoordinates}");

              if (_sourceGeoCoordinates != null &&
                  _destinationGeoCoordinates != null) {
                addRoute(_hereMapController, _sourceGeoCoordinates!,
                    _destinationGeoCoordinates!);

                _loadDriverOptions(
                    _sourceGeoCoordinates!, _destinationGeoCoordinates!);

                setState(() {
                  _changeSheetSize(0.37);
                  showRouteSummary = true;
                  showRideConfirmSheet = true;
                });
              } else {
                print("Vui lòng chọn cả điểm đón và điểm đến!");
              }
            },
            moveToCurrentLocation: _moveToCurrentLocation,
            buildNotificationIcon: buildNotificationIcon(),
            buildCurrentLocationIcon:
                buildCurrentLocationIcon(_moveToCurrentLocation),
          ),
          if (showRideConfirmSheet)
            buildDraggableRideConfirmSheet(
              _sheetRideConfirmChildSize,
              showRideConfirmSheet,
              buildDriverList,
              buildPaymentCardWidget,
              () {
                setState(() {
                  showRideConfirmSheet = false;
                  showRouteSummary = false; // Update state in parent widget
                });
              },
            ),
          ProfileTitle(scaffoldKey: _scaffoldKey),
          Positioned(
            top: 140,
            left: 20,
            child: InkWell(
              onTap: () {
                Get.off(() => LoginScreen());
              },
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
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
                  color: AppColors.blueColor,
                  size: 26,
                ),
              ),
            ),
          ),
          if (showRouteSummary)
            Align(
              alignment: Alignment.topCenter,
              child: RouteSummaryCard(
                pickupAddress: sourceController.text,
                destinationAddress: destinationController.text,
                onAddPressed: () {
                  print("Thêm điểm dừng");
                },
              ),
            ),
        ],
      ),
    );
  }
}
