import 'package:prayer_times/core/base/base_entity.dart';

class AppUpdateEntity extends BaseEntity {
  final String changeLogs;
  final bool forceUpdate;
  final String latestVersion;
  final String minSupportedVersion;
  final String title;
  final String storeUrl;
  final String iosStoreUrl;

  const AppUpdateEntity({
    required this.changeLogs,
    required this.forceUpdate,
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.title,
    required this.storeUrl,
    required this.iosStoreUrl,
  });

  @override
  List<Object?> get props => [
    changeLogs,
    forceUpdate,
    latestVersion,
    minSupportedVersion,
    title,
    storeUrl,
    iosStoreUrl,
  ];
}
