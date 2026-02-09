import 'package:flutter/material.dart';
import 'package:prayer_times/core/config/prayer_time_app_screen.dart';
import 'package:prayer_times/core/static/ui_const.dart';
import 'package:prayer_times/core/utility/utility.dart';

class TranslationCenterSection extends StatelessWidget {
  const TranslationCenterSection({super.key});

  static const List<Map<String, String>> _translators = [
    {'name': 'English', 'initials': 'EN', 'flag': '🇬🇧'},
    {'name': 'English', 'initials': 'AR', 'flag': '🇬🇧'},
    {'name': 'English', 'initials': 'BN', 'flag': '🇬🇧'},
    {'name': 'English', 'initials': 'UR', 'flag': '🇬🇧'},
    {'name': 'English', 'initials': 'FR', 'flag': '🇬🇧'},
    {'name': 'English', 'initials': 'TR', 'flag': '🇬🇧'},
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Translation Center',
          style: theme.textTheme.bodyMedium!.copyWith(
            fontSize: sixteenPx,
            fontWeight: FontWeight.w600,
          ),
        ),
        gapH15,
        SizedBox(
          height: ninetyPx,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _translators.length,
            separatorBuilder: (_, _) => gapW15,
            itemBuilder: (context, index) {
              final translator = _translators[index];
              return _TranslatorItem(
                name: translator['name']!,
                initials: translator['initials']!,
                flag: translator['flag']!,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TranslatorItem extends StatelessWidget {
  const _TranslatorItem({
    required this.name,
    required this.initials,
    required this.flag,
  });

  final String name;
  final String initials;
  final String flag;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      width: sixtyFivePx,
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: twentySevenPx,
                backgroundColor: context.color.primaryColor100,
                child: Text(
                  initials,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    fontSize: fourteenPx,
                    fontWeight: FontWeight.w600,
                    color: context.color.primaryColor700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: sixPx),
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
