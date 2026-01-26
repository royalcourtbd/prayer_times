# AI Coding Assistant Instructions

## Project Architecture

This Flutter project follows **Clean Architecture** with a **feature-first** approach, implementing MVP (Model-View-Presenter) pattern using GetX for state management.

### Core Architecture Patterns

#### 1. Feature Structure

```
lib/features/{feature_name}/
├── data/
│   ├── datasource/          # Local/Remote data sources
│   └── repositories/        # Repository implementations
├── domain/
│   ├── entities/           # Business entities
│   ├── repositories/       # Repository interfaces
│   └── usecase/           # Business logic use cases
├── presentation/
│   ├── presenter/         # MVP Presenters + UI States
│   ├── ui/               # Flutter pages/screens
│   └── widgets/          # Feature-specific widgets
└── di/                   # Dependency injection setup
```

#### 2. Base Classes & Patterns

**Presenter Pattern**: All screens use `BasePresenter<UiState>` with reactive state management

```dart
class FeaturePresenter extends BasePresenter<FeatureUiState> {
  final Obs<FeatureUiState> uiState = Obs<FeatureUiState>(FeatureUiState.empty());
  FeatureUiState get currentUiState => uiState.value;

  // Override required methods from BasePresenter
  @override Future<void> addUserMessage(String message) async { /*...*/ }
  @override Future<void> toggleLoading({required bool loading}) async { /*...*/ }
}
```

**UI State Pattern**: Immutable state classes extending `BaseUiState`

```dart
class FeatureUiState extends BaseUiState {
  const FeatureUiState({required super.isLoading, required super.userMessage, /*custom props*/});
  factory FeatureUiState.empty() => FeatureUiState(isLoading: false, userMessage: '');
  FeatureUiState copyWith({/*props*/}) => FeatureUiState(/*...*/);
}
```

**Widget Integration**: Use `PresentableWidgetBuilder` for presenter-widget binding

```dart
class FeaturePage extends StatelessWidget {
  final FeaturePresenter _presenter = locate<FeaturePresenter>();

  Widget build(BuildContext context) {
    return PresentableWidgetBuilder(
      presenter: _presenter,
      builder: () => Scaffold(/* UI based on _presenter.currentUiState */),
    );
  }
}
```

#### 3. Dependency Injection

**Service Locator Pattern**: Uses GetIt with feature-specific DI modules

- Core services in `/core/di/setup/service_setup.dart`
- Feature DI in `/features/{name}/di/{name}_di.dart`
- Global setup in `/core/di/service_locator.dart`

**Registration Pattern**:

```dart
// In FeatureDi.setup(GetIt serviceLocator):
serviceLocator.registerLazySingleton<Repository>(() => RepositoryImpl(locate()));
serviceLocator.registerFactory(() => loadPresenter(FeaturePresenter()));
```

#### 4. Use Case Pattern

All business logic in use cases extending `BaseUseCase<ReturnType>`:

```dart
class FeatureUseCase extends BaseUseCase<ReturnType> {
  FeatureUseCase(super.errorMessageHandler);

  Future<Either<String, ReturnType>> execute() => mapResultToEither(() async {
    // Business logic here
    return result;
  });
}
```

### Key Development Workflows

#### 1. Code Generation

Use `create_page.py` script for feature scaffolding:

```bash
python3 create_page.py feature_name
```

This generates complete feature structure with presenter, UI state, DI setup, and boilerplate code.

#### 2. File Organization Rules

**Core Layer** (`/core/`):

- `/base/` - Abstract base classes (BasePresenter, BaseUseCase, BaseEntity)
- `/widgets/` - Framework utilities (PresentableWidgetBuilder)
- `/services/` - App-wide services (not external_libs)
- `/di/` - Dependency injection setup
- `/utility/` - Pure utility functions

**Shared Layer** (`/shared/`):

- `/widgets/` - Reusable UI components used across features
- `/models/` - Shared data models
- `/services/` - Cross-feature business services

**Never put**: Feature-specific logic in core, UI components in external_libs

#### 3. Error Handling & Logging

- Use `Either<String, T>` for error-prone operations
- BasePresenter provides `executeTaskWithLoading()`, `mapDataFromEitherWithUserMessage()`
- Log errors with `logError()` from logger_utility
- User messages via `addUserMessage()` in presenters

### Critical Dependencies & Integration

- **GetX**: State management (wrapped in PresentableWidgetBuilder)
- **GetIt**: Service location (accessed via `locate<T>()`)
- **fpdart**: Functional programming (Either, Option)
- **Firebase**: Backend services in `BackendAsAService`
- **Drift**: Local database (structured in data layer)

### Testing Patterns

- Mock repositories in domain layer
- Test use cases with `mapResultToEither` pattern
- Mock presenters for UI testing
- Use `Either.left()` for error scenarios

### Common Gotchas

1. **Always register presenters with `loadPresenter()`** in DI setup
2. **Import from `core/base/base_export.dart`** for base classes
3. **Use `locate<T>()` not GetIt directly** for service location
4. **Override both `addUserMessage` and `toggleLoading`** in presenters
5. **Include `copyWith` method** in all UI state classes
