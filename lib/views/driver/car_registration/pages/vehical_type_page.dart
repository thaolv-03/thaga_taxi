import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../utils/app_colors.dart';

class VehicalTypePage extends StatefulWidget {
  const VehicalTypePage(
      {super.key, required this.selectedVehicalType, required this.onSelect});

  final String selectedVehicalType; // Giá trị ban đầu
  final Function(String) onSelect;
  @override
  State<VehicalTypePage> createState() => _VehicalTypePageState();
}

class _VehicalTypePageState extends State<VehicalTypePage> {
  List<String> vehicalType = [
    '4 người',
    '7 người',
    '5 người',
    '6 người',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          'Đây là loại xe gì?',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(
          height: 0,
        ),
        Expanded(
          child: ListView.builder(
              itemBuilder: (ctx, i) {
                return ListTile(
                  onTap: () => widget.onSelect(vehicalType[i]),
                  visualDensity: VisualDensity(vertical: -4),
                  title: Text(
                    vehicalType[i],
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  ),
                  trailing: widget.selectedVehicalType == vehicalType[i]
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircleAvatar(
                            backgroundColor: AppColors.blueColor,
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                        )
                      : SizedBox.shrink(),
                );
              },
              itemCount: vehicalType.length),
        ),
      ],
    );
  }
}
