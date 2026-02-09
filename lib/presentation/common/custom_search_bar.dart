import 'package:flutter/material.dart';
import 'package:prayer_times/core/config/prayer_time_app_screen.dart';
import 'package:prayer_times/core/external_libs/user_input_field/user_input_field.dart';
import 'package:prayer_times/core/static/svg_path.dart';
import 'package:prayer_times/core/utility/utility.dart';

class CustomSearchBar extends StatelessWidget {
  const CustomSearchBar({
    super.key,
    required TextEditingController searchController,
    required this.hintText,
    this.onChanged,
  }) : _searchController = searchController;

  final TextEditingController _searchController;
  final String hintText;
  final Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return UserInputField(
      textEditingController: _searchController,
      hintStyle: theme.textTheme.bodyMedium!.copyWith(
        fontSize: fourteenPx,
        color: context.color.placeHolderColor,
      ),
      onChanged: onChanged,
      prefixIconPath: SvgPath.icSearch,
      prefixIconColor: context.color.primaryColor,
      hintText: hintText,
      borderColor: context.color.primaryColor.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(50),
    );
  }
}
