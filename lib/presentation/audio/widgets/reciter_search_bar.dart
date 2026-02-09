import 'package:flutter/material.dart';
import 'package:prayer_times/core/config/prayer_time_app_screen.dart';
import 'package:prayer_times/core/external_libs/user_input_field/user_input_field.dart';
import 'package:prayer_times/core/static/svg_path.dart';
import 'package:prayer_times/core/utility/utility.dart';

class ReciterSearchBar extends StatelessWidget {
  const ReciterSearchBar({
    super.key,
    required TextEditingController searchController,
    this.onChanged,
  }) : _searchController = searchController;

  final TextEditingController _searchController;
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
      hintText: 'Search Reciter',
      borderColor: context.color.primaryColor.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(50),
    );
  }
}
