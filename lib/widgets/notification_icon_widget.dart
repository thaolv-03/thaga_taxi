import 'package:flutter/material.dart';

Widget buildNotificationIcon() {
  return Align(
    child: Padding(
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
  );
}
