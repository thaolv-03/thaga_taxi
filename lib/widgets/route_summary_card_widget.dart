import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_colors.dart';

class RouteSummaryCard extends StatelessWidget {
  final String pickupAddress;
  final String destinationAddress;
  final VoidCallback onAddPressed;

  const RouteSummaryCard({
    Key? key,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.onAddPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 140, right: 20, left: 20),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Điểm đón
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.blueColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pickupAddress,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          // Điểm đến
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  destinationAddress,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Nút thêm
              // IconButton(
              //   onPressed: onAddPressed,
              //   icon: const Icon(Icons.add_circle, color: Colors.teal),
              // ),
            ],
          ),
        ],
      ),
    );
  }
}
