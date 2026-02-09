import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:prayer_times/core/config/prayer_time_app_color.dart';

InputDecoration userInputDecoration({
  required BuildContext context,
  required String hintText,
  required BorderRadius borderRadius,
  TextStyle? hintStyle,
  bool enabled = true,
  Color? suffixIconColor,
  String? prefixIconPath,
  String? suffixIconPath,
  EdgeInsetsGeometry? contentPadding,
  VoidCallback? onTapSuffixIcon,
  Color? prefixIconColor,
  bool showPrefixIcon = true,
  bool showSuffixIcon = false,
  double? borderWidth,
  Color? borderColor,
  Color? focusedBorderColor,
  Color? enabledBorderColor,
  Color? disabledBorderColor,
  Color? errorBorderColor,
  Color? focusedErrorBorderColor,
  Color? fillColor,
  String? errorText,
  double? suffixIconSize,
}) {
  final ThemeData theme = Theme.of(context);
  final TextTheme textTheme = theme.textTheme;

  return InputDecoration(
    counterText: '',
    errorStyle: textTheme.bodySmall?.copyWith(height: 0, fontSize: 0),
    counterStyle: textTheme.bodySmall?.copyWith(height: 0, fontSize: 0),

    enabled: enabled,
    border: outlineInputBorder(
      context: context,
      borderRadius: borderRadius,
      borderWidth: borderWidth ?? 0.8,
      borderColor: borderColor ?? Colors.transparent,
    ),
    focusedBorder: outlineInputBorder(
      context: context,
      borderRadius: borderRadius,
      borderWidth: borderWidth ?? 0.8,
      borderColor: focusedBorderColor ?? borderColor ?? Colors.transparent,
    ),

    enabledBorder: outlineInputBorder(
      context: context,
      borderRadius: borderRadius,
      borderWidth: borderWidth ?? 0.8,
      borderColor: enabledBorderColor ?? borderColor ?? Colors.transparent,
    ),
    disabledBorder: outlineInputBorder(
      context: context,
      borderRadius: borderRadius,
      borderWidth: borderWidth ?? 0.8,
      borderColor: disabledBorderColor ?? borderColor ?? Colors.transparent,
    ),
    errorBorder: outlineInputBorder(
      context: context,
      borderRadius: borderRadius,
      borderWidth: borderWidth ?? 0.8,
      borderColor: errorBorderColor ?? PrayerTimeAppColor.errorColor,
    ),
    focusedErrorBorder: outlineInputBorder(
      context: context,
      borderRadius: borderRadius,
      borderWidth: borderWidth ?? 0.8,
      borderColor:
          focusedErrorBorderColor ??
          errorBorderColor ??
          PrayerTimeAppColor.errorColor,
    ),
    contentPadding: contentPadding ?? const EdgeInsets.all(5),
    hintText: hintText,
    filled: true,
    fillColor: fillColor ?? theme.inputDecorationTheme.fillColor,
    hintStyle:
        hintStyle ??
        textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w400,
          fontSize: 14,
          color: theme.hintColor,
        ),
    suffixIconConstraints: showSuffixIcon
        ? BoxConstraints(
            minWidth: (suffixIconSize ?? 16) + 28,
            minHeight: (suffixIconSize ?? 16) + 28,
          )
        : null,
    suffixIcon: showSuffixIcon
        ? InkWell(
            onTap: () {
              if (onTapSuffixIcon != null) {
                onTapSuffixIcon();
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: suffixIconPath != null && suffixIconPath.isNotEmpty
                  ? SvgPicture.asset(
                      suffixIconPath,
                      fit: BoxFit.scaleDown,
                      height: suffixIconSize ?? 16,
                      width: suffixIconSize ?? 16,
                      colorFilter: suffixIconColor != null
                          ? ColorFilter.mode(suffixIconColor, BlendMode.srcIn)
                          : null,
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: suffixIconSize ?? 16,
                        color: theme.primaryColor,
                      ),
                    ),
            ),
          )
        : null,
    prefixIcon: showPrefixIcon
        ? (prefixIconPath != null && prefixIconPath.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(10, 5, 5, 5),
                  child: SvgPicture.asset(
                    prefixIconPath,
                    fit: BoxFit.scaleDown,
                    height: 22,
                    width: 22,
                    colorFilter: prefixIconColor != null
                        ? ColorFilter.mode(prefixIconColor, BlendMode.srcIn)
                        : null,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(5),
                  child: Icon(
                    Icons.search,
                    size: 22,
                    color: prefixIconColor ?? theme.hintColor,
                  ),
                ))
        : null,
  );
}

OutlineInputBorder outlineInputBorder({
  required BuildContext context,
  required BorderRadius borderRadius,
  double? borderWidth,
  Color? borderColor,
}) {
  return OutlineInputBorder(
    borderRadius: borderRadius,
    borderSide: BorderSide(
      width: borderWidth ?? 0.8,
      color: borderColor ?? Colors.transparent,
    ),
  );
}
