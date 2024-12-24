import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_colors.dart';

class TextFieldDestination extends StatefulWidget {
  final String initialTitle;
  final FocusNode destinationFocusNode;
  final TextEditingController destinationController;
  final bool isDestinationFocused;
  final Function(String) onChanged;
  final Function() onSubmitted;
  final Function() onTap;
  final List suggestionsForDestination;
  final Function onSuggestionTap;

  const TextFieldDestination({
    Key? key,
    required this.initialTitle,
    required this.destinationFocusNode,
    required this.destinationController,
    required this.isDestinationFocused,
    required this.onChanged,
    required this.onSubmitted,
    required this.onTap,
    required this.suggestionsForDestination,
    required this.onSuggestionTap,
  }) : super(key: key);

  @override
  _TextFieldDestinationState createState() => _TextFieldDestinationState();
}

class _TextFieldDestinationState extends State<TextFieldDestination> {
  @override
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: Get.width,
          height: 50,
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 4,
                blurRadius: 10,
              ),
            ],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.destinationFocusNode.hasFocus
                  ? AppColors.blueColor // Viền màu xanh khi chọn
                  : Colors.transparent, // Không có viền khi không chọn
              width: 2,
            ),
          ),
          child: TextFormField(
            focusNode: widget.destinationFocusNode,
            controller: widget.destinationController,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (value) {
              setState(() {
                widget.onSubmitted();
              });
            },
            onTap: () {
              widget.onTap();
            },
            onChanged: (value) {
              // Kiểm tra nếu chuỗi trống và cập nhật danh sách gợi ý
              widget.onChanged(value);
            },
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
            decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 10, right: 10),
                  child: Icon(
                    Icons.location_on,
                    color: AppColors.blueColor,
                  ),
                ),
                suffixIcon: widget.isDestinationFocused &&
                        widget.destinationController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            widget.destinationController.clear();
                            widget.onChanged('');
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                hintText: 'Tìm kiếm điểm đến...',
                hintStyle: TextStyle(color: Colors.black54)),
          ),
        ),
        if (widget.suggestionsForDestination.isNotEmpty)
          Container(
            width: Get.width,
            constraints: BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 4,
                  blurRadius: 10,
                ),
              ],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: widget.suggestionsForDestination.length,
              itemBuilder: (context, index) {
                final suggestion = widget.suggestionsForDestination[index];
                final address =
                    suggestion.place?.address.addressText ?? "Unknown";
                return ListTile(
                  title: Text(suggestion.title),
                  subtitle: Text(address),
                  onTap: () {
                    widget.onSuggestionTap(suggestion);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

