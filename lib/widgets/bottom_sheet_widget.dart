import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:here_sdk/search.dart';
import 'package:thaga_taxi/widgets/text_field_destination_widget.dart';
import 'package:thaga_taxi/widgets/text_field_source_widget.dart';
import '../utils/app_colors.dart';

class DraggableBottomSheet extends StatelessWidget {
  final double sheetChildSize;
  final String title;
  final Function(double) changeSheetSize;
  final String sourceAddress;
  final FocusNode sourceFocusNode;
  final TextEditingController sourceController;
  final bool isSourceFocused;
  final Function(String) onSourceChanged;
  final VoidCallback onSourceSubmitted;
  final VoidCallback onSourceTap;
  final List suggestionsForSource;
  final Function(Suggestion) onSourceSuggestionTap;

  final FocusNode destinationFocusNode;
  final TextEditingController destinationController;
  final bool isDestinationFocused;
  final Function(String) onDestinationChanged;
  final VoidCallback onDestinationSubmitted;
  final VoidCallback onDestinationTap;
  final List suggestionsForDestination;
  final Function(Suggestion) onDestinationSuggestionTap;

  final Function() onContinuePressed;
  final Function() moveToCurrentLocation;
  final Widget buildNotificationIcon;
  final Widget buildCurrentLocationIcon;

  const DraggableBottomSheet({
    Key? key,
    required this.sheetChildSize,
    required this.title,
    required this.changeSheetSize,
    required this.sourceAddress,
    required this.sourceFocusNode,
    required this.sourceController,
    required this.isSourceFocused,
    required this.onSourceChanged,
    required this.onSourceSubmitted,
    required this.onSourceTap,
    required this.suggestionsForSource,
    required this.onSourceSuggestionTap,
    required this.destinationFocusNode,
    required this.destinationController,
    required this.isDestinationFocused,
    required this.onDestinationChanged,
    required this.onDestinationSubmitted,
    required this.onDestinationTap,
    required this.suggestionsForDestination,
    required this.onDestinationSuggestionTap,
    required this.onContinuePressed,
    required this.moveToCurrentLocation,
    required this.buildNotificationIcon,
    required this.buildCurrentLocationIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: sheetChildSize,
      minChildSize: sheetChildSize,
      maxChildSize: sheetChildSize,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 4,
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // Title
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    TextFieldSource(
                      initialTitle: title,
                      sourceAddress: sourceAddress,
                      sourceFocusNode: sourceFocusNode,
                      sourceController: sourceController,
                      isSourceFocused: isSourceFocused,
                      onChanged: onSourceChanged,
                      onSubmitted: onSourceSubmitted,
                      onTap: onSourceTap,
                      suggestionsForSource: suggestionsForSource,
                      onSuggestionTap: onSourceSuggestionTap,
                    ),
                    TextFieldDestination(
                      initialTitle: title,
                      destinationFocusNode: destinationFocusNode,
                      destinationController: destinationController,
                      isDestinationFocused: isDestinationFocused,
                      onChanged: onDestinationChanged,
                      onSubmitted: onDestinationSubmitted,
                      onTap: onDestinationTap,
                      suggestionsForDestination: suggestionsForDestination,
                      onSuggestionTap: onDestinationSuggestionTap,
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: onContinuePressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blueColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Tiếp tục',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    buildNotificationIcon,
                    buildCurrentLocationIcon,
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
