import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:thaga_taxi/controller/auth_controller.dart';
import 'package:thaga_taxi/utils/app_colors.dart';
import 'package:thaga_taxi/views/home_screen.dart';
import 'package:thaga_taxi/widgets/thaga_intro_widget.dart';

class ProfileSettingScreen extends StatefulWidget {
  const ProfileSettingScreen({super.key});

  @override
  State<ProfileSettingScreen> createState() => _ProfileSettingScreenState();
}

class _ProfileSettingScreenState extends State<ProfileSettingScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController homeController = TextEditingController();
  TextEditingController jobController = TextEditingController();
  TextEditingController companyController = TextEditingController();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  AuthController authController = Get.find<AuthController>();

  final ImagePicker _picker = ImagePicker();
  File? selectedImage;
  getImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      selectedImage = File(image.path);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: Get.height * 0.4,
              child: Stack(
                children: [
                  thagaIntroWidgetWithoutLogos(),
                  Positioned(
                    top: 80,
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
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: InkWell(
                      onTap: () {
                        getImage(ImageSource.gallery);
                      },
                      child: selectedImage == null
                          ? Container(
                              width: 120,
                              height: 120,
                              margin: EdgeInsets.only(bottom: 40),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color.fromARGB(255, 255, 255, 255),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      spreadRadius: 3,
                                      blurRadius: 3)
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.camera_alt_outlined,
                                  size: 40,
                                  color: AppColors.blueColor,
                                ),
                              ),
                            )
                          : Container(
                              width: 120,
                              height: 120,
                              margin: EdgeInsets.only(bottom: 40),
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                    image: FileImage(selectedImage!),
                                    fit: BoxFit.fill),
                                shape: BoxShape.circle,
                                color: Color.fromARGB(255, 255, 255, 255),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      spreadRadius: 3,
                                      blurRadius: 3)
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 0,
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 23),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFieldWidget('Họ và tên', nameController,
                        (String? input) {
                      if (input!.isEmpty) {
                        return 'Tên là bắt buộc!';
                      }
                      return null;
                    }),
                    const SizedBox(
                      height: 10,
                    ),
                    TextFieldWidget('Email', emailController, (String? input) {
                      if (input!.isEmpty) {
                        return 'Email là bắt buộc!';
                      }
                      if (!input.contains('@')) {
                        return 'Vui lòng nhập email hợp lệ!';
                      }
                      return null;
                    }),
                    const SizedBox(
                      height: 10,
                    ),
                    TextFieldWidget('Địa chỉ', homeController,
                        (String? input) {
                      if (input!.isEmpty) {
                        return 'Địa chỉ là bắt buộc!';
                      }
                      return null;
                    }),
                    const SizedBox(
                      height: 10,
                    ),
                    TextFieldWidget('Công việc', jobController,
                        (String? input) {
                      if (input!.isEmpty) {
                        return 'Công việc là bắt buộc!';
                      }
                      return null;
                    }),
                    const SizedBox(
                      height: 10,
                    ),
                    TextFieldWidget('Công ty', companyController,
                        (String? input) {
                      if (input!.isEmpty) {
                        return 'Công ty là bắt buộc!';
                      }
                      return null;
                    }),
                    const SizedBox(
                      height: 30,
                    ),
                    Obx(() => authController.isProfileUploading.value
                        ? Center(
                            child: CircularProgressIndicator(),
                          )
                        : submitButton('Lưu thông tin', () {
                            // formKey.currentState!.validate();
                            if (!formKey.currentState!.validate()) {
                              return;
                            }

                            if (selectedImage == null) {
                              Get.snackbar('Cảnh báo',
                                  'Vui lòng thêm ảnh của bạn!');
                              return;
                            }
                            authController.isProfileUploading(true);
                            authController.storeUserInfo(
                                selectedImage,
                                nameController.text,
                                emailController.text,
                                homeController.text,
                                jobController.text,
                                companyController.text);
                          })),
                    const SizedBox(
                      height: 10,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextFieldWidget(
      String title, TextEditingController controller, Function validator,
      {Function? onTap, bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xffA7A7A7)),
        ),
        const SizedBox(
          height: 6,
        ),
        Container(
          width: Get.width,
          height: 50,
          decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 1)
              ],
              borderRadius: BorderRadius.circular(8)),
          child: TextFormField(
            readOnly: readOnly,
            onTap: () {},
            validator: (input) => validator(input),
            controller: controller,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xffA7A7A7)),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 20),
              border: InputBorder.none,
            ),
          ),
        )
      ],
    );
  }

  Widget submitButton(String title, Function onPressed) {
    return MaterialButton(
      minWidth: Get.width,
      height: 50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      color: AppColors.blueColor,
      onPressed: () => onPressed(),
      child: Text(
        title,
        style: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}