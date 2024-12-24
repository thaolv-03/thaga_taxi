import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:thaga_taxi/utils/app_colors.dart';
import 'package:thaga_taxi/views/driver/car_registration/pages/document_uploaded_page.dart';
import 'package:thaga_taxi/views/driver/car_registration/pages/location_page.dart';
import 'package:thaga_taxi/views/driver/car_registration/pages/upload_document_page.dart';
import 'package:thaga_taxi/views/driver/car_registration/pages/vehical_color_page.dart';
import 'package:thaga_taxi/views/driver/car_registration/pages/vehical_make_page.dart';
import 'package:thaga_taxi/views/driver/car_registration/pages/vehical_model_page.dart';
import 'package:thaga_taxi/views/driver/car_registration/pages/vehical_model_year_page.dart';
import 'package:thaga_taxi/views/driver/car_registration/pages/vehical_number_page.dart';
import 'package:thaga_taxi/views/driver/car_registration/pages/vehical_type_page.dart';
import 'package:thaga_taxi/views/driver/car_registration/verification_pending_screen.dart';
import 'package:thaga_taxi/views/driver/driver_profile_setup.dart';
import 'package:thaga_taxi/widgets/thaga_intro_widget.dart';

import '../../../controller/auth_controller.dart';

class CarRegistrationTemplate extends StatefulWidget {
  const CarRegistrationTemplate({super.key});

  @override
  State<CarRegistrationTemplate> createState() =>
      _CarRegistrationTemplateState();
}

class _CarRegistrationTemplateState extends State<CarRegistrationTemplate> {
  String selectedVehicalType = '';
  TextEditingController locationController = TextEditingController();
  TextEditingController vehicalMakeController = TextEditingController();
  TextEditingController vehicalModelController = TextEditingController();
  TextEditingController vehicalModelYearController = TextEditingController();
  TextEditingController vehicalNumberController = TextEditingController();
  TextEditingController vehicalColorController = TextEditingController();
  File? document;

  PageController pageController = PageController();

  int currentPage = 0;

