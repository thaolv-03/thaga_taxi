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
import 'package:thaga_taxi/views/driver/home_screen_driver.dart';
import 'package:thaga_taxi/views/home_screen.dart';
import 'package:thaga_taxi/widgets/thaga_intro_widget.dart';

class DriverProfileSetup extends StatefulWidget {
  const DriverProfileSetup({super.key});

  @override
  State<DriverProfileSetup> createState() => _DriverProfileSetupState();
}

class _DriverProfileSetupState extends State<DriverProfileSetup> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  String profileImage = "";
  bool isHasUserData = false;

  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  AuthController authController = Get.find<AuthController>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final ImagePicker _picker = ImagePicker();
  File? selectedImage;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  Future<void> _loadCurrentUserData() async {
    try {
      final User? currentUser = _auth.currentUser; // Lấy người dùng hiện tại
      if (currentUser != null) {
        String uid = currentUser.uid;

        // Truy vấn thông tin người dùng từ Firestore
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(uid).get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          // Cập nhật thông tin vào controller
          setState(() {
            isHasUserData = true;
            nameController.text = userData['name'] ?? '';
            emailController.text = userData['email'] ?? '';
            profileImage = userData['image'] ?? '';
          });
        } else {
          // Nếu không có thông tin, để trống các controller
          setState(() {
            isHasUserData = false;
            nameController.clear();
            emailController.clear();
            profileImage = '';
          });
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
      // Nếu có lỗi, để trống các controller
      setState(() {
        isHasUserData = false;
        nameController.clear();
        emailController.clear();
        profileImage = '';
      });
    }
  }

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
      body: Obx(
        () {
          final user = authController.userData;

          String profileImage = user['image'] ?? '';

          return SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: Get.height * 0.4,
                  child: Stack(
                    children: [
                      thagaIntroWidgetWithoutLogos("Thiết lập hồ sơ tài xế", ""),
                      if (isHasUserData)
                        Positioned(
                          top: 60,
                          left: 30,
                          child: InkWell(
                            onTap: () {
                              Get.off(() => HomeScreenDriver());
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
                              ? (profileImage.isNotEmpty
                                  ? Container(
                                      width: 120,
                                      height: 120,
                                      margin: EdgeInsets.only(bottom: 40),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image: NetworkImage(profileImage),
                                          fit: BoxFit.cover,
                                        ),
                                        color:
                                            Color.fromARGB(255, 255, 255, 255),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
                                            spreadRadius: 3,
                                            blurRadius: 3,
                                          )
                                        ],
                                      ),
                                    )
                                  : Container(
                                      width: 120,
                                      height: 120,
                                      margin: EdgeInsets.only(bottom: 40),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            Color.fromARGB(255, 255, 255, 255),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
                                            spreadRadius: 3,
                                            blurRadius: 3,
                                          )
                                        ],
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.camera_alt_outlined,
                                          size: 40,
                                          color: AppColors.blueColor,
                                        ),
                                      ),
                                    ))
                              : Container(
                                  width: 120,
                                  height: 120,
                                  margin: EdgeInsets.only(bottom: 40),
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: FileImage(selectedImage!),
                                      fit: BoxFit.cover,
                                    ),
                                    shape: BoxShape.circle,
                                    color: Color.fromARGB(255, 255, 255, 255),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        spreadRadius: 3,
                                        blurRadius: 3,
                                      )
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
                        TextFieldWidget('Email', emailController,
                            (String? input) {
                          if (input!.isEmpty) {
                            return 'Email là bắt buộc!';
                          }
                          if (!input.contains('@')) {
                            return 'Vui lòng nhập email hợp lệ!';
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

                                if (selectedImage == null &&
                                    profileImage.isEmpty) {
                                  Get.snackbar('Cảnh báo',
                                      'Vui lòng thêm ảnh của bạn!');
                                  return;
                                }
                                authController.isProfileUploading(true);

                                authController.storeDriverInfo(
                                  selectedImage,
                                  nameController.text,
                                  emailController.text,
                                  imageUrl: profileImage,
                                );
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
          );
        },
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
