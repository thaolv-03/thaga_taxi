import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

Widget buildCurrentLocationIcon(
    Future<void> Function() _moveToCurrentLocation) {
  return Align(
    child: Padding(
      padding: const EdgeInsets.only(right: 15),
      child: InkWell(
        onTap: () async {
          await _moveToCurrentLocation();
        },
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
  );
}
