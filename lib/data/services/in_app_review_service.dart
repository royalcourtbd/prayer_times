import 'package:in_app_review/in_app_review.dart';
import 'package:prayer_times/core/utility/logger_utility.dart';
import 'package:prayer_times/core/utility/trial_utility.dart';
import 'package:prayer_times/data/services/local_cache_service.dart';

/// InAppReviewService - In-app review functionality manage করে
///
/// এই service native platform review dialog (Google Play Store / Apple App Store)
/// ব্যবহার করে user এর কাছে review request পাঠায়।
///
/// Features:
/// - Native in-app review dialog request
/// - Smart trigger: launch count + days since install + cooldown
/// - Review request count ও timing track করে
/// - Platform unavailable হলে store listing এ fallback
///
/// Note: In-app review dialog দেখানো platform এর discretion এ।
/// request করলেও dialog দেখানোর guarantee নেই।
class InAppReviewService {
  final InAppReview _inAppReview;
  final LocalCacheService _cacheService;

  static const int _minLaunchCount = 15;
  static const int _minDaysSinceFirstLaunch = 3;
  static const int _cooldownDays = 60;

  InAppReviewService(this._inAppReview, this._cacheService);

  /// App launch count increment করে এবং first launch date record করে
  ///
  /// প্রতিটি app session এ একবার call হবে।
  Future<void> trackAppLaunch() async {
    await catchFutureOrVoid(() async {
      final int currentCount = _cacheService.getData<int>(
            key: CacheKeys.launchCount,
          ) ??
          0;

      await _cacheService.saveData<int>(
        key: CacheKeys.launchCount,
        value: currentCount + 1,
      );

      // প্রথমবার launch হলে date save করা
      final int? firstLaunchDate = _cacheService.getData<int>(
        key: CacheKeys.firstLaunchDate,
      );

      if (firstLaunchDate == null) {
        await _cacheService.saveData<int>(
          key: CacheKeys.firstLaunchDate,
          value: DateTime.now().millisecondsSinceEpoch,
        );
      }
    });
  }

  /// Smart trigger conditions check করে review request দেখানো উচিত কিনা
  ///
  /// Conditions:
  /// 1. Launch count >= 15
  /// 2. First launch থেকে >= 3 দিন পার হয়েছে
  /// 3. Last review request থেকে >= 60 দিন পার হয়েছে (বা আগে কখনো request হয়নি)
  bool shouldRequestReview() {
    return catchAndReturn<bool>(() {
      final int launchCount = _cacheService.getData<int>(
            key: CacheKeys.launchCount,
          ) ??
          0;
      if (launchCount < _minLaunchCount) return false;

      final int? firstLaunchMs = _cacheService.getData<int>(
        key: CacheKeys.firstLaunchDate,
      );
      if (firstLaunchMs == null) return false;

      final DateTime firstLaunch =
          DateTime.fromMillisecondsSinceEpoch(firstLaunchMs);
      final int daysSinceFirstLaunch =
          DateTime.now().difference(firstLaunch).inDays;
      if (daysSinceFirstLaunch < _minDaysSinceFirstLaunch) return false;

      final int? lastReviewMs = _cacheService.getData<int>(
        key: CacheKeys.lastReviewRequestTime,
      );
      if (lastReviewMs != null) {
        final DateTime lastReview =
            DateTime.fromMillisecondsSinceEpoch(lastReviewMs);
        final int daysSinceLastReview =
            DateTime.now().difference(lastReview).inDays;
        if (daysSinceLastReview < _cooldownDays) return false;
      }

      return true;
    }) ??
        false;
  }

  /// Smart conditions পূরণ হলে automatically review request পাঠায়
  ///
  /// App launch এ call হয়। Conditions মিললে native dialog দেখায়।
  Future<void> requestReviewIfEligible() async {
    await catchFutureOrVoid(() async {
      if (!shouldRequestReview()) return;

      logDebugStatic(
        'InAppReview: Eligible for review, requesting...',
        'InAppReviewService',
      );
      await requestReview();
    });
  }

  /// User এর কাছে in-app review request পাঠায়
  ///
  /// সফল হলে true, ব্যর্থ হলে false return করে।
  /// true return করলেও platform dialog না দেখাতে পারে।
  Future<bool> requestReview() async {
    return await catchAndReturnFuture<bool>(() async {
      final bool isAvailable = await _inAppReview.isAvailable();

      if (!isAvailable) {
        logDebugStatic(
          'InAppReview: Not available on this device',
          'InAppReviewService',
        );
        return false;
      }

      await _inAppReview.requestReview();
      await _trackReviewRequest();

      logDebugStatic(
        'InAppReview: Review requested successfully',
        'InAppReviewService',
      );
      return true;
    }) ??
        false;
  }

  /// App store page open করে
  ///
  /// In-app review unavailable হলে fallback হিসেবে ব্যবহৃত হয়।
  Future<bool> openStoreListing() async {
    return await catchAndReturnFuture<bool>(() async {
      await _inAppReview.openStoreListing();
      logDebugStatic(
        'InAppReview: Store listing opened',
        'InAppReviewService',
      );
      return true;
    }) ??
        false;
  }

  /// Device এ in-app review available কিনা check করে
  Future<bool> isAvailable() async {
    return await catchAndReturnFuture<bool>(() async {
      return await _inAppReview.isAvailable();
    }) ??
        false;
  }

  /// Review request track করে analytics/limiting এর জন্য
  Future<void> _trackReviewRequest() async {
    await catchFutureOrVoid(() async {
      final int currentCount = _cacheService.getData<int>(
            key: CacheKeys.reviewRequestCount,
          ) ??
          0;

      await _cacheService.saveData<int>(
        key: CacheKeys.reviewRequestCount,
        value: currentCount + 1,
      );

      await _cacheService.saveData<int>(
        key: CacheKeys.lastReviewRequestTime,
        value: DateTime.now().millisecondsSinceEpoch,
      );
    });
  }

  /// মোট কতবার review request করা হয়েছে
  int get reviewRequestCount =>
      _cacheService.getData<int>(key: CacheKeys.reviewRequestCount) ?? 0;

  /// সর্বশেষ কখন review request করা হয়েছে (milliseconds since epoch)
  int? get lastReviewRequestTime =>
      _cacheService.getData<int>(key: CacheKeys.lastReviewRequestTime);
}
