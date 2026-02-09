import 'package:flutter/material.dart';
import 'package:prayer_times/core/config/prayer_time_app_screen.dart';
import 'package:prayer_times/core/static/ui_const.dart';
import 'package:prayer_times/presentation/audio/widgets/education_section.dart';
import 'package:prayer_times/presentation/audio/widgets/custom_search_bar.dart';
import 'package:prayer_times/presentation/audio/widgets/top_pick_section.dart';
import 'package:prayer_times/presentation/audio/widgets/translation_center_section.dart';
import 'package:prayer_times/presentation/common/custom_app_bar.dart';

class AudioPage extends StatelessWidget {
  const AudioPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Audio Recitation',
        theme: theme,
        isRoot: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: twentyPx),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              gapH10,
              CustomSearchBar(
                searchController: TextEditingController(),
                hintText: 'Search by reciter name',
              ),
              gapH25,
              const TranslationCenterSection(),
              gapH25,
              const TopPickSection(),
              gapH25,
              const EducationSection(),
              gapH30,
            ],
          ),
        ),
      ),
    );
  }
}
