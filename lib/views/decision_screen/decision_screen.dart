import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:thaga_taxi/controller/auth_controller.dart';
import 'package:thaga_taxi/views/login_screen.dart';
import 'package:thaga_taxi/widgets/text_widget.dart';

import '../../utils/app_constants.dart';
import '../../widgets/decision_button.dart';
import '../../widgets/thaga_intro_widget.dart';

class DecisionScreen extends StatefulWidget {
  const DecisionScreen({super.key});

  @override
  State<DecisionScreen> createState() => _DecisionScreenState();
}

class _DecisionScreenState extends State<DecisionScreen> {
  AuthController authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    // Close the keyboard when the screen is first shown
    Future.delayed(Duration.zero, () {
      FocusScope.of(context).unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(  // Wrap the entire body in SingleChildScrollView
        child: Container(
          width: double.infinity,
          child: Column(
            children: [
              thagaIntroWidget(isBackButton = false),
              const SizedBox(
                height: 40,
              ),
              textWidget(text: AppConstants.helloNiceToMeetYou, fontSize: 14),
              textWidget(
                  text: AppConstants.getMovingWithThagaTaxi,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
              const SizedBox(
                height: 30,
              ),
              DecisionButton('local_taxi', 'Tài xế đăng nhập', () {
                authController.isLoginAsDriver = true;
                Get.to(() => LoginScreen());
              }, Get.width * 0.8),
              const SizedBox(
                height: 20,
              ),
              DecisionButton('person', 'Người dùng đăng nhập', () {
                authController.isLoginAsDriver = false;
                Get.to(() => LoginScreen());
              }, Get.width * 0.8),
            ],
          ),
        ),
      ),
    );
  }
}
