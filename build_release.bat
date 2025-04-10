@echo off
echo Setting up environment variables for keystore...

REM Set environment variables
set KEYSTORE_PASSWORD=Spiderman_8140541404
set KEY_ALIAS=upload
set KEY_PASSWORD=Spiderman_8140541404

echo Environment variables set:
echo KEYSTORE_PASSWORD=%KEYSTORE_PASSWORD%
echo KEY_ALIAS=%KEY_ALIAS%
echo KEY_PASSWORD=%KEY_PASSWORD%

echo Running Flutter build...
fvm flutter run --release --dart-define=GITHUB_PAT=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

echo Running the app as build process completed.
pause