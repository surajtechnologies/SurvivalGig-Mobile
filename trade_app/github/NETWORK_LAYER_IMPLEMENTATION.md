# Network Layer Implementation

## Overview
This document describes the network layer implementation for the BarterX Trade App, based on the OpenAPI specification.

## Architecture

### Core Network Layer (`lib/core/network/`)

#### 1. **ApiEndpoints** (`api_endpoints.dart`)
- Contains all API endpoint constants
- Three base URLs: production, staging, and development
- Currently configured to use: `http://localhost:3000/v1`
- Organized by feature: auth, users, listings, trades, etc.

#### 2. **ApiResponse** (`api_response.dart`)
- Generic response wrapper matching OpenAPI schema
- Structure: `{status, data, error[]}`
- Status types: `success`, `failure`, `pending`
- Includes `ApiError` model and error code constants
- User-friendly error message mapping

#### 3. **ApiClient** (`api_client.dart`)
- HTTP client wrapper for making API requests
- Methods: `get()`, `post()`, `patch()`, `delete()`
- Automatic JWT token management using `flutter_secure_storage`
- Automatic error handling and response parsing
- Network exception handling (no internet, connection errors)

### Authentication Feature (`lib/features/auth/data/`)

#### Models (`models/`)
- **user_model.dart**: Full User and PublicUser models
- **login_models.dart**: LoginRequest, LoginResponse, User
- **register_models.dart**: RegisterRequest, RegisterResponse, User

#### Repository (`repositories/`)
- **auth_repository.dart**: Authentication operations
  - `login()` - Email/password authentication
  - `register()` - User registration
  - `logout()` - Clear tokens
  - `forgotPassword()` - Request password reset
  - `resetPassword()` - Reset with token
  - `changePassword()` - Change for authenticated user
  - `verifyEmail()` - Email verification
  - `resendVerification()` - Resend verification email
  - `isAuthenticated()` - Check auth status

### Login Screen Integration

The login screen (`lib/features/auth/presentation/screens/login_screen.dart`) now:
- Uses `AuthRepository` for API calls
- Handles API errors with user-friendly messages
- Stores JWT tokens securely
- Navigates to home on successful login

## Dependencies Added

```yaml
dependencies:
  http: ^1.2.0                        # HTTP client
  flutter_secure_storage: ^9.2.2     # Secure token storage
  provider: ^6.1.2                   # State management
```

## Usage Example

```dart
// Initialize repository
final authRepository = AuthRepository();

// Login
try {
  await authRepository.login(
    email: 'user@example.com',
    password: 'password123',
  );
  // Tokens are automatically stored
  // Navigate to home
} on ApiException catch (e) {
  // Handle error
  print(e.userMessage);
}

// Check if authenticated
final isAuth = await authRepository.isAuthenticated();

// Logout
await authRepository.logout();
```

## Error Handling

### Error Codes
The API returns standardized error codes:
- `VALIDATION_ERROR` - Input validation failed
- `INVALID_AUTH_TOKEN` - Invalid or expired token
- `ACCOUNT_BANNED` - User account is banned
- `EMAIL_NOT_VERIFIED` - Email needs verification
- `INSUFFICIENT_BALANCE` - Not enough points
- `NO_INTERNET` - Network unavailable
- `CONNECTION_ERROR` - Server unreachable

### User-Friendly Messages
The `ApiException` class provides `userMessage` property that converts error codes to readable messages.

## Security

1. **JWT Token Storage**: Tokens stored in `flutter_secure_storage`
2. **Automatic Auth Headers**: `Authorization: Bearer <token>` added automatically
3. **Token Lifecycle**: Login stores, logout clears tokens
4. **Secure Endpoints**: `requiresAuth` parameter controls authentication

## API Configuration

To change the API environment, update `ApiEndpoints.baseUrl`:

```dart
// Development (local)
static const String baseUrl = developmentBaseUrl;

// Staging
static const String baseUrl = stagingBaseUrl;

// Production
static const String baseUrl = productionBaseUrl;
```

## Next Steps

1. Implement social authentication (Google, Apple, Facebook)
2. Add refresh token logic
3. Create user profile screens
4. Implement listing and trade features
5. Add state management with Provider
6. Create API interceptors for logging
7. Add retry logic for failed requests

## File Structure

```
lib/
├── core/
│   └── network/
│       ├── api_client.dart          # HTTP client
│       ├── api_endpoints.dart       # Endpoint constants
│       └── api_response.dart        # Response models
└── features/
    └── auth/
        ├── data/
        │   ├── models/
        │   │   ├── login_models.dart
        │   │   ├── register_models.dart
        │   │   └── user_model.dart
        │   └── repositories/
        │       └── auth_repository.dart
        └── presentation/
            └── screens/
                └── login_screen.dart
```
