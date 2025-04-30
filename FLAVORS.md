# App Flavors and Update System

This documentation explains how to use the app flavors (production and staging) and how to manage updates through GitHub Actions.

## App Flavors

The app has two flavors:

1. **Production** - The main app published to users
2. **Staging** - A version for testing that can receive updates independently

### Building Flavors

#### Android

To build the app with a specific flavor, use the following commands:

```bash
# Production build
flutter build apk --flavor production -t lib/main_production.dart

# Staging build
flutter build apk --flavor staging -t lib/main_staging.dart
```

#### Running in Debug Mode

```bash
# Production flavor
flutter run --flavor production -t lib/main_production.dart

# Staging flavor
flutter run --flavor staging -t lib/main_staging.dart
```

## Update System

The app uses two separate update channels:

1. **Production Updates**: Published through standard GitHub Releases
2. **Staging Updates**: Published through a separate branch without creating visible releases

### Publishing Production Updates

1. Create a new tag in the format `v1.2.3` (where 1.2.3 is your version)
2. Push the tag to trigger the existing GitHub workflow:
   ```bash
   git tag v1.2.3
   git push origin v1.2.3
   ```
3. The GitHub Action will build the app and publish a release

#### Force Updates

For mandatory updates, add `-force` to your tag:
```bash
git tag v1.2.3-force
git push origin v1.2.3-force
```

### Publishing Staging Updates

1. Go to the GitHub repository
2. Navigate to Actions → Build and Publish Staging App Update
3. Click "Run workflow"
4. Enter the version number (e.g., "1.2.3")
5. Select whether it should be a force update
6. Click "Run workflow"

The action will:
1. Build the staging app
2. Create or update the test-versions branch
3. Push the APK and version.json file to this branch
4. Staging app users will receive the update notification

## Technical Details

### Flavor Configuration

The flavor system uses:

1. Android product flavors in `android/app/build.gradle`
2. Flutter entry points in `lib/main_production.dart` and `lib/main_staging.dart`
3. `FlavorConfig` to manage build-specific variables

### Update System

- **Production**: Uses GitHub Releases API
- **Staging**: Uses a special branch with version-specific files
- Each flavor checks its appropriate update channel
- Force updates show a non-dismissible dialog

### Folder Structure

The staging update system creates the following structure in the test-versions branch:

```
test-versions/
├── v1.0.0/
│   ├── app-staging-release.apk
│   └── version.json
├── v1.0.1/
│   ├── app-staging-release.apk
│   └── version.json
...
```

Each `version.json` file follows this format:
```json
{
  "version": "1.0.0",
  "apk_url": "https://raw.githubusercontent.com/username/case_sync/test-versions/v1.0.0/app-staging-release.apk",
  "force_update": false
}
``` 