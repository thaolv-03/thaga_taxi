import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart'; // Nếu bạn sử dụng GetX
import '../utils/app_colors.dart';

class TextFieldSource extends StatefulWidget {
  final String initialTitle;
  final String sourceAddress;
  final FocusNode sourceFocusNode;
  final TextEditingController sourceController;
  final bool isSourceFocused;
  final Function(String) onChanged;
  final Function() onSubmitted;
  final Function() onTap;
  final List suggestionsForSource;
  final Function onSuggestionTap;

  const TextFieldSource({
    Key? key,
    required this.initialTitle,
    required this.sourceAddress,
    required this.sourceFocusNode,
    required this.sourceController,
    required this.isSourceFocused,
    required this.onChanged,
    required this.onSubmitted,
    required this.onTap,
    required this.suggestionsForSource,
    required this.onSuggestionTap,
  }) : super(key: key);

  @override
  _TextFieldSourceState createState() => _TextFieldSourceState();
}

class _TextFieldSourceState extends State<TextFieldSource> {
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
              color: widget.sourceFocusNode.hasFocus
                  ? AppColors.blueColor // Viền màu xanh khi chọn
                  : Colors.transparent, // Không có viền khi không chọn
              width: 2,
            ),
          ),
          child: TextFormField(
            focusNode: widget.sourceFocusNode,
            controller: widget.sourceController,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (value) {
              widget.onSubmitted();
            },
            onTap: () {
              widget.onTap();
            },
            onChanged: (value) {
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
                  Icons.my_location,
                  color: AppColors.blueColor,
                ),
              ),
              suffixIcon: widget.isSourceFocused && widget.sourceController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    widget.sourceController.clear();
                    widget.onChanged('');
                  });
                },
              )
                  : null,
              border: InputBorder.none,
              hintText: widget.sourceAddress,
              hintStyle: const TextStyle(color: Colors.black54),
            ),
          ),
        ),
        if (widget.suggestionsForSource.isNotEmpty)
          Container(
            width: Get.width,
            constraints: const BoxConstraints(maxHeight: 200),
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
              itemCount: widget.suggestionsForSource.length,
              itemBuilder: (context, index) {
                final suggestion = widget.suggestionsForSource[index];
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


// Widget buildTextFieldForSource() {
//   return Column(
//     children: [
//       Container(
//         width: Get.width,
//         height: 50,
//         margin: const EdgeInsets.only(top: 10),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               spreadRadius: 4,
//               blurRadius: 10,
//             ),
//           ],
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(
//             color: focusedField == "source"
//                 ? AppColors.blueColor // Viền màu xanh khi chọn
//                 : Colors.transparent, // Không có viền khi không chọn
//             width: 2,
//           ),
//         ),
//         child: TextFormField(
//           focusNode: sourceFocusNode,
//           controller: sourceController,
//           textInputAction: TextInputAction.done,
//           onFieldSubmitted: (value) {
//             setState(() {
//               _changeSheetSize(0.37);
//             });
//           },
//           onTap: () {
//             setState(() {
//               // Chọn toàn bộ văn bản khi nhấn vào
//               sourceController.selection = TextSelection(
//                 baseOffset: 0,
//                 extentOffset: sourceController.text.length,
//               );
//               focusedField = "source";
//               _title = "Điểm đón";
//               _changeSheetSize(0.6);
//             });
//           },
//           onChanged: (value) {
//             if (value.isEmpty) {
//               setState(() {
//                 _suggestionsForSource = [];
//               });
//             } else {
//               _getSuggestionsForSource(value);
//             }
//           },
//           style: GoogleFonts.inter(
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//             color: Colors.black54,
//           ),
//           decoration: InputDecoration(
//             contentPadding:
//             const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
//             prefixIcon: const Padding(
//               padding: EdgeInsets.only(left: 10, right: 10),
//               child: Icon(
//                 Icons.my_location,
//                 color: AppColors.blueColor,
//               ),
//             ),
//             suffixIcon: isSourceFocused && sourceController.text.isNotEmpty
//                 ? IconButton(
//               icon: const Icon(Icons.clear),
//               onPressed: () {
//                 setState(() {
//                   sourceController.clear();
//                   _suggestionsForSource = [];
//                 });
//               },
//             )
//                 : null,
//             border: InputBorder.none,
//             hintText: _sourceAddress,
//             hintStyle: const TextStyle(color: Colors.black54),
//           ),
//         ),
//       ),
//       if (_suggestionsForSource.isNotEmpty)
//         Container(
//           width: Get.width,
//           constraints: const BoxConstraints(maxHeight: 200),
//           margin: const EdgeInsets.only(top: 5),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.05),
//                 spreadRadius: 4,
//                 blurRadius: 10,
//               ),
//             ],
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: ListView.builder(
//             padding: EdgeInsets.zero,
//             itemCount: _suggestionsForSource.length,
//             itemBuilder: (context, index) {
//               final suggestion = _suggestionsForSource[index];
//               final address =
//                   suggestion.place?.address.addressText ?? "Unknown";
//               return ListTile(
//                 title: Text(suggestion.title),
//                 subtitle: Text(address),
//                 onTap: () {
//                   _handleSuggestionSourceTap(suggestion);
//                 },
//               );
//             },
//           ),
//         ),
//     ],
//   );
// }
