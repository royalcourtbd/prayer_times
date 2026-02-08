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
/// - Review request count ও timing track করে
/// - Platform unavailable হলে store listing এ fallback
///
/// Note: In-app review dialog দেখানো platform এর discretion এ।
/// request করলেও dialog দেখানোর guarantee নেই।
class InAppReviewService {
  final InAppReview _inAppReview;
  final LocalCacheService _cacheService;

  InAppReviewService(this._inAppReview, this._cacheService);

  /// User এর কাছে in-app review request পাঠায়
  ///
  /// সফল হলে true, ব্যর্থ হলে false return করে।
  /// true return করলেও platform dialog না দেখাতে পারে।
  Future<bool> requestReview() async {
    return await catchAndReturnFuture<bool>(() async {
      final bool isAvailable = await _inAppReview.isAvailable();

      if (!isAvailable) {
        logDebugStatic('InAppReview: Not available on this device', 'InAppReviewService');
        return false;
      }

      await _inAppReview.requestReview();
      await _trackReviewRequest();

      logDebugStatic('InAppReview: Review requested successfully', 'InAppReviewService');
      return true;
    }) ?? false;
  }

  /// App store page open করে
  ///
  /// In-app review unavailable হলে fallback হিসেবে ব্যবহৃত হয়।
  Future<bool> openStoreListing() async {
    return await catchAndReturnFuture<bool>(() async {
      await _inAppReview.openStoreListing();
      logDebugStatic('InAppReview: Store listing opened', 'InAppReviewService');
      return true;
    }) ?? false;
  }

  /// Device এ in-app review available কিনা check করে
  Future<bool> isAvailable() async {
    return await catchAndReturnFuture<bool>(() async {
      return await _inAppReview.isAvailable();
    }) ?? false;
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
