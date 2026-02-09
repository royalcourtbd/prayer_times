import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prayer_times/core/config/prayer_time_app_color.dart';
import 'package:prayer_times/core/config/prayer_time_app_screen.dart';
import 'package:prayer_times/core/external_libs/user_input_field/user_input_field.dart';
import 'package:prayer_times/core/static/ui_const.dart';
import 'package:prayer_times/core/utility/utility.dart';
import 'package:prayer_times/presentation/prayer_times.dart';

class UserInputField extends StatefulWidget {
  const UserInputField({
    super.key,
    required this.textEditingController,
    this.hintText,
    this.onTapSuffixIcon,
    this.showSuffixIcon = false,
    this.maxLength = 50,
    this.textAlign = TextAlign.start,
    this.showPrefixIcon = true,
    this.validator,
    this.onChanged,
    this.borderRadius,
    this.prefixIconPath,
    this.suffixIconPath,
    this.prefixIconColor,
    this.inputFormatters,
    this.contentPadding,
    this.onFieldSubmitted,
    this.isError = false,
    this.errorBorderColor,
    this.focusNode,
    this.fillColor,
    this.keyboardType,
    this.hintStyle,
    this.borderColor,
    this.borderWidth,
    this.focusedBorderColor,
    this.enabledBorderColor,
    this.disabledBorderColor,
    this.suffixIconColor,
    this.suffixIconSize,
    this.errorText,
    this.label,
    this.labelColor,
    this.labelFontSize,
    this.focusedLabelColor,
    this.focusedFillColor,
    this.focusedSuffixIconColor,
    this.autovalidateMode,
  });

  const UserInputField.withHeader({
    super.key,
    required this.textEditingController,
    this.hintText,
    required String this.label,
    this.labelColor,
    this.labelFontSize,
    this.focusedLabelColor,
    this.focusedFillColor,
    this.focusedSuffixIconColor,
    this.onTapSuffixIcon,
    this.showSuffixIcon = false,
    this.maxLength = 50,
    this.textAlign = TextAlign.start,
    this.showPrefixIcon = true,
    this.validator,
    this.onChanged,
    this.borderRadius,
    this.prefixIconPath,
    this.suffixIconPath,
    this.prefixIconColor,
    this.inputFormatters,
    this.contentPadding,
    this.onFieldSubmitted,
    this.isError = false,
    this.errorBorderColor,
    this.focusNode,
    this.fillColor,
    this.keyboardType,
    this.hintStyle,
    this.borderColor,
    this.borderWidth,
    this.focusedBorderColor,
    this.enabledBorderColor,
    this.disabledBorderColor,
    this.suffixIconColor,
    this.suffixIconSize,
    this.errorText,
    this.autovalidateMode,
  });

  final TextEditingController textEditingController;
  final String? hintText;
  final BorderRadius? borderRadius;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final String? prefixIconPath;
  final String? suffixIconPath;
  final Color? prefixIconColor;
  final Color? suffixIconColor;
  final EdgeInsetsGeometry? contentPadding;
  final List<TextInputFormatter>? inputFormatters;
  final bool isError;
  final Color? errorBorderColor;
  final FocusNode? focusNode;
  final Color? fillColor;
  final TextInputType? keyboardType;
  final TextStyle? hintStyle;
  final Color? borderColor;
  final double? borderWidth;
  final Color? focusedBorderColor;
  final Color? enabledBorderColor;
  final Color? disabledBorderColor;
  final VoidCallback? onTapSuffixIcon;
  final double? suffixIconSize;
  final bool showPrefixIcon;
  final bool showSuffixIcon;
  final String? label;
  final Color? labelColor;
  final double? labelFontSize;
  final Color? focusedLabelColor;
  final Color? focusedFillColor;
  final Color? focusedSuffixIconColor;
  final int maxLength;
  final String? Function(String?)? validator;
  final TextAlign textAlign;
  final String? errorText;
  final AutovalidateMode? autovalidateMode;

  @override
  State<UserInputField> createState() => _UserInputFieldState();
}

class _UserInputFieldState extends State<UserInputField> with RouteAware {
  late FocusNode _focusNode;
  bool _isInternalFocusNode = false;
  ModalRoute<dynamic>? _route;

