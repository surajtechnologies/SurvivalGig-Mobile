# copilot_instrcutions.md

THIS FILE IS THE SINGLE SOURCE OF TRUTH.
ALL CODE GENERATED OR MODIFIED BY COPILOT OR ANY AI MUST FOLLOW THIS FILE STRICTLY.
IF CODE WORKS BUT VIOLATES THIS FILE, IT IS WRONG.
IF ANYTHING IS UNCLEAR, STOP AND ASK. DO NOT GUESS. DO NOT IMPROVISE.

==================================================
CORE PRINCIPLES (NON-NEGOTIABLE)
==================================================

- Clean Architecture + Feature-First ONLY
- One responsibility per layer
- Strict dependency direction (TOP → DOWN ONLY)
- UI, API, frameworks are replaceable details
- Consistency > Cleverness > Speed
- Predictable behavior is mandatory

==================================================
PROJECT BOUNDARIES
==================================================

NO application logic is allowed in:
android/
ios/
web/
macos/
windows/
linux/
test/

ALL application code MUST live inside lib/

==================================================
AUTHORITATIVE PROJECT STRUCTURE
==================================================

lib/
├── core/
│   ├── constants/
│   ├── theme/
│   ├── network/
│   ├── routing/
│   ├── errors/
│   └── utils/
├── features/
│   ├── auth/
│   ├── wallet/
│   ├── listings/
│   ├── trades/
│   ├── chat/
│   ├── profile/
│   └── admin/
├── shared/
│   ├── widgets/
│   └── models/
├── config/
│   ├── di/
│   └── env/
└── main.dart

NO deviations.
NO extra folders.
NO feature logic outside features/.

==================================================
FEATURE STRUCTURE (MANDATORY)
==================================================

feature_name/
├── data/
│   ├── models/
│   ├── datasources/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── presentation/
│   ├── screens/
│   ├── widgets/
│   └── cubit/
└── feature_module.dart

Missing folders OR extra folders = INVALID FEATURE.

==================================================
CLEAN ARCHITECTURE FLOW (ENFORCED)
==================================================

UI
→ Cubit
→ UseCase
→ Domain Repository (interface)
→ Data Repository (implementation)
→ Datasource
→ API / Firebase / DB

NO skipping layers.
NO reverse dependencies.
NO shortcuts.

==================================================
DOMAIN LAYER RULES (MOST CRITICAL)
==================================================

ALLOWED:
- Pure Dart only
- Entities
- Value objects
- UseCases
- Business rules

FORBIDDEN:
- Flutter imports
- Dio / Firebase / JSON
- API models
- BuildContext
- Annotations

RULES:
- One UseCase = One business action
- No orchestration usecases
- No god usecases

==================================================
DATA LAYER RULES (API ISOLATION)
==================================================

Datasources:
- Location: features/<feature>/data/datasources/
- Perform API / Firebase / DB calls ONLY
- Parse raw responses ONLY
- Throw API-specific exceptions ONLY
- NO business logic
- NO domain entities
- NO UI imports

Models (DTOs):
- Represent API contracts ONLY
- fromJson / toJson is MANDATORY
- NEVER exposed to UI or domain

Repositories:
- Implement domain repository interfaces
- Convert DTO → Entity
- Map data exceptions → domain failures

==================================================
NETWORKING RULES (DIO + INTERCEPTOR FINAL)
==================================================

GENERAL:
- Dio ONLY (MANDATORY)
- ONE shared Dio instance for entire app
- Created ONLY in:
  lib/core/network/dio_client.dart

FORBIDDEN:
- Creating Dio anywhere else
- Using http package
- Using print / debugPrint for API logging
- Logging inside datasources, repositories, cubits, widgets, or UI

--------------------------------------------------
BASE CONFIGURATION (MANDATORY)
--------------------------------------------------

- Base URL ONLY from config/env
- Mandatory timeouts:
  - connectTimeout
  - receiveTimeout
  - sendTimeout
- Headers configured centrally
- NO hardcoded URLs
- NO default Dio configuration

--------------------------------------------------
INTERCEPTORS (ORDER IS ABSOLUTE)
--------------------------------------------------

