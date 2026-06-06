# Pesa Barbaadi ⛽

Flutter app to split petrol costs with a friend, synced via Firebase and exportable to Excel/PDF/CSV.

## Features
- **Google Sign-In**: Secure authentication.
- **Shared Trips**: Create or join trips via Trip IDs.
- **Real-time Sync**: Automatic balance updates using Firestore.
- **Spending Trends**: Monthly bar charts to track expenses.
- **Multi-format Export**: Generate reports in Excel, PDF, and CSV.
- **Automated CI/CD**: Built-in GitHub Actions for automated distribution.

## CI/CD & Deployment Guide

This project uses **GitHub Actions** and **Fastlane** to automatically build and distribute the Android app to **Firebase App Distribution**.

### Required GitHub Secrets
To make the deployment work, you must add the following secrets to your GitHub repository (**Settings > Secrets and variables > Actions**):

| Secret Name | Description |
| :--- | :--- |
| `FIREBASE_APP_ID` | The App ID from Firebase Console (Project Settings > General). |
| `FIREBASE_TOKEN` | Auth token from `firebase login:ci`. |
| `GOOGLE_SERVICES_JSON` | Base64 encoded content of `google-services.json`. |
| `KEYSTORE_BASE64` | Base64 encoded content of your signing keystore (`.jks` or `.keystore`). |
| `KEY_ALIAS` | The alias of your signing key. |
| `KEY_PASSWORD` | The password for your signing key. |
| `STORE_PASSWORD` | The password for your keystore. |

### How to Encode Files for Secrets
GitHub Secrets only accept plain text. Use these commands in your **Git Bash** terminal to get the Base64 strings:

**For google-services.json:**
```bash
cat android/app/google-services.json | base64 | tr -d '\n'
```

**For your Keystore file:**
```bash
cat path/to/your/release.keystore | base64 | tr -d '\n'
```

### Local Development Setup
1. **Flutter**: Ensure you are on the `stable` channel (Version 3.44.0+ recommended).
2. **Ruby**: Required for Fastlane (Version 3.3+ recommended).
3. **Setup**:
   ```bash
   flutter pub get
   cd android
   bundle install
   ```
4. **Run**:
   ```bash
   flutter run
   ```

### Manual Workflow Dispatch
You can manually trigger a build and distribution from the **Actions** tab on GitHub:
1. Select the **Build & Distribute** workflow.
2. Click **Run workflow** and select the branch.

## Project Structure
- `lib/providers`: State management using Riverpod.
- `lib/repositories`: Firestore data handling.
- `lib/screens`: UI screens (Home, History, Export, etc.).
- `lib/services`: Logic for exports and balance calculations.
- `android/fastlane`: Fastlane lanes for testing and distribution.
- `.github/workflows`: GitHub Actions configuration.
