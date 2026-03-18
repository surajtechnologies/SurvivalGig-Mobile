# Clean Architecture Implementation

This document describes the Clean Architecture implementation following the copilot_instructions.md.

## Architecture Overview

The app follows **Clean Architecture** with **Feature-First** organization:

```
lib/
├── core/               # Shared infrastructure
│   ├── constants/     # App constants
│   ├── theme/         # Theme configuration
│   ├── network/       # Networking (Dio client)
│   ├── routing/       # Go Router configuration
│   ├── errors/        # Failures and exceptions
│   └── utils/         # Utility functions
├── features/          # Feature modules
│   └── auth/          # Authentication feature
│       ├── data/             # Data layer
│       │   ├── datasources/  # API calls (remote datasource)
│       │   ├── models/       # DTOs (Data Transfer Objects)
│       │   └── repositories/ # Repository implementations
│       ├── domain/           # Domain layer (Pure Dart)
│       │   ├── entities/     # Business entities
│       │   ├── repositories/ # Repository interfaces
│       │   └── usecases/     # Business use cases
│       └── presentation/     # Presentation layer
│           ├── cubit/        # State management (Cubit)
│           ├── screens/      # Screen widgets
│           └── widgets/      # Feature-specific widgets
├── shared/            # Shared widgets
│   └── widgets/       # Reusable UI components
├── config/            # Configuration
│   ├── di/            # Dependency injection
│   └── env/           # Environment config
└── main.dart          # App entry point
```

## Layer Responsibilities

### Domain Layer (Pure Dart - NO Flutter)
- **Entities**: Business objects (User, AuthToken)
- **Repository Interfaces**: Contracts for data access
- **UseCases**: Single business actions (LoginUseCase, RegisterUseCase)
- **Rules**: Business logic validation

### Data Layer
- **Models (DTOs)**: API contract representation (fromJson/toJson)
- **DataSources**: API/Database calls ONLY
- **Repository Implementations**: Implements domain interfaces, converts DTO ↔ Entity

### Presentation Layer
- **Cubit**: State management (extends BlocBase)
- **States**: UI states (Loading, Success, Failure)
- **Screens**: UI widgets consuming Cubit

## Data Flow

```
UI (Screen)
    ↓ calls
Cubit
    ↓ calls
UseCase (Domain)
    ↓ calls
Repository Interface (Domain)
    ↓ implemented by
Repository Implementation (Data)
    ↓ calls
DataSource (Data)
    ↓ calls
Dio Client (Core)
    ↓ makes
HTTP Request
```

## Networking Rules

### Dio Client (MANDATORY)
- Single shared instance in `lib/core/network/dio_client.dart`
- Base URL from `lib/config/env/app_config.dart`
- Configured timeouts: connect, receive, send

### Interceptors (Fixed Order)
1. **AuthInterceptor**: Attaches token, handles refresh
2. **LoggingInterceptor**: Logs requests/responses (debug only)

### Error Handling
```
API Error (Dio)
    ↓ caught by
DataSource
    ↓ throws
Exception (ServerException, NetworkException)
    ↓ caught by
Repository
    ↓ returns
Failure (ServerFailure, NetworkFailure)
    ↓ handled by
UseCase
    ↓ returns Either<Failure, Success>
    ↓ handled by
Cubit
    ↓ emits
State (Success/Failure)
    ↓ observed by
UI
```

## Dependency Injection

Using Service Locator pattern in `lib/config/di/service_locator.dart`:

```dart
void main() {
  sl.init();  // Initialize all dependencies
  runApp(const MyApp());
}
```

### Creating Cubit in Screens:
```dart
BlocProvider(
  create: (context) => sl.createAuthCubit(),
  child: MyScreen(),
)
```

## State Management

Using **flutter_bloc** with Cubit (not Bloc) for simplicity.

### Cubit Pattern:
```dart
// 1. Define states
abstract class AuthState extends Equatable {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class LoginSuccess extends AuthState {}
class AuthFailure extends AuthState {}

// 2. Create Cubit
class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  
  AuthCubit({required this.loginUseCase}) : super(AuthInitial());
  
  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    final result = await loginUseCase(email: email, password: password);
    result.fold(
      (failure) => emit(AuthFailure(message: failure.message)),
      (data) => emit(LoginSuccess(user: data.user)),
    );
  }
}

// 3. Use in UI
BlocConsumer<AuthCubit, AuthState>(
  listener: (context, state) {
    if (state is LoginSuccess) {
      // Navigate or show success
    } else if (state is AuthFailure) {
      // Show error
    }
  },
  builder: (context, state) {
    if (state is AuthLoading) {
      return CircularProgressIndicator();
    }
    return LoginForm();
  },
)
```

## Key Packages

- `dio`: HTTP client
- `pretty_dio_logger`: Request/response logging
- `flutter_secure_storage`: Secure token storage
- `flutter_bloc`: State management
- `dartz`: Functional programming (Either type)
- `equatable`: Value equality
- `go_router`: Declarative routing

## Migration Status

### ✅ Completed
- Core networking layer (DioClient)
- Domain layer (entities, repositories, usecases)
- Data layer (DTOs, datasources, repository implementations)
- Presentation layer (cubit, states)
- Dependency injection setup
- New login screen (LoginScreenNew)
- New signup screen (SignupScreenNew)
- Router updated to use new screens

### 📝 Old Files (To Be Removed)
- `lib/features/auth/data/repositories/auth_repository.dart` (old implementation)
- `lib/features/auth/data/models/user_model.dart` (old model)
- `lib/features/auth/data/models/login_models.dart` (old models)
- `lib/features/auth/data/models/register_models.dart` (old models)
- `lib/features/auth/presentation/screens/login_screen.dart` (old screen)
- `lib/features/auth/presentation/screens/signup_screen.dart` (old screen)
- `lib/core/network/api_client.dart` (old client)
- `lib/core/network/api_response.dart` (old response wrapper)

### 🔄 Active Files
- All files in `lib/features/auth/domain/` (NEW)
- `lib/features/auth/data/datasources/auth_remote_datasource.dart` (NEW)
- `lib/features/auth/data/models/*_dto.dart` (NEW)
- `lib/features/auth/data/repositories/auth_repository_impl.dart` (NEW)
- `lib/features/auth/presentation/cubit/` (NEW)
- `lib/features/auth/presentation/screens/*_new.dart` (NEW)
- `lib/core/network/dio_client.dart` (NEW)
- `lib/core/errors/` (NEW)
- `lib/config/` (NEW)

## Testing

To test the new implementation:

1. Run the app: `flutter run`
2. Navigate to login/signup screens
3. Try logging in / registering
4. Observe network logs in debug console
5. Verify state changes in UI

## Next Steps

1. Implement password reset feature
2. Add more features following same pattern
3. Remove old files after verification
4. Add unit tests for domain/data layers
5. Add widget tests for UI