INTERCEPTORS MUST BE REGISTERED IN THIS EXACT ORDER:

1. AuthInterceptor
   - Attaches access token to every request
   - Handles token refresh automatically
   - Retries original request EXACTLY ONCE after refresh
   - NO UI interaction
   - NO navigation

2. LoggingInterceptor
   - Implemented ONLY as a Dio Interceptor
   - Enabled ONLY when kDebugMode == true
   - Logs:
     - HTTP method
     - URL
     - Request body
     - Response body
     - Error details
   - MUST mask:
     - access tokens
     - refresh tokens
     - secrets
     - credentials
   - MUST be COMPLETELY DISABLED in release builds

3. ErrorInterceptor
   - Converts DioError → AppException
   - Normalizes all error types
   - NO UI responsibility

--------------------------------------------------
ERROR NORMALIZATION (MANDATORY)
--------------------------------------------------

ALL network errors MUST be mapped to ONE of:
- NetworkException
- UnauthorizedException
- TimeoutException
- ServerException
- UnknownException

UI must NEVER see:
- Status codes
- DioError
- Raw API error messages
- Stack traces

--------------------------------------------------
RETRIES & CANCELLATION
--------------------------------------------------

- Retry logic ONLY inside interceptors
- Max retry count = 1
- Use CancelToken when explicitly required
- NO retry logic in datasources
- NO retry logic in cubits or UI

==================================================
PRESENTATION LAYER RULES
==================================================

Widgets:
- UI ONLY
- NO business logic
- NO API logic
- NO data mapping
- Widgets are DUMB by design

State Management:
- Cubit ONLY
- Naming: FeatureCubit, FeatureState
- States must be immutable
- States must be explicit
- Cubits call UseCases ONLY
- Cubits NEVER call repositories or APIs

==================================================
NAVIGATION RULES (FINAL & LOCKED)
==================================================

NAVIGATION IS ALLOWED ONLY INSIDE:
- Screens (presentation/screens)
- NEVER inside widgets, cubits, services, interceptors, or usecases

ONLY the following 3 navigation actions are allowed:

FORWARD (Push):
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => NextScreen()),
);

BACK (Pop):
Navigator.pop(context);

REPLACE (Present):
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (_) => NextScreen()),
);

WHEN TO USE:
- Push → normal forward navigation
- Pop → back navigation
- PushReplacement → splash → login, login → home, logout → login

FORBIDDEN:
- named routes
- go_router
- auto_route
- navigatorKey
- popUntil
- pushAndRemoveUntil
- navigation helpers
- navigation abstractions

CONSISTENCY RULE:
- If a screen already uses push / pop / replace,
  ALL future changes MUST continue using the SAME method.

If navigation choice is unclear → STOP.

==================================================
ERROR HANDLING FLOW (MANDATORY)
==================================================

API Error
→ Data Exception
→ Domain Failure
→ UI State

RULES:
- NO try-catch in widgets
- NO raw error strings in UI
- UI displays mapped, user-safe messages ONLY

==================================================
THEME, STYLES & ASSETS
==================================================

NEVER hardcode:
- Colors
- Text styles
- Font sizes
- Spacing
- Radius
- Asset paths

Must use:
- core/theme/
- core/constants/

==================================================
DEPENDENCY INJECTION
==================================================

- get_it ONLY
- All registrations in:
  lib/config/di/
- NO DI inside widgets
- NO global singletons

==================================================
NAMING CONVENTIONS
==================================================

- Files: snake_case.dart
- Classes: PascalCase
- Variables: camelCase
- Constants: const classes

==================================================
FORBIDDEN PRACTICES (AUTO-REJECT)
==================================================

- Business logic in widgets
- API calls in Cubit
- UI importing data models
- Feature logic in core
- God classes
- Mixed responsibilities
- Navigation outside screens
- Logging outside Dio interceptors

==================================================
COPILOT BEHAVIOR CONTRACT
==================================================

Copilot MUST:
- Follow this file literally
- Preserve existing architecture
- NEVER invent patterns
- NEVER refactor unless explicitly instructed

If ANY ambiguity exists:
STOP AND ASK. DO NOT DECIDE.

END OF FILE
