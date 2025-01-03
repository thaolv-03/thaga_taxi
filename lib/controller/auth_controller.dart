import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:thaga_taxi/views/customer_profile_screen.dart';
import 'package:thaga_taxi/views/driver/car_registration/car_registration_template.dart';
import 'package:thaga_taxi/views/driver/home_screen_driver.dart';
import 'package:thaga_taxi/views/home_screen.dart';
import 'package:thaga_taxi/views/login_screen.dart';
import 'package:thaga_taxi/views/profile_setting.dart';
import 'package:path/path.dart' as Path;

import '../views/driver/driver_profile_setup.dart';

class AuthController extends GetxController {
  String userUid = '';
  var verId = '';
  int? resendTokenId;
  bool phoneAuthCheck = false;
  dynamic credentials;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  var userData = {}.obs;

  var isProfileUploading = false.obs;
  var phoneNumber = ''.obs;

  bool isLoginAsDriver = false;

  phoneAuth(String phone) async {
    try {
      credentials = null;
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          log('Completed');
          credentials = credential;
          await FirebaseAuth.instance.signInWithCredential(credential);
          decideRoute(); // Chuyển hướng sau khi đăng nhập thành công
        },
        forceResendingToken: resendTokenId,
        verificationFailed: (FirebaseAuthException e) {
          log('Failed');
          if (e.code == 'invalid-phone-number') {
            debugPrint('The provided phone number is not valid.');
          }
        },
        codeSent: (String verificationId, int? resendToken) async {
          log('Code sent');
          verId = verificationId;
          resendTokenId = resendToken;
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      log("Error occured $e");
    }
  }

  verifiOtp(String otpNumber) async {
    log('Called');

    if (verId == null || verId.isEmpty) {
      log('Verification ID is null or empty');
      return;
    }

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verId, smsCode: otpNumber);

      log('LoggedIn');
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        decideRoute(); // Chuyển hướng sau khi đăng nhập thành công
      }
    } catch (e) {
      log('Error during OTP verification: $e');
    }
  }

  Future<void> fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((DocumentSnapshot snapshot) {
        if (snapshot.exists) {
          userData.value = snapshot.data() as Map<String, dynamic>;
        }
      });
    }
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .get();

      if (userDoc.exists) {
        phoneNumber.value = userDoc['phone'] ?? 'Không có số điện thoại';
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  decideRoute() async {
    User? user = FirebaseAuth.instance.currentUser;
    log('Current user: ${user?.uid}'); // In ra giá trị user

    if (user != null) {
      await fetchUserData();
      print('isLoginAsDrive: ${isLoginAsDriver}');
      FirebaseFirestore.instance.collection('users').doc(user.uid).get().then(
        (onValue) {
          if (isLoginAsDriver) {
            // print('isLoginAsDrive: ${isLoginAsDriver}');
            if (onValue.exists) {
              print("Driver Home Screen");
              Get.offAll(() => HomeScreenDriver());
            } else {
              Get.offAll(() => DriverProfileSetup());
            }
          } else {
            if (onValue.exists) {
              bool isDriver = onValue['isDriver'] ?? false;
              if (isDriver) {
                Get.offAll(() => HomeScreenDriver());
              } else {
                Get.offAll(() => HomeScreen());
              }
            } else {
              print('isLoginAsDrive: ${isLoginAsDriver}');
              Get.offAll(() => ProfileSettingScreen());
            }
          }
        },
      ).catchError((e) {
        log('Error fetching user data: $e');
      });
    } else {
      log('No user is logged in.');
    }
  }

  uploadImage(File image) async {
    String imageUrl = '';
    String fileName = Path.basename(image.path);
    var reference = FirebaseStorage.instance.ref().child('users/$fileName');
    UploadTask uploadTask = reference.putFile(image);
    TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
    await taskSnapshot.ref.getDownloadURL().then((value) {
      imageUrl = value;
      print('Download URL: $value');
    });

    return imageUrl;
  }

  Future<void> storeUserInfo(
    File? selectedImage,
    String name,
    String email,
    String home,
    String job,
    String company, {
    String? imageUrl, // URL ảnh cũ
  }) async {
    try {
      String? uploadedImageUrl;
      String? phoneNumber = FirebaseAuth.instance.currentUser?.phoneNumber;

      // Kiểm tra nếu có ảnh mới, tải ảnh lên Firebase Storage
      if (selectedImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${FirebaseAuth.instance.currentUser!.uid}.jpg');
        await ref.putFile(selectedImage);
        uploadedImageUrl = await ref.getDownloadURL();
      } else {
        // Sử dụng ảnh cũ nếu không có ảnh mới
        uploadedImageUrl = imageUrl;
      }

      // Cập nhật thông tin người dùng trong Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .set({
        'name': name,
        'email': email,
        'home': home,
        'job': job,
        'company': company,
        'image': uploadedImageUrl,
        'phoneNumber': phoneNumber,
        'isDriver': false,// Dùng URL ảnh mới hoặc cũ
      });

      Get.snackbar('Thành công', 'Thông tin đã được cập nhật!');
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể lưu thông tin: $e');
    } finally {
      isProfileUploading(false);
      Get.to(() => HomeScreen());
    }
  }

  Future<void> storeDriverInfo(
    File? selectedImage,
    String name,
    String email, {
    String? imageUrl, // URL ảnh cũ
  }) async {
    try {
      String? uploadedImageUrl;
      String? phoneNumber = FirebaseAuth.instance.currentUser?.phoneNumber;

      // Kiểm tra nếu có ảnh mới, tải ảnh lên Firebase Storage
      if (selectedImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('driver_images')
            .child('${FirebaseAuth.instance.currentUser!.uid}.jpg');
        await ref.putFile(selectedImage);
        uploadedImageUrl = await ref.getDownloadURL();
      } else {
        // Sử dụng ảnh cũ nếu không có ảnh mới
        uploadedImageUrl = imageUrl;
      }

      // Cập nhật thông tin người dùng trong Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .set({
        'name': name,
        'email': email,
        'image': uploadedImageUrl,
        'phoneNumber': phoneNumber,
        'isDriver': true,
      }, SetOptions(merge: true));

      // Kiểm tra trạng thái đăng ký xe và điều hướng
      await handleDriverNavigation();

      Get.snackbar('Thành công', 'Thông tin đã được cập nhật!');
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể lưu thông tin: $e');
    } finally {
      isProfileUploading(false);
    }
  }

  Future<void> handleDriverNavigation() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    // Kiểm tra trạng thái đăng ký xe
    bool hasCarRegistered = await checkCarRegistrationStatus();

    if (hasCarRegistered) {
      // Nếu đã đăng ký xe, điều hướng đến HomeScreenDriver
      Get.offAll(() => HomeScreenDriver());
    } else {
      // Nếu chưa đăng ký xe, điều hướng đến CarRegistrationTemplate
      Get.offAll(() => CarRegistrationTemplate());
    }
  }

  Future<bool> checkCarRegistrationStatus() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        return userDoc['hasCarRegistration'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      print('Error checking car registration status: $e');
      return false;
    }
  }

  Future<bool> uploadCarEntry(Map<String, dynamic> carData) async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      // Lưu thông tin xe và cập nhật trạng thái
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
          {...carData, 'hasCarRegistration': true, 'verified': false}, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error uploading car entry: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    decideRoute(); // Chuyển hướng sau khi đăng xuất
  }
}
