import 'package:flutter/material.dart';
import 'package:prayer_times/core/config/prayer_time_app_screen.dart';
import 'package:prayer_times/core/di/service_locator.dart';
import 'package:prayer_times/core/external_libs/presentable_widget_builder.dart';
import 'package:prayer_times/core/static/ui_const.dart';
import 'package:prayer_times/core/utility/utility.dart';
import 'package:prayer_times/presentation/common/animated_flip_counter.dart';
import 'package:prayer_times/presentation/event/pesenter/ramadan_countdown_presenter.dart';

class RamadanCountdownWidget extends StatelessWidget {
  RamadanCountdownWidget({super.key});

  final RamadanCountdownPresenter _presenter =
      locate<RamadanCountdownPresenter>();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return PresentableWidgetBuilder(
      presenter: _presenter,
      builder: () {
        if (!_presenter.currentUiState.shouldShow) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: twentyPx),
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: twentyPx),
            padding: padding15,
            decoration: BoxDecoration(
              color: context.color.primaryColor.withOpacityInt(0.05),
              borderRadius: radius18,
              border: Border.all(
                color: context.color.primaryColor.withOpacityInt(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _buildTitle(context, theme),
                gapH6,
                _buildSubtitle(context, theme),
                gapH16,
                _buildCountdownRow(context, theme),
                if (_presenter.currentUiState.isRamadan &&
                    _presenter.currentUiState.currentRamadanDay != null) ...[
                  gapH12,
                  _buildCurrentDayText(context, theme),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle(BuildContext context, ThemeData theme) {
    final bool isRamadan = _presenter.currentUiState.isRamadan;
    return Text(
      isRamadan ? 'Ramadan Mubarak' : 'Ramadan Countdown',
      style: theme.textTheme.titleMedium?.copyWith(
        color: context.color.primaryColor,
        fontWeight: FontWeight.bold,
        fontSize: eighteenPx,
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context, ThemeData theme) {
    final bool isRamadan = _presenter.currentUiState.isRamadan;
    return Text(
      isRamadan ? 'Ramadan ends in' : 'Ramadan starts in',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: context.color.subTitleColor,
        fontSize: thirteenPx,
      ),
    );
  }

  Widget _buildCountdownRow(BuildContext context, ThemeData theme) {
    final state = _presenter.currentUiState;

    return Row(
      children: [
        Expanded(
          child: _CountdownUnit(value: state.days, label: 'Days', theme: theme),
        ),
        gapW8,
        Expanded(
          child: _CountdownUnit(
            value: state.hours,
            label: 'Hours',
            theme: theme,
          ),
        ),
        gapW8,
        Expanded(
          child: _CountdownUnit(
            value: state.minutes,
            label: 'Minutes',
            theme: theme,
          ),
        ),
        gapW8,
        Expanded(
          child: _CountdownUnit(
            value: state.seconds,
            label: 'Seconds',
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentDayText(BuildContext context, ThemeData theme) {
    final int? currentDay = _presenter.currentUiState.currentRamadanDay;
    return Text(
      'Day $currentDay of Ramadan',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: context.color.primaryColor,
        fontWeight: FontWeight.w600,
        fontSize: fourteenPx,
      ),
    );
  }
}

class _CountdownUnit extends StatelessWidget {
  const _CountdownUnit({
    required this.value,
    required this.label,
    required this.theme,
  });

  final int value;
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: tenPx),
      decoration: BoxDecoration(
        border: Border.all(color: context.color.whiteColor, width: 1),
        color: context.color.whiteColor.withOpacityInt(0.5),
        borderRadius: radius12,
      ),
      child: Column(
        children: [
          AnimatedFlipCounter(
            value: value,
            wholeDigits: 2,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            textStyle: theme.textTheme.headlineSmall?.copyWith(
              color: context.color.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: twentyTwoPx,
            ),
          ),
          gapH4,
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.color.subTitleColor,
              fontSize: elevenPx,
            ),
          ),
        ],
      ),
    );
  }
}
