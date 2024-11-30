import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:thaga_taxi/views/home_screen.dart';
import 'package:thaga_taxi/views/profile_setting.dart';
import 'package:path/path.dart' as Path;

class AuthController extends GetxController {
  String userUid = '';
  var verId = '';
  int? resendTokenId;
  bool phoneAuthCheck = false;
  dynamic credentials;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var isProfileUploading = false.obs;

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
    PhoneAuthCredential credential =
        PhoneAuthProvider.credential(verificationId: verId, smsCode: otpNumber);
    log('LoggedIn');

    await FirebaseAuth.instance.signInWithCredential(credential).then((value) {
      decideRoute();
    });
  }

  decideRoute() {
    // Buoc 1: Check user login?
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Buoc 2: Check whether user profile exists?
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .then((onValue) {
        if (onValue.exists) {
          Get.to(() => HomeScreen());
        } else {
          Get.to(() => ProfileSettingScreen());
        }
      });
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

  storeUserInfo(
    File? selectedImage,
    String name,
    String email,
    String home,
    String job,
    String company, {
    String url = '',
  }) async {
    String url_new = url;
    if (selectedImage != null) {
      url_new = await uploadImage(selectedImage);
    }
    String uid = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore.instance.collection('users').doc(uid).set({
      'image': url_new,
      'name': name,
      'email': email,
      'home': home,
      'job': job,
      'company': company,
    }, SetOptions(merge: true)).then((value) {
      isProfileUploading(false);

      Get.to(() => HomeScreen());
    });
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
