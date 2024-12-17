import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/routing.dart';
import 'package:here_sdk/search.dart';
import 'package:thaga_taxi/controller/auth_controller.dart';
import 'package:thaga_taxi/utils/app_colors.dart';
import 'dart:ui' as ui;
import 'package:geolocator/geolocator.dart';
import 'package:thaga_taxi/views/customer_profile_screen.dart';
import 'package:thaga_taxi/views/login_screen.dart';
import 'package:thaga_taxi/views/profile_setting.dart';
import 'package:thaga_taxi/widgets/text_widget.dart';
import 'package:intl/intl.dart';

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
  String _title = ""; // Tiêu đề mặc định
  String _sourceAddress = "Đang tải vị trí hiện tại...";
  String focusedField = "destination";
  double _sheetChildSize = 0.6;
  double _sheetRideConfirmChildSize = 0.4;
  bool showSourceField = true;
  bool isSourceFocused = false;
  bool isDestinationFocused = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _cameraUpdateTimer;
  MapPolyline? _currentRoutePolyline;
  GeoCoordinates? _sourceGeoCoordinates;
  GeoCoordinates? _destinationGeoCoordinates;
  // List<String> list = <String>[
  //   '**** **** **** 8789',
  //   '**** **** **** 8921',
  //   '**** **** **** 1233',
  //   '**** **** **** 4352'
  // ];
  // String dropdownValue = '**** **** **** 8789';
  bool showRideConfirmSheet = false;

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

