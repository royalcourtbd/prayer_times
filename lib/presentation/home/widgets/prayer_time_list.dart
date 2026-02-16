import 'package:flutter/material.dart';
import 'package:prayer_times/core/config/prayer_time_app_screen.dart';
import 'package:prayer_times/presentation/home/models/waqt.dart';
import 'package:prayer_times/presentation/home/widgets/prayer_time_list_item.dart';

class PrayerTimeList extends StatelessWidget {
  const PrayerTimeList({
    super.key,
    required this.theme,
    required this.waqtList,
    required this.scrollController,
    this.onTapVolume,
    this.adjustmentEnabledMap = const {},
  });

  final ThemeData theme;
  final List<WaqtViewModel> waqtList;
  final ScrollController scrollController;
  final void Function(WaqtViewModel waqt)? onTapVolume;
  final Map<WaqtType, bool> adjustmentEnabledMap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 29.percentWidth,
      child: ListView.builder(
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        shrinkWrap: true,
        itemCount: waqtList.length,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(left: twentyPx),
        itemBuilder: (context, index) {
          final WaqtViewModel waqt = waqtList[index];
          if (waqt.type == WaqtType.duha) {
            return const SizedBox.shrink();
          }
          return PrayerTimeListItem(
            theme: theme,
            waqt: waqt,
            isLastItem: index == waqtList.length - 1,
            isAdjustmentEnabled: adjustmentEnabledMap[waqt.type] ?? false,
            onTapVolume: onTapVolume != null
                ? () => onTapVolume!(waqt)
                : null,
          );
        },
      ),
    );
  }
}
