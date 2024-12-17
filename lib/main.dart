import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:provider/provider.dart';
import 'package:thaga_taxi/controller/auth_controller.dart';
import 'package:thaga_taxi/firebase_options.dart';
import 'package:thaga_taxi/provider/user_data_provider.dart';
import 'package:thaga_taxi/views/login_screen.dart';
import 'package:thaga_taxi/views/profile_setting.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  _initializeHERESDK();

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.white,
    ),
  );

  runApp(MyApp());
}

void _initializeHERESDK() async {
  // Needs to be called before accessing SDKOptions to load necessary libraries.
  SdkContext.init(IsolateOrigin.main);

  // Set your credentials for the HERE SDK.
  String accessKeyId = "FN18ig_A94EuC0YXaixtGg";
  String accessKeySecret =
      "VB8bXioTb1sLVHGxSNSeB52fGqDz1I2fD5hse-JQN3d-riDavsbko5oGrNOkcwEs47vwr5e8vVEX2g5PgJCDBQ";
  SDKOptions sdkOptions =
      SDKOptions.withAccessKeySecret(accessKeyId, accessKeySecret);

  try {
    await SDKNativeEngine.makeSharedInstance(sdkOptions);
  } on InstantiationException {
    throw Exception("Failed to initialize the HERE SDK.");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    AuthController authController = Get.put(AuthController());
    authController.decideRoute();

    final textTheme = Theme.of(context).textTheme;

    return GetMaterialApp(
      title: 'Thaga Taxi',
      theme: ThemeData(
        textTheme: GoogleFonts.interTextTheme(textTheme),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const LoginScreen(),
    );
  }
}
