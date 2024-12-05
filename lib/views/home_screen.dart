import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/search.dart';
import 'package:provider/provider.dart';
import 'package:thaga_taxi/controller/auth_controller.dart';
import 'package:thaga_taxi/utils/app_colors.dart';
import 'dart:ui' as ui;
import 'package:geolocator/geolocator.dart';
import 'package:thaga_taxi/views/customer_profile_screen.dart';
import 'package:thaga_taxi/views/login_screen.dart';
import 'package:thaga_taxi/views/profile_setting.dart';

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
  bool showSourceField = true;
  bool isSourceFocused = false;
  bool isDestinationFocused = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _cameraUpdateTimer;

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
        final mapImage = await _createMarkerImage();

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
        // Di chuyển xuống phía dưới một chút so với vị trí hiện tại
        // const double offsetInDegrees = 0.0007;
        // // const double offsetInDegrees = 0.0;
        // final adjustedGeoCoordinates = GeoCoordinates(
        //   geoCoordinates.latitude - offsetInDegrees,
        //   geoCoordinates.longitude,
        // );

        // // Điều hướng camera tới tọa độ được điều chỉnh
        // _hereMapController.camera.lookAtPoint(adjustedGeoCoordinates);

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
        final mapImage = await _createMarkerImage();

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
          // _sourceAddress = places.first.address.addressText;
          sourceController.text = places.first.address.addressText;
        });
      }
    });
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

    // Điều chỉnh camera
    _hereMapController.camera.lookAtPoint(adjustedCurrentLocation);

    // Zoom vào vị trí gần hơn (nếu cần)
    const double distanceToEarthInMeters = 800; // Khoảng cách zoom
    MapMeasure mapMeasureZoom =
        MapMeasure(MapMeasureKind.distance, distanceToEarthInMeters);

    _hereMapController.camera
        .lookAtPointWithMeasure(adjustedCurrentLocation, mapMeasureZoom);
    // Sử dụng hiệu ứng "lướt" camera tới vị trí hiện tại
    // Tạo hiệu ứng lướt camera
    // _animateCamera(currentLocation, mapMeasureZoom);

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
    _mapMarkers.clear();
  }

  Future<MapImage> _createMarkerImage({int width = 50, int height = 75}) async {
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
                        print("Điểm đón đã xác nhận: ${sourceController.text}");
                        print(
                            "Điểm đến đã xác nhận: ${destinationController.text}");
                        // Có thể điều hướng hoặc thực hiện hành động khác ở đây
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
