import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:prayer_times/core/base/base_presenter.dart';
import 'package:prayer_times/core/di/service_locator.dart';
import 'package:prayer_times/core/external_libs/flutter_toast/debouncer.dart';
import 'package:prayer_times/core/static/constants.dart';
import 'package:prayer_times/core/utility/utility.dart';
import 'package:prayer_times/data/datasources/local/location_local_data_source.dart';
import 'package:prayer_times/domain/entities/country_entity.dart';
import 'package:prayer_times/domain/entities/location_entity.dart';
import 'package:prayer_times/domain/usecases/get_countries_usecase.dart';
import 'package:prayer_times/domain/usecases/get_juristic_method_usecase.dart';
import 'package:prayer_times/domain/usecases/search_countries_usecase.dart';
import 'package:prayer_times/domain/usecases/update_juristic_method_usecase.dart';
import 'package:prayer_times/presentation/home/presenter/home_presenter.dart';
import 'package:prayer_times/presentation/settings/presenter/settings_page_ui_state.dart';
import 'package:prayer_times/presentation/settings/widgets/juristic_method_bottom_sheet.dart';
import 'package:prayer_times/presentation/settings/widgets/select_location_bottomsheet.dart';

class SettingsPagePresenter extends BasePresenter<SettingsPageUiState> {
  final GetJuristicMethodUseCase _getJuristicMethodUseCase;
  final UpdateJuristicMethodUseCase _updateJuristicMethodUseCase;
  final GetCountriesUseCase _getCountriesUseCase;
  final SearchCountriesUseCase _searchCountriesUseCase;
  final LocationLocalDataSource _locationLocalDataSource;

  SettingsPagePresenter(
    this._getJuristicMethodUseCase,
    this._updateJuristicMethodUseCase,
    this._getCountriesUseCase,
    this._searchCountriesUseCase,
    this._locationLocalDataSource,
  );

  final Obs<SettingsPageUiState> uiState = Obs(SettingsPageUiState.empty());
  SettingsPageUiState get currentUiState => uiState.value;

  final HomePresenter _homePresenter = locate<HomePresenter>();

  final TextEditingController countryController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final _searchDebouncer = Debouncer(milliseconds: 500);

  // Track if location was saved (for onboarding navigation)
  bool _locationActionTaken = false;
  bool get wasLocationActionTaken => _locationActionTaken;
  void resetLocationActionFlag() => _locationActionTaken = false;

  @override
  void onInit() {
    _loadJuristicMethod();
    _loadCountries();
    super.onInit();
  }

  Future<void> _loadJuristicMethod() async {
    await executeTaskWithLoading(() async {
      await parseDataFromEitherWithUserMessage(
        task: () => _getJuristicMethodUseCase.execute(),
        onDataLoaded: (String method) {
          if (method.isNotEmpty) {
            uiState.value = currentUiState.copyWith(
              selectedJuristicMethod: method,
            );
          }
        },
      );
    });
  }

  Future<void> onJuristicMethodChanged({
    required String method,
    VoidCallback? onPrayerTimeUpdateRequired,
  }) async {
    await executeTaskWithLoading(() async {
      await parseDataFromEitherWithUserMessage(
        task: () => _updateJuristicMethodUseCase.execute(method: method),
        onDataLoaded: (_) async {
          uiState.value = currentUiState.copyWith(
            selectedJuristicMethod: method,
          );
          onPrayerTimeUpdateRequired?.call();
        },
      );
    });
  }

  String showLocationName() {
    return _homePresenter.currentUiState.location?.placeName ?? '';
  }

  void showJuristicMethodBottomSheet(BuildContext context) {
    JuristicMethodBottomSheet.show(context: context, presenter: this);
  }

  void showSelectLocationBottomSheet(BuildContext context) {
    SelectLocationBottomsheet.show(context: context);
  }

  Future<void> showSelectLocationBottomSheetAsync(BuildContext context) async {
    await SelectLocationBottomsheet.show(context: context);
  }

  void onManualLocationSelected({required bool isManualLocationSelected}) {
    uiState.value = currentUiState.copyWith(
      isManualLocationSelected: isManualLocationSelected,
    );
  }

