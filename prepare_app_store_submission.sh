#!/bin/bash

# CryptoMaps App Store Submission Script
# ======================================

echo "====================================================="
echo "🚀 CRYPTOMAPS APP STORE SUBMISSION PREPARATION 🚀"
echo "====================================================="
echo "Version: 1.2.0 (Build 2)"
echo "Bundle ID: raphaelpierre.cryptomaps"
echo

# Confirm versions are correct
echo "1️⃣ CONFIRMING VERSION NUMBERS:"
MARKETING_VERSION=$(xcodebuild -project cryptomaps.xcodeproj -showBuildSettings | grep MARKETING_VERSION | awk '{ print $3 }')
CURRENT_VERSION=$(xcodebuild -project cryptomaps.xcodeproj -showBuildSettings | grep CURRENT_PROJECT_VERSION | awk '{ print $3 }')
BUNDLE_ID=$(xcodebuild -project cryptomaps.xcodeproj -showBuildSettings | grep PRODUCT_BUNDLE_IDENTIFIER | awk '{ print $3 }')

echo "- Marketing Version: $MARKETING_VERSION"
echo "- Build Number: $CURRENT_VERSION"
echo "- Bundle ID: $BUNDLE_ID"
echo

# Ensure all changes are committed
echo "2️⃣ CHECKING FOR UNCOMMITTED CHANGES:"
if [[ -n $(git status --porcelain) ]]; then
  echo "⚠️ WARNING: You have uncommitted changes:"
  git status --short
  echo
  read -p "❓ Do you want to continue anyway? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Aborting submission preparation. Please commit your changes first."
    exit 1
  fi
else
  echo "✅ All changes are committed."
fi
echo

# Build archive for App Store
echo "3️⃣ CREATING APP STORE ARCHIVE:"
echo "This step will build the app and create an archive for App Store submission."
echo "To proceed, follow these steps:"
echo
echo "1. Open Xcode and select the project"
echo "2. Select Product > Archive from the menu"
echo "3. Wait for the archive process to complete"
echo "4. When the Organizer window appears, select the new archive"
echo "5. Click 'Distribute App'"
echo "6. Select 'App Store Connect'"
echo "7. Select 'Upload'"
echo "8. Follow the remaining prompts to upload to App Store Connect"
echo

# Manual archiving command (commented out as Xcode GUI is more reliable for distribution)
# echo "Would you like to start the archive process now? This might take several minutes."
# read -p "Start archive now? (y/n) " -n 1 -r
# echo
# if [[ $REPLY =~ ^[Yy]$ ]]; then
#   echo "Starting archive process..."
#   xcodebuild -project cryptomaps.xcodeproj -scheme cryptomaps -configuration Release clean archive -archivePath ./build/cryptomaps.xcarchive
# fi

# Open Xcode
echo "4️⃣ OPENING PROJECT IN XCODE:"
echo "Opening Xcode now so you can create the archive..."
open cryptomaps.xcodeproj

echo
echo "5️⃣ SUBMISSION NOTES:"
echo "When submitting in App Store Connect, use the following for release notes:"
echo
echo "CryptoMaps v1.2.0 - Performance & Caching Update"
echo "-------------------------------------------"
echo "• Enhanced caching system for better offline experience"
echo "• New detail view for Global Market coin dominance"
echo "• Smarter network layer with automatic retry"
echo "• Cross-view state sharing for better performance"
echo "• Fixed display issues and improved layout"
echo "• Optimized for all supported iOS, macOS, and tvOS versions"
echo

echo "====================================================="
echo "🎉 PREPARATION COMPLETE! 🎉"
echo "====================================================="
echo "Next steps:"
echo "1. Archive the app in Xcode (Product > Archive)"
echo "2. Validate and upload the archive to App Store Connect"
echo "3. Complete the submission in App Store Connect"
echo "   - https://appstoreconnect.apple.com"
echo "4. Push the version bump changes to GitHub"
echo "   - git push origin main"
echo "=====================================================" 