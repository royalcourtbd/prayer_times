import 'dart:async';
import 'package:flutter/material.dart';
import 'package:prayer_times/core/base/base_presenter.dart';
import 'package:prayer_times/core/di/service_locator.dart';
import 'package:prayer_times/core/external_libs/flutter_toast/debouncer.dart';
import 'package:prayer_times/core/utility/utility.dart';
import 'package:prayer_times/data/datasources/local/location_local_data_source.dart';
import 'package:prayer_times/data/services/hijri_date_service.dart';
import 'package:prayer_times/domain/entities/country_entity.dart';
import 'package:prayer_times/domain/entities/location_entity.dart';
import 'package:prayer_times/domain/usecases/get_countries_usecase.dart';
import 'package:prayer_times/domain/usecases/get_calculation_method_usecase.dart';
import 'package:prayer_times/domain/usecases/get_juristic_method_usecase.dart';
import 'package:prayer_times/domain/usecases/search_countries_usecase.dart';
import 'package:prayer_times/domain/usecases/update_calculation_method_usecase.dart';
import 'package:prayer_times/domain/usecases/update_juristic_method_usecase.dart';
import 'package:prayer_times/presentation/home/presenter/home_presenter.dart';
import 'package:prayer_times/presentation/event/pesenter/event_presenter.dart';
import 'package:prayer_times/presentation/event/pesenter/ramadan_calendar_presenter.dart';
import 'package:prayer_times/presentation/settings/presenter/settings_page_ui_state.dart';
import 'package:prayer_times/presentation/settings/widgets/calcutation_method_bottom_sheet.dart';
import 'package:prayer_times/presentation/settings/widgets/juristic_method_bottom_sheet.dart';
import 'package:prayer_times/presentation/settings/widgets/select_location_bottomsheet.dart';

class SettingsPagePresenter extends BasePresenter<SettingsPageUiState> {
  final GetJuristicMethodUseCase _getJuristicMethodUseCase;
  final UpdateJuristicMethodUseCase _updateJuristicMethodUseCase;
  final GetCalculationMethodUseCase _getCalculationMethodUseCase;
  final UpdateCalculationMethodUseCase _updateCalculationMethodUseCase;
  final GetCountriesUseCase _getCountriesUseCase;
  final SearchCountriesUseCase _searchCountriesUseCase;
  final LocationLocalDataSource _locationLocalDataSource;
  final HijriDateService _hijriDateService;

  SettingsPagePresenter(
    this._getJuristicMethodUseCase,
    this._updateJuristicMethodUseCase,
    this._getCalculationMethodUseCase,
    this._updateCalculationMethodUseCase,
    this._getCountriesUseCase,
    this._searchCountriesUseCase,
    this._locationLocalDataSource,
    this._hijriDateService,
  );

  final Obs<SettingsPageUiState> uiState = Obs(SettingsPageUiState.empty());
  SettingsPageUiState get currentUiState => uiState.value;