  // Tạo FocusNode cho mỗi TextField
  FocusNode locationFocusNode = FocusNode();
  FocusNode vehicalMakeFocusNode = FocusNode();
  FocusNode vehicalModelFocusNode = FocusNode();
  FocusNode vehicalModelYearFocusNode = FocusNode();
  FocusNode vehicalNumberFocusNode = FocusNode();
  FocusNode vehicalColorFocusNode = FocusNode();

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     body: Column(
  //       children: [
  //         Container(
  //           child: Stack(
  //             children: [
  //               thagaIntroWidgetWithoutLogos('Đăng ký xe', ''),
  //               // Positioned(
  //               //   top: 60,
  //               //   left: 30,
  //               //   child: InkWell(
  //               //     onTap: () {
  //               //       Get.off(() => DriverProfileSetup());
  //               //     },
  //               //     child: Container(
  //               //       width: 45,
  //               //       height: 45,
  //               //       decoration: BoxDecoration(
  //               //         shape: BoxShape.circle,
  //               //         color: Colors.white,
  //               //       ),
  //               //       child: Icon(
  //               //         Icons.arrow_back,
  //               //         color: Colors.blue,
  //               //         size: 20,
  //               //       ),
  //               //     ),
  //               //   ),
  //               // ),
  //             ],
  //           ),
  //         ),
  //         const SizedBox(
  //           height: 30,
  //         ),
  //         Expanded(
  //           child: Padding(
  //             padding: const EdgeInsets.symmetric(horizontal: 20),
  //             child: PageView(
  //               onPageChanged: (int page) {
  //                 currentPage = page;
  //               },
  //               controller: pageController,
  //               // physics: NeverScrollableScrollPhysics(),
  //               children: [
  //                 LocationPage(
  //                   controller: locationController,
  //                 ),
  //                 VehicalTypePage(
  //                   selectedVehicalType: selectedVehicalType,
  //                   onSelect: (String vehicalType) {
  //                     setState(() {
  //                       selectedVehicalType = vehicalType;
  //                     });
  //                   },
  //                 ),
  //                 VehicalMakePage(
  //                   controller: vehicalMakeController,
  //                 ),
  //                 VehicalModelPage(
  //                   controller: vehicalModelController,
  //                 ),
  //                 VehicalModelYearPage(
  //                   controller: vehicalModelYearController,
  //                 ),
  //                 VehicalNumberPage(
  //                   controller: vehicalNumberController,
  //                 ),
  //                 VehicalColorPage(
  //                   controller: vehicalColorController,
  //                 ),
  //                 UploadDocumentPage(
  //                   onImageSelected: (File image) {
  //                     document = image;
  //                   },
  //                 ),
  //                 DocumentUploadedPage(),
  //               ],
  //             ),
  //           ),
  //         ),
  //         Align(
  //           alignment: Alignment.bottomRight,
  //           child: Padding(
  //             padding: const EdgeInsets.all(8.0),
  //             child: Obx(
  //               () => isUploading.value
  //                   ? Center(
  //                       child: CircularProgressIndicator(),
  //                     )
  //                   : FloatingActionButton(
  //                       onPressed: () {
  //                         if (currentPage < 8) {
  //                           pageController.animateToPage(currentPage + 1,
  //                               duration: const Duration(seconds: 1),
  //                               curve: Curves.easeIn);
  //                         } else {
  //                           uploadDriverCarEntry();
  //                         }
  //                       },
  //                       child: Icon(
  //                         Icons.arrow_forward,
  //                         color: Colors.white,
  //                       ),
  //                       backgroundColor: AppColors.blueColor,
  //                     ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            child: Stack(
              children: [
                thagaIntroWidgetWithoutLogos('Đăng ký xe', ''),
              ],
            ),
          ),
          const SizedBox(
            height: 30,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: PageView(
                physics: NeverScrollableScrollPhysics(),
                onPageChanged: (int page) {
                  setState(() {
                    currentPage = page;
                  });
                  // Tắt bàn phím khi đến trang VehicalTypePage hoặc UploadDocumentPage
                  if (page == 1 || page == 7) {
                    FocusScope.of(context).unfocus();
                  }

                  // Tự động focus vào TextField khi chuyển trang
                  _focusOnPage(page);
                },
                controller: pageController,
                children: [
                  LocationPage(
                    controller: locationController,
                    focusNode: locationFocusNode,
                  ),
                  VehicalTypePage(
                    selectedVehicalType: selectedVehicalType,
                    onSelect: (String vehicalType) {
                      setState(() {
                        selectedVehicalType = vehicalType;
                      });
                    },
                  ),
                  VehicalMakePage(
                    controller: vehicalMakeController,
                    focusNode: vehicalMakeFocusNode,
                  ),
                  VehicalModelPage(
                    controller: vehicalModelController,
                    focusNode: vehicalModelFocusNode,
                  ),
                  VehicalModelYearPage(
                    controller: vehicalModelYearController,
                    focusNode: vehicalModelYearFocusNode,
                  ),
                  VehicalNumberPage(
                    controller: vehicalNumberController,
                    focusNode: vehicalNumberFocusNode,
                  ),
                  VehicalColorPage(
                    controller: vehicalColorController,
                    focusNode: vehicalColorFocusNode,
                  ),
                  UploadDocumentPage(
                    onImageSelected: (File image) {
                      setState(() {
                        document = image;
                      });
                    },
                  ),
                  DocumentUploadedPage(),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Obx(
                    () => isUploading.value
                    ? Center(
                  child: CircularProgressIndicator(),
                )
                    : FloatingActionButton(
                  onPressed: () {
                    if (validateCurrentPage()) {
                      if (currentPage < 8) {
                        pageController.animateToPage(
                          currentPage + 1,
                          duration: const Duration(seconds: 1),
                          curve: Curves.easeIn,
                        );
                      } else {
                        uploadDriverCarEntry();
                      }
                    } else {
                      Get.snackbar(
                        'Lỗi',
                        'Vui lòng hoàn thành thông tin trước khi tiếp tục.',
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                    }
                  },
                  child: Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                  ),
                  backgroundColor: AppColors.blueColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Hàm để tự động focus vào TextField khi chuyển trang
  void _focusOnPage(int page) {
    switch (page) {
      case 0:
        FocusScope.of(context).requestFocus(locationFocusNode);
        break;
      case 2:
        FocusScope.of(context).requestFocus(vehicalMakeFocusNode);
        break;
      case 3:
        FocusScope.of(context).requestFocus(vehicalModelFocusNode);
        break;
      case 4:
        FocusScope.of(context).requestFocus(vehicalModelYearFocusNode);
        break;
      case 5:
        FocusScope.of(context).requestFocus(vehicalNumberFocusNode);
        break;
      case 6:
        FocusScope.of(context).requestFocus(vehicalColorFocusNode);
        break;
      default:
        break;
    }
  }

  bool validateCurrentPage() {
    switch (currentPage) {
      case 0:
        return locationController.text.isNotEmpty;
      case 1:
        return selectedVehicalType.isNotEmpty;
      case 2:
        return vehicalMakeController.text.isNotEmpty;
      case 3:
        return vehicalModelController.text.isNotEmpty;
      case 4:
        return vehicalModelYearController.text.isNotEmpty;
      case 5:
        return vehicalNumberController.text.isNotEmpty;
      case 6:
        return vehicalColorController.text.isNotEmpty;
      case 7:
        return document != null;
      default:
        return true;
    }
  }

  var isUploading = false.obs;

  void uploadDriverCarEntry() async {
    isUploading(true);
    String imageUrl = await Get.find<AuthController>().uploadImage(document!);

    Map<String, dynamic> carData = {
      'country': locationController.text,
      'vehicle_type': selectedVehicalType.replaceAll(' người', ''),
      'vehicle_make': vehicalMakeController.text,
      'vehicle_model': vehicalModelController.text,
      'vehicle_year': vehicalModelYearController.text,
      'vehicle_number': vehicalNumberController.text.trim(),
      'vehicle_color': vehicalColorController.text,
      'document': imageUrl
    };

    await Get.find<AuthController>().uploadCarEntry(carData);
    isUploading(false);
    Get.off(() => VerificaitonPendingScreen());
  }
}
