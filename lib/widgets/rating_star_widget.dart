import 'package:flutter/material.dart';

class RatingStarWidget extends StatefulWidget {
  RatingStarWidget({super.key, required this.ratingNotifier});

  final ValueNotifier<int> ratingNotifier; // Thay thế `rating` bằng `ratingNotifier`

  @override
  State<RatingStarWidget> createState() => _RatingStarWidgetState();
}

class _RatingStarWidgetState extends State<RatingStarWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          return IconButton(
            onPressed: () {
              widget.ratingNotifier.value = index + 1; // Cập nhật giá trị của ValueNotifier
            },
            icon: Icon(
              Icons.star,
              color: index < widget.ratingNotifier.value
                  ? Colors.yellow
                  : Colors.grey,
              size: 40,
            ),
          );
        }),
      ),
    );
  }
}