  final HomePresenter _homePresenter = locate<HomePresenter>();
  final EventPresenter _eventPresenter = locate<EventPresenter>();
  final RamadanCalendarPresenter _ramadanCalendarPresenter =
      locate<RamadanCalendarPresenter>();

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
    _loadCalculationMethod();
    _loadCountries();
    _loadDayAdjustment();
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
          showMessage(message: 'Juristic method saved successfully');
        },
      );
    });
  }

  Future<void> _loadCalculationMethod() async {
    await executeTaskWithLoading(() async {
      await parseDataFromEitherWithUserMessage(
        task: () => _getCalculationMethodUseCase.execute(),
        onDataLoaded: (String method) {
          if (method.isNotEmpty) {
            uiState.value = currentUiState.copyWith(
              selectedCalculationMethod: method,
            );
          }
        },
      );
    });
  }

  Future<void> onCalculationMethodChanged({
    required String method,
    VoidCallback? onPrayerTimeUpdateRequired,
  }) async {
    await executeTaskWithLoading(() async {
      await parseDataFromEitherWithUserMessage(
        task: () => _updateCalculationMethodUseCase.execute(method: method),
        onDataLoaded: (_) async {
          uiState.value = currentUiState.copyWith(
            selectedCalculationMethod: method,
          );
          onPrayerTimeUpdateRequired?.call();
          showMessage(message: 'Calculation method saved successfully');
        },
      );
    });
  }

  void _loadDayAdjustment() {
    uiState.value = currentUiState.copyWith(
      selectedDayAdjustment: _hijriDateService.dayAdjustment,
    );
  }

  Future<void> onDayAdjustmentChanged({required int value}) async {
    await _hijriDateService.saveDayAdjustment(value);
    uiState.value = currentUiState.copyWith(selectedDayAdjustment: value);
    _homePresenter.refreshLocationAndPrayerTimes();
    _eventPresenter.loadEvents();
    _ramadanCalendarPresenter.loadRamadanCalendar();
    showMessage(message: 'Day adjustment saved successfully');
  }

  void showCalculationMethodBottomSheet(BuildContext context) {
    CalculationMethodBottomSheet.show(context: context, presenter: this);
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

  Future<void> onSaveLocationSelected(BuildContext context) async {
    if (currentUiState.isManualLocationSelected) {
      await _saveManualLocation(context);
    } else {
      await _saveCurrentLocation(context);
    }
  }

  Future<void> _saveManualLocation(BuildContext context) async {
    final selectedCityName = currentUiState.selectedCity;
    if (selectedCityName.isEmpty) {
      showMessage(message: 'Please select a city');
      return;
    }

    final selectedCity = currentUiState.selectedCountryCities.firstWhere(
      (city) => city.name == selectedCityName,
      orElse: () =>
          CityNameEntity(name: '', timezone: '', latitude: 0, longitude: 0),
    );

    if (selectedCity.name.isEmpty) {
      showMessage(message: 'City not found');
      return;
    }

    final location = LocationEntity(
      latitude: selectedCity.latitude,
      longitude: selectedCity.longitude,
      placeName: '${selectedCity.name}, ${currentUiState.selectedCountry}',
      timezone: selectedCity.timezone,
    );

    await _locationLocalDataSource.cacheLocation(location);
    await _locationLocalDataSource.cacheLocationPreference(
      isManual: true,
      country: currentUiState.selectedCountry,
      city: selectedCityName,
    );
    _locationActionTaken = true;

    if (context.mounted) {
      context.navigatorPop();
    }
    clearControllers();

    Future.delayed(const Duration(milliseconds: 300), () {
      _homePresenter.loadLocationAndPrayerTimes();
      _ramadanCalendarPresenter.loadRamadanCalendar();
      showMessage(message: 'Location saved successfully');
    });
  }

  Future<void> _saveCurrentLocation(BuildContext context) async {
    try {
      await toggleLoading(loading: true);
      await _homePresenter.refreshLocationAndPrayerTimes();
      await _locationLocalDataSource.cacheLocationPreference(
        isManual: false,
        country: '',
        city: '',
      );
      _locationActionTaken = true;
      _ramadanCalendarPresenter.loadRamadanCalendar();
      await toggleLoading(loading: false);

      showMessage(message: 'Location updated successfully');
      if (context.mounted) {
        context.navigatorPop();
      }
      clearControllers();
    } catch (e) {
      await toggleLoading(loading: false);
      showMessage(message: 'Failed to get current location');
    }
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
          _restoreLocationPreference(countries);
        },
      );
    });
  }

  void _restoreLocationPreference(List<CountryNameEntity> countries) {
    final preference = _locationLocalDataSource.getCachedLocationPreference();
    if (preference == null || !preference.isManual) return;

    final countryName = preference.country;
    final cityName = preference.city;

    List<CityNameEntity> cities = [];
    if (countryName.isNotEmpty) {
      final matchingCountry = countries
          .where((c) => c.name == countryName)
          .firstOrNull;
      if (matchingCountry != null) {
        cities = matchingCountry.cities;
      }
    }

    uiState.value = currentUiState.copyWith(
      isManualLocationSelected: true,
      selectedCountry: countryName,
      selectedCity: cityName,
      selectedCountryCities: cities,
    );
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
