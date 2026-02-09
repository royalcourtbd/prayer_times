import 'package:flutter/material.dart';
import 'package:prayer_times/core/config/prayer_time_app_screen.dart';
import 'package:prayer_times/core/static/ui_const.dart';
import 'package:prayer_times/core/utility/utility.dart';

class TopPickSection extends StatelessWidget {
  const TopPickSection({super.key});

  static const List<Map<String, String>> _topPicks = [
    {
      'name': 'Ahmed Alshafey',
      'subtitle': 'The Voice of Serenity',
      'initials': 'AA',
    },
    {
      'name': 'Zain Al-Abdeen',
      'subtitle': 'The Melodic Heart',
      'initials': 'ZA',
    },
    {
      'name': 'Abdelaziz AlGaraani',
      'subtitle': 'The Echo of Wisdom',
      'initials': 'AG',
    },
    {
      'name': 'Omar Al-Farouq',
      'subtitle': 'The Whispering Soul',
      'initials': 'OF',
    },
  ];

  static const List<Color> _avatarColors = [
    Color(0xFFE8D5B7),
    Color(0xFFBFD8E8),
    Color(0xFFD4C5A9),
    Color(0xFFC8D5C3),
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Pick',
          style: theme.textTheme.bodyMedium!.copyWith(
            fontSize: sixteenPx,
            fontWeight: FontWeight.w600,
          ),
        ),
        gapH15,
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: twelvePx,
            mainAxisSpacing: sixteenPx,
            childAspectRatio: 2.4,
          ),
          itemCount: _topPicks.length,
          itemBuilder: (context, index) {
            final pick = _topPicks[index];
            return _TopPickItem(
              name: pick['name']!,
              subtitle: pick['subtitle']!,
              initials: pick['initials']!,
              avatarColor: _avatarColors[index % _avatarColors.length],
            );
          },
        ),
      ],
    );
  }
}

class _TopPickItem extends StatelessWidget {
  const _TopPickItem({
    required this.name,
    required this.subtitle,
    required this.initials,
    required this.avatarColor,
  });

  final String name;
  final String subtitle;
  final String initials;
  final Color avatarColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      children: [
        CircleAvatar(
          radius: twentyFourPx,
          backgroundColor: avatarColor,
          child: Text(
            initials,
            style: theme.textTheme.bodyMedium!.copyWith(
              fontSize: thirteenPx,
              fontWeight: FontWeight.w600,
              color: context.color.blackColor700,
            ),
          ),
        ),
        SizedBox(width: eightPx),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.bodyMedium!.copyWith(
                  fontSize: twelvePx,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: twoPx),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium!.copyWith(
                  fontSize: elevenPx,
                  color: context.color.subTitleColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
