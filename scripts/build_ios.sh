#!/bin/bash
# ============================================
#  Epicordia - iOS Release Build Script
#  Run this on a Mac with Xcode installed
# ============================================

set -e

echo "============================================"
echo " Building Epicordia - iOS Release (IPA)"
echo "============================================"
echo ""

# Ensure Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "ERROR: Flutter not found. Install from https://flutter.dev"
    exit 1
fi

# Clean
echo "[1/3] Cleaning previous build..."
flutter clean

# Get dependencies
echo "[2/3] Getting dependencies..."
flutter pub get

# Build IPA
echo "[3/3] Building release IPA..."
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist

echo ""
echo "============================================"
echo " BUILD COMPLETE!"
echo "============================================"
echo ""
echo " Output: build/ios/ipa/Epicordia.ipa"
echo ""
echo " To upload to App Store Connect:"
echo " Option 1: Open Xcode → Window → Organizer → Distribute App"
echo " Option 2: Use Transporter app from Mac App Store"
echo " Option 3: xcrun altool --upload-app -f build/ios/ipa/Epicordia.ipa"
echo "============================================"
