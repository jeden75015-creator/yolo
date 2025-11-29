// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import '../theme/app_button_styles.dart';
import '../theme/app_dimensions.dart';

enum ButtonType { primary, secondary, danger, disabled }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final ButtonType type;
  final double? width;
  final IconData? icon;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    this.onTap,
    this.type = ButtonType.primary,
    this.width,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // Sélection du style selon le type
    final decoration = switch (type) {
      ButtonType.primary => AppButtonStyles.mainButtonDecoration,
      ButtonType.secondary => AppButtonStyles.secondaryButtonDecoration,
      ButtonType.danger => AppButtonStyles.dangerButtonDecoration,
      ButtonType.disabled => AppButtonStyles.disabledButtonDecoration,
    };

    final textStyle = switch (type) {
      ButtonType.primary => AppButtonStyles.mainButtonText,
      ButtonType.secondary => AppButtonStyles.secondaryButtonText,
      ButtonType.danger => AppButtonStyles.dangerButtonText,
      ButtonType.disabled => AppButtonStyles.disabledButtonText,
    };

    final isDisabled = type == ButtonType.disabled || onTap == null;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        width: width ?? AppDimensions.buttonWidth,
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.buttonVerticalPadding,
        ),
        decoration: decoration,
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: textStyle.color, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(text, style: textStyle),
                  ],
                ),
        ),
      ),
    );
  }
}
