import 'package:flutter/material.dart';
import 'package:prayer_times/core/config/prayer_time_app_screen.dart';
import 'package:prayer_times/domain/entities/event_entity.dart';
import 'package:prayer_times/presentation/event/widgets/govt_holiday_list_item.dart';

class GovtHolidayList extends StatelessWidget {
  const GovtHolidayList({
    super.key,
    required this.theme,
    required this.events,
  });

  final ThemeData theme;
  final List<EventEntity> events;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34.percentWidth,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        shrinkWrap: true,
        itemCount: events.length,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(left: twentyPx),
        itemBuilder: (context, index) {
          final EventEntity event = events[index];
          return GovtHolidayListItem(
            theme: theme,
            event: event,
            isLastItem: index == events.length - 1,
          );
        },
      ),
    );
  }
}