  Future<void> onUseCurrentLocationSelected(BuildContext context) async {
    onManualLocationSelected(isManualLocationSelected: false);
    _locationActionTaken = true;

    // Close the bottom sheet first
    if (context.mounted) {
      context.navigatorPop();
    }
    clearControllers();

    // Force refresh from GPS after bottomsheet animation completes
    Future.delayed(const Duration(milliseconds: 300), () {
      _homePresenter.refreshLocationAndPrayerTimes();
    });
  }

  Future<void> onSaveLocationSelected(BuildContext context) async {
    if (currentUiState.isManualLocationSelected) {
      // Find the selected city from the list
      final selectedCityName = currentUiState.selectedCity;
      if (selectedCityName.isEmpty) {
        showMessage(message: 'Please select a city');
        return;
      }

      final selectedCity = currentUiState.selectedCountryCities.firstWhere(
        (city) => city.name == selectedCityName,
        orElse: () => CityNameEntity(
          name: '',
          timezone: '',
          latitude: 0,
          longitude: 0,
        ),
      );

      if (selectedCity.name.isEmpty) {
        showMessage(message: 'City not found');
        return;
      }

      // Create LocationEntity from selected city - including timezone
      final location = LocationEntity(
        latitude: selectedCity.latitude,
        longitude: selectedCity.longitude,
        placeName: '${selectedCity.name}, ${currentUiState.selectedCountry}',
        timezone: selectedCity.timezone,
      );

      // Cache the location
      await _locationLocalDataSource.cacheLocation(location);
      _locationActionTaken = true;

      // Close the bottom sheet first
      if (context.mounted) {
        context.navigatorPop();
      }
      clearControllers();

      // Load prayer times after bottomsheet animation completes
      Future.delayed(const Duration(milliseconds: 300), () {
        _homePresenter.loadLocationAndPrayerTimes();
      });
      return;
    }

    if (context.mounted) {
      context.navigatorPop();
    }
    clearControllers();
  }

  void clearControllers() {
    countryController.clear();
    cityController.clear();
  }

  Future<void> get loadCountries => _loadCountries();

  Future<void> _loadCountries() async {
    await executeTaskWithLoading(() async {
      await parseDataFromEitherWithUserMessage(
        task: () => _getCountriesUseCase.execute(),
        onDataLoaded: (List<CountryNameEntity> countries) {
          uiState.value = currentUiState.copyWith(countries: countries);
        },
      );
    });
  }

  Future<void> onSearchQueryChanged({required String searchQuery}) async {
    _searchDebouncer.run(() async {
      countryController.text = searchQuery;

      if (searchQuery.isEmpty) {
        await _loadCountries();
        return;
      }

      await executeTaskWithLoading(() async {
        await parseDataFromEitherWithUserMessage(
          task: () => _searchCountriesUseCase.execute(searchQuery: searchQuery),
          onDataLoaded: (List<CountryNameEntity> countries) {
            uiState.value = currentUiState.copyWith(countries: countries);
          },
        );
      });
    });
  }

  Future<void> onCitySearchQueryChanged({required String searchQuery}) async {
    _searchDebouncer.run(() {
      cityController.text = searchQuery;

      final filteredCities = currentUiState.selectedCountryCities
          .where(
            (city) =>
                city.name.toLowerCase().contains(searchQuery.toLowerCase()),
          )
          .toList();

      uiState.value = currentUiState.copyWith(
        selectedCountryCities: filteredCities,
      );
    });
  }

  void onCountrySelected({required CountryNameEntity country}) {
    clearControllers();
    uiState.value = currentUiState.copyWith(
      selectedCountry: country.name,
      selectedCountryCities: country.cities,
      selectedCity: '',
    );
    countryController.text = country.name;
  }

  void onCitySelected({required CityNameEntity city}) {
    clearControllers();
    uiState.value = currentUiState.copyWith(selectedCity: city.name);
  }

  Future<void> onRatingClicked() {
    return openUrl(url: Platform.isIOS ? appStoreUrl : playStoreUrl);
  }

  Future<void> onShareAppTap() async {
    await shareText(text: playStoreUrl);
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
