// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// import '../../../../utils/app_colors.dart';
//
// class VehicalModelYearPage extends StatefulWidget {
//   const VehicalModelYearPage({super.key, required this.selectedVehicalModelYear, required this.onSelect});
//
//   final String selectedVehicalModelYear; // Giá trị ban đầu
//   final Function(String) onSelect;
//
//   @override
//   State<VehicalModelYearPage> createState() => _VehicalModelYearPageState();
// }
//
// class _VehicalModelYearPageState extends State<VehicalModelYearPage> {
//
//   late TextEditingController _vehicalModelYearController;
//
//   @override
//   void initState() {
//     super.initState();
//     // Khởi tạo TextEditingController với giá trị ban đầu
//     _vehicalModelYearController = TextEditingController(text: widget.selectedVehicalModelYear);
//   }
//
//   @override
//   void dispose() {
//     _vehicalModelYearController.dispose(); // Hủy controller khi không còn sử dụng
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Xe này được sản xuất năm nào?',
//           style: GoogleFonts.inter(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 30),
//         TextField(
//           controller: _vehicalModelYearController, // Gắn controller
//           decoration: InputDecoration(
//             hintText: 'Nhập năm sản xuất của xe',
//             hintStyle: GoogleFonts.inter(
//               fontSize: 16,
//               color: Colors.grey,
//             ),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: BorderSide(color: AppColors.blueColor, width: 2),
//             ),
//             contentPadding:
//             const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           ),
//           style: GoogleFonts.inter(
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//           ),
//           onChanged: (value) {
//             widget.onSelect(value); // Gọi callback khi giá trị thay đổi
//           },
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../utils/app_colors.dart';

class VehicalModelYearPage extends StatefulWidget {
  const VehicalModelYearPage(
      {Key? key, required this.controller, required this.focusNode})
      : super(key: key);

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  State<VehicalModelYearPage> createState() => _VehicalModelYearPageState();
}

class _VehicalModelYearPageState extends State<VehicalModelYearPage> {
  TextFieldWidget(
    String title,
    TextEditingController controller,
    Function validator, {
    Function? onTap,
    bool readOnly = false,
    FocusNode? focusNode,
  }) {
    return Container(
      width: Get.width,
      margin: EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 2,
                blurRadius: 1)
          ],
          borderRadius: BorderRadius.circular(8)),
      child: TextFormField(
        readOnly: readOnly,
        focusNode: focusNode,
        onTap: onTap != null ? () => onTap() : null,
        validator: (input) => validator(input),
        controller: controller,
        style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xffA7A7A7)),
        decoration: InputDecoration(
          hintText: title,
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.blueColor, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          'Mẫu xe này được sản xuất năm nào?',
          style: GoogleFonts.inter(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        SizedBox(
          height: 30,
        ),
        TextFieldWidget(
          'Nhập năm sản xuất của mẫu xe',
          widget.controller,
          (String v) {},
          onTap: null,
          readOnly: false,
          focusNode: widget.focusNode,
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Giải phóng tài nguyên của FocusNode khi widget bị hủy
    widget.focusNode.dispose();
    super.dispose();
  }

}