// Hàm thêm marker cho điểm xuất phát và điểm đến
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

  // Hàm zoom-out để hiển thị cả hai điểm
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: buildDrawer(),
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
          buildDraggableBottomSheet(),
          // Draggable BottomSheet thứ hai, chỉ hiển thị khi showRideConfirmSheet = true
          if (showRideConfirmSheet) buildDraggableRideConfirmSheet(),

          // buildDraggableBottomSheet(),
          buildProfileTile(),
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
        ],
      ),
    );
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

  Widget buildProfileTile() {
    final authController = Get.find<AuthController>();

    return Obx(
      () {
        final user = authController.userData;

        if (user.isEmpty) {
          return Center(child: Text('Không tìm thấy thông tin người dùng'));
        }

        String name = user['name'] ?? 'Tên người dùng';
        String profileImage = user['image'] ?? '';
        return Positioned(
          top: 60,
          left: 20,
          right: 20,
          child: Container(
            width: Get.width,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: profileImage.isNotEmpty
                            ? NetworkImage(
                                profileImage) // Sử dụng URL hình ảnh từ Firestore
                            : AssetImage('assets/person.png')
                                as ImageProvider, // Nếu không có ảnh thì dùng ảnh mặc định
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 15,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          color: AppColors.blueColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Tìm kiếm điểm đến...',
                        style: GoogleFonts.inter(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildTextFieldForSource() {
    return Column(
      children: [
        Container(
          width: Get.width,
          height: 50,
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 4,
                blurRadius: 10,
              ),
            ],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: focusedField == "source"
                  ? AppColors.blueColor // Viền màu xanh khi chọn
                  : Colors.transparent, // Không có viền khi không chọn
              width: 2,
            ),
          ),
          child: TextFormField(
            focusNode: sourceFocusNode,
            controller: sourceController,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (value) {
              setState(() {
                _changeSheetSize(0.37);
              });
            },
            onTap: () {
              setState(() {
                // Chọn toàn bộ văn bản khi nhấn vào
                sourceController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: sourceController.text.length,
                );
                focusedField = "source";
                _title = "Điểm đón";
                _changeSheetSize(0.6);
              });
            },
            onChanged: (value) {
              if (value.isEmpty) {
                setState(() {
                  _suggestionsForSource = [];
                });
              } else {
                _getSuggestionsForSource(value);
              }
            },
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 10, right: 10),
                child: Icon(
                  Icons.my_location,
                  color: AppColors.blueColor,
                ),
              ),
              suffixIcon: isSourceFocused && sourceController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          sourceController.clear();
                          _suggestionsForSource = [];
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              hintText: _sourceAddress,
              hintStyle: const TextStyle(color: Colors.black54),
            ),
          ),
        ),
        if (_suggestionsForSource.isNotEmpty)
          Container(
            width: Get.width,
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 4,
                  blurRadius: 10,
                ),
              ],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _suggestionsForSource.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestionsForSource[index];
                final address =
                    suggestion.place?.address.addressText ?? "Unknown";
                return ListTile(
                  title: Text(suggestion.title),
                  subtitle: Text(address),
                  onTap: () {
                    _handleSuggestionSourceTap(suggestion);
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget buildTextFieldForDestination() {
    return Column(
      children: [
        Container(
          width: Get.width,
          height: 50,
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 4,
                blurRadius: 10,
              ),
            ],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: focusedField == "destination"
                  ? AppColors.blueColor // Viền màu xanh khi chọn
                  : Colors.transparent, // Không có viền khi không chọn
              width: 2,
            ),
          ),
          child: TextFormField(
            focusNode: destinationFocusNode,
            controller: destinationController,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (value) {
              setState(() {
                _changeSheetSize(0.37);
              });
            },
            onTap: () {
              setState(() {
                destinationController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: destinationController.text.length,
                );
                focusedField = "destination";
                _title = "Điểm đến";
                _changeSheetSize(0.6);
              });
            },
            onChanged: (value) {
              // Kiểm tra nếu chuỗi trống và cập nhật danh sách gợi ý
              if (value.isEmpty) {
                setState(() {
                  _suggestionsForDestination =
                      []; // Xóa hết danh sách gợi ý khi không có văn bản
                });
              } else {
                // Gọi hàm tìm kiếm hoặc cập nhật gợi ý khi có văn bản
                _getSuggestionsForDestination(value);
              }
            },
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
            decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 10, right: 10),
                  child: Icon(
                    Icons.location_on,
                    color: AppColors.blueColor,
                  ),
                ),
                suffixIcon: isDestinationFocused &&
                        destinationController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            destinationController.clear();
                            _suggestionsForDestination = [];
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                hintText: 'Tìm kiếm điểm đến...',
                hintStyle: TextStyle(color: Colors.black54)),
          ),
        ),
        if (_suggestionsForDestination.isNotEmpty)
          Container(
            width: Get.width,
            constraints: BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 4,
                  blurRadius: 10,
                ),
              ],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _suggestionsForDestination.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestionsForDestination[index];
                final address =
                    suggestion.place?.address.addressText ?? "Unknown";
                return ListTile(
                  title: Text(suggestion.title),
                  subtitle: Text(address),
                  onTap: () {
                    _handleSuggestionDestinationTap(suggestion);
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  void _changeSheetSize(double size) {
    setState(() {
      _sheetChildSize = size;
    });
  }

  Widget buildDraggableBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: _sheetChildSize,
      // minChildSize: 0.37,
      minChildSize: _sheetChildSize,
      // maxChildSize: 0.75,
      maxChildSize: _sheetChildSize,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
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
              // Thanh kéo
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // Tiêu đề
              Text(
                _title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              // Nội dung trong BottomSheet
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    buildTextFieldForSource(),
                    buildTextFieldForDestination(),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () {
                        // Hành động xác nhận, có thể thực hiện lưu hoặc chuyển sang màn hình tiếp theo
                        print(
                            "Điểm đón đã xác nhận: ${sourceController.text} - ${_sourceGeoCoordinates}");
                        print(
                            "Điểm đến đã xác nhận: ${destinationController.text} - ${_destinationGeoCoordinates}");

                        if (_sourceGeoCoordinates != null &&
                            _destinationGeoCoordinates != null) {
                          // Gọi hàm addRoute và truyền các tọa độ
                          addRoute(_hereMapController, _sourceGeoCoordinates!,
                              _destinationGeoCoordinates!);

                          _loadDriverOptions(_sourceGeoCoordinates!,
                              _destinationGeoCoordinates!);

                          setState(() {
                            showRideConfirmSheet = true;
                          });
                        } else {
                          print("Vui lòng chọn cả điểm đón và điểm đến!");
                        }
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
                              'Tiếp tục',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Các icon ở dưới
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Notification Icon
                    Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.black12,
                        child: Icon(
                          Icons.notifications_on_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    // Current Location Icon
                    Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: InkWell(
                        onTap: _moveToCurrentLocation,
                        borderRadius: BorderRadius.circular(25),
                        splashColor: AppColors.blueColor.withOpacity(0.37),
                        highlightColor: AppColors.blueColor.withOpacity(0.2),
                        child: CircleAvatar(
                          radius: 25,
                          backgroundColor: AppColors.blueColor,
                          child: Icon(
                            Icons.my_location,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildCurrentLocationIcon() {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 270, right: 35),
        child: InkWell(
          onTap: _moveToCurrentLocation,
          borderRadius:
              BorderRadius.circular(25), // Đặt border radius cho hiệu ứng
          splashColor:
              AppColors.blueColor.withOpacity(0.37), // Màu hiệu ứng khi nhấn
          highlightColor:
              AppColors.blueColor.withOpacity(0.2), // Màu khi đang nhấn
          // Khi nhấn vào CircleAvatar, sẽ gọi hàm di chuyển
          child: CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.blueColor,
            child: Icon(
              Icons.my_location,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildNotificationIcon() {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 270, left: 35),
        child: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.white,
          child: Icon(
            Icons.notifications_on_outlined,
            color: Color(0xffC3CDD6),
            size: 28,
          ),
        ),
      ),
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

  String formatCurrency(int amount) {
    int roundedAmount = (amount ~/ 1000) * 1000;

    final formatter = NumberFormat("#,###", "vi_VN");
    return "${formatter.format(roundedAmount)}đ";
  }

  double pricePerKm4Seats = 14000; // 15k cho xe 4 chỗ
  double pricePerKm7Seats = 18000; // 20k cho xe 7 chỗ

  List<Map<String, dynamic>> driverOptions = [];

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
        }
      ];
    });
  }

  int selectedRide = 0;

  buildDriverList() {
    return Container(
      height: 90,
      width: Get.width,
      child: StatefulBuilder(
        builder: (context, set) {
          return ListView.builder(
            itemBuilder: (ctx, i) {
              return InkWell(
                onTap: () {
                  set(() {
                    selectedRide = i;
                  });
                },
                child: buildDriverCard(
                  selected: selectedRide == i,
                  title: driverOptions[i]['title'],
                  price: driverOptions[i]['price'],
                  seats: driverOptions[i]['seats'],
                ),
              );
            },
            itemCount: driverOptions.length,
            scrollDirection: Axis.horizontal,
          );
        },
      ),
    );
  }

  buildDriverCard(
      {required bool selected,
      required String title,
      required int price,
      required String seats}) {
    return Container(
      margin: EdgeInsets.only(right: 16, left: 0, top: 4, bottom: 4),
      height: 85,
      width: 165,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: selected
                ? AppColors.blueColor.withOpacity(0.2)
                : Colors.grey.withOpacity(0.2),
            offset: Offset(0, 5),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
        borderRadius: BorderRadius.circular(12),
        color: selected ? AppColors.blueColor : Colors.grey,
      ),
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.only(left: 10, top: 10, bottom: 10, right: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Text(
                  formatCurrency(price),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Text(
                  seats,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: -20,
            top: 0,
            bottom: 0,
            child: Image.asset(
              'assets/car_image.png',
              width: 90,
            ),
          ),
        ],
      ),
    );
  }

  buildPaymentCardWidget() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: () {
              // Thêm logic khi nhấn nút ở đây
              print('Button pressed!');
            },
            splashColor: Colors.grey.withOpacity(0.3), // Màu hiệu ứng khi nhấn
            highlightColor:
                Colors.grey.withOpacity(0.1), // Màu sáng khi giữ nút
            borderRadius: BorderRadius.circular(8), // Định hình hiệu ứng
            child: Row(
              children: [
                Image.asset(
                  'assets/cash_black.png',
                  width: 30,
                ),
                SizedBox(
                  width: 10,
                ),
                Text(
                  'Tiền mặt',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(
                  width: 5,
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.black,
                  size: 30,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDraggableRideConfirmSheet() {
    return DraggableScrollableSheet(
      initialChildSize: _sheetRideConfirmChildSize,
      minChildSize: _sheetRideConfirmChildSize,
      maxChildSize: _sheetRideConfirmChildSize,
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
                        setState(() {
                          showRideConfirmSheet = false;
                        });
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
                            onPressed: () {},
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

  buildDrawerItem({
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
        // dense: true,
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
                : Container()
          ],
        ),
      ),
    );
  }

  buildDrawer() {
    final authController = Get.find<AuthController>();

    return Obx(
      () {
        final user = authController.userData;

        if (user.isEmpty) {
          return Center(child: Text('Không tìm thấy thông tin người dùng'));
        }

        String name = user['name'] ?? 'Tên người dùng';
        String profileImage = user['image'] ?? '';
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
                                ? NetworkImage(
                                    profileImage) // Sử dụng URL hình ảnh từ Firestore
                                : AssetImage('assets/person.png')
                                    as ImageProvider,
                            fit: BoxFit.fill,
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
              Container(
                padding: EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    buildDrawerItem(
                      title: 'Thiết lập hồ sơ',
                      onPressed: () => Get.to(
                        () => ProfileSettingScreen(),
                      ),
                    ),
                    buildDrawerItem(
                      title: 'Hồ sơ khách hàng',
                      onPressed: () => Get.to(
                        () => CustomerProfileScreen(),
                      ),
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
                        await AuthController().signOut();
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginScreen()));
                      },
                    ),
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