  // ─── RouteAware lifecycle ───

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _isInternalFocusNode = true;
    }
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(UserInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_onFocusChanged);
      if (_isInternalFocusNode) {
        _focusNode.dispose();
        _isInternalFocusNode = false;
      }

      if (widget.focusNode != null) {
        _focusNode = widget.focusNode!;
      } else {
        _focusNode = FocusNode();
        _isInternalFocusNode = true;
      }
      _focusNode.addListener(_onFocusChanged);
    }
  }

  /// Subscribe to the RouteObserver when dependencies change
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute && _route != route) {
      if (_route != null) {
        PrayerTimes.appRouteObserver.unsubscribe(this);
      }
      _route = route;
      PrayerTimes.appRouteObserver.subscribe(this, route);
    }
  }

  /// Called when a route that was pushed on top is now popped —
  /// unfocuses the field so the keyboard doesn't reappear.
  @override
  void didPopNext() {
    _focusNode.unfocus();
  }

  void _onFocusChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    if (_route != null) {
      PrayerTimes.appRouteObserver.unsubscribe(this);
    }
    if (_isInternalFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final themeColor = context.color;

    final bool hasLengthFormatter =
        widget.inputFormatters?.any(
          (formatter) => formatter is LengthLimitingTextInputFormatter,
        ) ??
        false;

    final List<TextInputFormatter> formatters = [
      if (!hasLengthFormatter)
        LengthLimitingTextInputFormatter(widget.maxLength),
      ...(widget.inputFormatters ?? []),
    ];

    final isFocused = _focusNode.hasFocus;

    Widget inputField = TextFormField(
      style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w400),
      focusNode: _focusNode,
      textAlign: widget.textAlign,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      onTapOutside: (event) => FocusScope.of(context).unfocus(),
      cursorColor: theme.colorScheme.primary,
      keyboardType: widget.keyboardType ?? TextInputType.text,
      contextMenuBuilder: (context, editableTextState) {
        return CustomTextSelectionToolbar(
          anchors: editableTextState.contextMenuAnchors,
          editableTextState: editableTextState,
        );
      },
      controller: widget.textEditingController,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      inputFormatters: formatters,
      decoration: userInputDecoration(
        context: context,
        hintText: widget.hintText ?? '',
        contentPadding:
            widget.contentPadding ??
            (widget.showPrefixIcon
                ? const EdgeInsets.only(right: 15)
                : const EdgeInsets.only(left: 20, right: 15)),
        prefixIconColor: widget.prefixIconColor,
        prefixIconPath: widget.prefixIconPath ?? '',
        suffixIconPath: widget.suffixIconPath,
        showPrefixIcon: widget.showPrefixIcon,
        showSuffixIcon: widget.showSuffixIcon,
        suffixIconColor:
            (isFocused ? widget.focusedSuffixIconColor : null) ??
            widget.suffixIconColor,
        onTapSuffixIcon: widget.onTapSuffixIcon,
        suffixIconSize: widget.suffixIconSize,
        fillColor:
            (isFocused ? widget.focusedFillColor : null) ??
            widget.fillColor ??
            theme.inputDecorationTheme.fillColor,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(10),
        borderColor: widget.borderColor ?? PrayerTimeAppColor.primaryColor25,
        borderWidth: widget.borderWidth,
        focusedBorderColor: widget.focusedBorderColor ?? widget.borderColor,
        enabledBorderColor: widget.enabledBorderColor ?? widget.borderColor,
        disabledBorderColor: widget.disabledBorderColor ?? widget.borderColor,
        errorBorderColor: widget.isError
            ? (widget.errorBorderColor ?? PrayerTimeAppColor.errorColor)
            : null,
        focusedErrorBorderColor: widget.isError
            ? (widget.errorBorderColor ?? PrayerTimeAppColor.errorColor)
            : null,
        hintStyle: widget.hintStyle,
        errorText: widget.errorText,
      ),
    );

    if (widget.label != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.label!,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: widget.labelFontSize ?? fourteenPx,
              color: isFocused
                  ? (widget.focusedLabelColor ?? themeColor.primaryColor)
                  : (widget.labelColor ?? themeColor.titleColor),
            ),
          ),
          gapH8,
          inputField,
        ],
      );
    }

    return inputField;
  }
}
