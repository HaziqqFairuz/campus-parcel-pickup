# Campus Parcel Pickup

A261 STTPK2143 Application Programming · Assignment 2 · Parcel Collection Management (Option 10)

Campus Parcel Pickup is a Flutter app for students and staff at a campus parcel desk. Students can register as **Recipients**. Staff use separately provisioned **Parcel Operator** accounts. Both roles share a dashboard that shows the authenticated user’s name, email, and role.

The assignment covers registration, sign-in, profile retrieval, session restoration, and sign-out. Parcel records and pickup status are planned for the Final Project.

## Run the app

Open the `parcel_collection_app` folder in VS Code with the Flutter and Dart extensions installed. Run `flutter pub get`. The project requires a Flutter SDK with Dart 3.13.5 or later in the Dart 3 series.

| VS Code launch option | How to use it |
| --- | --- |
| **Campus Parcel Pickup (StudentWebHost)** | Connect to the UUM network, select an Android device or emulator, and press F5. |
| **Campus Parcel Pickup (Chrome on StudentWebHost)** | Connect to the UUM network and press F5. Chrome opens the preview at `http://localhost:5200`, an origin allowed by the API. |
| **Campus Parcel Pickup (Android emulator)** | Start the local PHP server described below, select the emulator, and press F5. |

The app’s default API base is `http://10.19.5.233:8088/hzqqfairuz/`. Flutter reads it from [`lib/main.dart`](lib/main.dart). Use `--dart-define=API_BASE_URL=<base-url>` to override it. The app adds the endpoint filename to the base URL.

### Run the PHP backend locally

1. Install PHP 8.1 or later with the `pdo_sqlite` extension. Run `php -m` to check that the extension is enabled.
2. From the project folder, start PHP and leave the terminal open.

   ```powershell
   php -S 127.0.0.1:8787 -t backend/public
   ```

   With XAMPP on Windows, use `& C:/xampp/php/php.exe` in place of `php`. The Android emulator reaches the computer at `http://10.0.2.2:8787`.
3. Register a Recipient from the app. To create a test Parcel Operator, run the setup script in a second PowerShell 7 terminal.

   ```powershell
   $env:PARCEL_OPERATOR_PASSWORD = Read-Host 'Operator test password' -MaskInput
   php backend/private/create_operator.php 'Campus Parcel Operator' operator@example.test
   Remove-Item Env:PARCEL_OPERATOR_PASSWORD
   ```

The API initializes the SQLite schema in `backend/private/parcel.sqlite` when it first opens the database. Set `PARCEL_DB_PATH` in both terminals to use a different writable path outside the public web directory. Give the lecturer the test credentials separately.

### Build an Android APK

Run this from the project folder to build with the default StudentWebHost address.

```powershell
flutter build apk --release
```

The APK is saved at `build/app/outputs/flutter-apk/app-release.apk`. Use the UUM network when running this build. To build for the local Android emulator, add `--dart-define=API_BASE_URL=http://10.0.2.2:8787`.

## How authentication works

1. The splash screen runs for at least three seconds while Flutter checks for a saved session.
2. Registration validates the name, email, password, and confirmation. An existing email is rejected. Successful registration returns to the sign-in screen.
3. PHP verifies the password and issues a session token. Flutter uses that token to request the account profile and display the dashboard. Invalid sign-in attempts show an error that also directs new users to registration.
4. **Keep me signed in** saves the checkbox choice with SharedPreferences. When selected, Flutter Secure Storage saves the token so the server can validate it on the next launch.
5. Sign-out revokes the server session and removes the token from the device.

### API endpoints

Registration and sign-in accept form fields. The API returns JSON. Profile and sign-out requests use an `Authorization: Bearer <token>` header.

| Endpoint | Method | Input | Expected results |
| --- | --- | --- | --- |
| [`register.php`](backend/public/register.php) | POST | `name`, `email`, `password`, `confirm_password` | 201 created, 409 duplicate email, 422 invalid input |
| [`login.php`](backend/public/login.php) | POST | `email`, `password` | 200 with a session token, 401 invalid credentials |
| [`profile.php`](backend/public/profile.php) | GET | Bearer token | 200 with the account profile, 401 missing or invalid session |
| [`logout.php`](backend/public/logout.php) | POST | Bearer token | 200 after revocation, 401 missing or malformed token |

### SQLite storage

- **`users`** stores the account ID, name, case-insensitively unique email, bcrypt password hash, role, and registration timestamp. Public registration assigns the Recipient role.
- **`sessions`** stores the SHA-256 hash of each session token, the associated user ID, and a 24-hour expiration time. PHP uses prepared statements for account and session queries.

### StudentWebHost deployment

The four hosted endpoints load `parcel_auth.php` from the same directory. It is the hosted version of [`backend/private/auth.php`](backend/private/auth.php) and uses the private path for `parcel_pickup.sqlite` supplied by SQLite Manager. Its direct URL returns HTTP 404.

For a fresh deployment, keep the SQLite database outside the web directory and configure PHP with its private path. The host must pass the `Authorization` header to PHP. Verify that `profile.php` returns HTTP 401 with JSON when called without a token. Use test accounts on the campus HTTP service.

## Test the app

Run the Flutter analyzer and the PHP API test suite from the project folder.

```powershell
flutter analyze
pwsh -NoProfile -File tool/test_api.ps1 -Php C:/xampp/php/php.exe
```

The PHP suite uses a temporary database. For the live demo, verify successful registration, duplicate-email rejection, invalid registration, valid and invalid sign-in, and profile display for both roles. Sign in with **Keep me signed in** selected, force-stop the app, and reopen it to check restoration. Then sign out and reopen to confirm the app requires sign-in. An unauthenticated profile request should return HTTP 401.

## Source layout

| Path | Responsibility |
| --- | --- |
| [`lib/main.dart`](lib/main.dart) | API configuration and session lifecycle |
| [`lib/splashscreen.dart`](lib/splashscreen.dart), [`lib/loginscreen.dart`](lib/loginscreen.dart), [`lib/registerscreeen.dart`](lib/registerscreeen.dart), [`lib/screens.dart`](lib/screens.dart) | Splash, sign-in, registration, and dashboard screens |
| [`lib/screen_widgets.dart`](lib/screen_widgets.dart) | App theme, shared form controls, and validation |
| [`lib/auth_api.dart`](lib/auth_api.dart) | HTTP requests, JSON parsing, and API errors |
| [`backend/public/`](backend/public/) | PHP endpoints |
| [`backend/private/`](backend/private/) | Database initialization, authentication helpers, and operator setup |
| [`tool/test_api.ps1`](tool/test_api.ps1) | Backend tests |

The course example `budget_plus` informed the Flutter and PHP structure. The app uses Flutter Material icons. Codex assisted with implementation and reporting.

