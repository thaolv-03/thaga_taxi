import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:thaga_taxi/controller/auth_controller.dart';

class RoundedWithShadow extends StatefulWidget {
  const RoundedWithShadow({Key? key}) : super(key: key);

  @override
  _RoundedWithShadowState createState() => _RoundedWithShadowState();

  @override
  String toStringShort() => 'Rounded With Shadow';
}

class _RoundedWithShadowState extends State<RoundedWithShadow> {
  final controller = TextEditingController();
  final focusNode = FocusNode();

  AuthController authController = Get.find<AuthController>();

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 60,
      height: 64,
      textStyle: GoogleFonts.inter(
        fontSize: 20,
        color: const Color.fromARGB(255, 65, 67, 68),
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        color: const Color.fromARGB(108, 156, 227, 255),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    final cursor = Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: 21,
        height: 1,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(137, 146, 160, 1),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );

    return Pinput(
      length: 6,
      controller: controller,
      focusNode: focusNode,
      onCompleted: (String input) {
        authController.verifiOtp(input);
      },
      defaultPinTheme: defaultPinTheme,
      separatorBuilder: (index) => const SizedBox(width: 16),
      focusedPinTheme: defaultPinTheme.copyWith(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05999999865889549),
              offset: Offset(0, 3),
              blurRadius: 16,
            ),
          ],
        ),
      ),
      // onClipboardFound: (value) {
      //   debugPrint('onClipboardFound: $value');
      //   controller.setText(value);
      // },
      showCursor: true,
      cursor: cursor,
    );
  }
}
