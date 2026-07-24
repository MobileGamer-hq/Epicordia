@echo off
echo ============================================
echo  Building Epicordia - Android Release (AAB)
echo ============================================
echo.

REM Clean previous build
echo [1/3] Cleaning previous build...
flutter clean

REM Get dependencies
echo [2/3] Getting dependencies...
flutter pub get

REM Build the Android App Bundle
echo [3/3] Building release AAB...
flutter build appbundle --release

echo.
echo ============================================
echo  BUILD COMPLETE!
echo ============================================
echo.
echo  Output file:
echo  build\app\outputs\bundle\release\app-release.aab
echo.
echo  Upload this .aab file to Google Play Console:
echo  https://play.google.com/console
echo ============================================
