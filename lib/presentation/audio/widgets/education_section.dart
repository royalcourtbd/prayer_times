import 'package:flutter/material.dart';
import 'package:prayer_times/core/config/prayer_time_app_screen.dart';
import 'package:prayer_times/core/static/ui_const.dart';
import 'package:prayer_times/core/utility/utility.dart';

class EducationSection extends StatelessWidget {
  const EducationSection({super.key});

  static const List<Map<String, String>> _educators = [
    {'name': 'Khalid Al-Farouqi', 'initials': 'KF'},
    {'name': 'Zayd Al-Mansoori', 'initials': 'ZM'},
    {'name': 'Omar Al-Basri', 'initials': 'OB'},
    {'name': 'Yusuf Al-Qahtani', 'initials': 'YQ'},
    {'name': 'Ibrahim Al-Dosari', 'initials': 'ID'},
  ];

  static const List<Color> _avatarColors = [
    Color(0xFFD4B896),
    Color(0xFFC9B8A0),
    Color(0xFFBFD0C8),
    Color(0xFFD0C4B0),
    Color(0xFFB8C8D8),
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'For Education',
          style: theme.textTheme.bodyMedium!.copyWith(
            fontSize: sixteenPx,
            fontWeight: FontWeight.w600,
          ),
        ),
        gapH15,
        SizedBox(
          height: hundredFifteenPx,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _educators.length,
            separatorBuilder: (_, _) => gapW12,
            itemBuilder: (context, index) {
              final educator = _educators[index];
              return _EducatorItem(
                name: educator['name']!,
                initials: educator['initials']!,
                avatarColor: _avatarColors[index % _avatarColors.length],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EducatorItem extends StatelessWidget {
  const _EducatorItem({
    required this.name,
    required this.initials,
    required this.avatarColor,
  });

  final String name;
  final String initials;
  final Color avatarColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      width: ninetyPx,
      child: Column(
        children: [
          CircleAvatar(
            radius: thirtySevenPx,
            backgroundColor: avatarColor,
            child: Text(
              initials,
              style: theme.textTheme.bodyMedium!.copyWith(
                fontSize: eighteenPx,
                fontWeight: FontWeight.w600,
                color: context.color.blackColor700,
              ),
            ),
          ),
          SizedBox(height: eightPx),
          Text(
            name,
            style: theme.textTheme.bodyMedium!.copyWith(
              fontSize: elevenPx,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
