import 'package:prayer_times/domain/entities/app_update_entity.dart';

class AppUpdateModel extends AppUpdateEntity {
  const AppUpdateModel({
    required super.changeLogs,
    required super.forceUpdate,
    required super.latestVersion,
    required super.minSupportedVersion,
    required super.title,
    required super.storeUrl,
    required super.iosStoreUrl,
  });

  factory AppUpdateModel.fromJson(Map<String, dynamic> json) {
    return AppUpdateModel(
      changeLogs: json['change_logs'] as String? ?? '',
      forceUpdate: json['force_update'] as bool? ?? false,
      latestVersion: json['latest_version'] as String? ?? '',
      minSupportedVersion: json['min_supported_version'] as String? ?? '',
      title: json['title'] as String? ?? '',
      storeUrl: json['store_url'] as String? ?? '',
      iosStoreUrl: json['ios_store_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'change_logs': changeLogs,
      'force_update': forceUpdate,
      'latest_version': latestVersion,
      'min_supported_version': minSupportedVersion,
      'title': title,
      'store_url': storeUrl,
      'ios_store_url': iosStoreUrl,
    };
  }
}
