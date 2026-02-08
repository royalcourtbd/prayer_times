import 'dart:io';

import 'package:flutter/material.dart';
import 'package:prayer_times/core/base/base_presenter.dart';
import 'package:prayer_times/core/static/constants.dart';
import 'package:prayer_times/core/utility/utility.dart';
import 'package:prayer_times/presentation/main/presenter/menu_drawer_ui_state.dart';

class MenuDrawerPresenter extends BasePresenter<MenuDrawerUiState> {
  final Obs<MenuDrawerUiState> uiState = Obs(MenuDrawerUiState.empty());

  MenuDrawerUiState get currentUiState => uiState.value;

  Future<void> onRatingClicked() {
    return openUrl(url: Platform.isIOS ? appStoreUrl : playStoreUrl);
  }

  Future<void> onShareAppTap() async {
    await shareText(text: playStoreUrl);
  }

  Future<void> onPrivacyPolicyClicked() {
    return openUrl(url: privacyPolicyUrl);
  }

  Future<void> onPlayStoreLinkClicked(BuildContext context) =>
      _onPromotionInteraction(
        onInternet: (url) => openUrl(url: url),
        onNoInternet: () => addUserMessage('No internet connection available'),
      );

  Future<void> _onPromotionInteraction({
    required void Function(String promotionUrl) onInternet,
    required VoidCallback onNoInternet,
  }) async {
    final bool isNetworkAvailable = await checkInternetConnection();
    if (!isNetworkAvailable) {
      onNoInternet();
      return;
    }
    onInternet(suitableAppStoreUrl);
  }

  @override
  Future<void> addUserMessage(String message) async {
    uiState.value = currentUiState.copyWith(userMessage: message);
    showMessage(message: currentUiState.userMessage);
  }

  @override
  Future<void> toggleLoading({required bool loading}) async {
    uiState.value = currentUiState.copyWith(isLoading: loading);
  }
}
