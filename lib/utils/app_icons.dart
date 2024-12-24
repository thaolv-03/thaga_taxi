import 'package:flutter/material.dart';

IconData getIconFromString(String iconName) {
  switch (iconName) {
    case 'local_taxi':
      return Icons.local_taxi;
    case 'person':
      return Icons.person;
    case 'settings':
      return Icons.settings;
  // Thêm các biểu tượng khác tại đây
    default:
      return Icons.help; // Biểu tượng mặc định nếu không khớp
  }
}