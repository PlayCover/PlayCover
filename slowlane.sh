#!/bin/sh
set -eu -o pipefail

APP_BUNDLE="build/PlayCover.xcarchive/Products/Applications/PlayCover.app"
TAG_NAME=$(git describe --tags --abbrev=0)

rm -rf build

### Build PlayCover

xcodebuild clean archive -scheme PlayCover -configuration Release -archivePath build/PlayCover.xcarchive

codesign -s "Developer ID Application: Hao Guan (29V29Y67P2)" -f -o runtime --deep --timestamp $APP_BUNDLE/Contents/Frameworks/PlayTools.framework/PlugIns/AKInterface.bundle
codesign -s "Developer ID Application: Hao Guan (29V29Y67P2)" -f -o runtime --deep --timestamp $APP_BUNDLE/Contents/Frameworks/PlayTools.framework
codesign -s "Developer ID Application: Hao Guan (29V29Y67P2)" -f -o runtime --deep --timestamp $APP_BUNDLE/Contents/Frameworks/Sparkle.framework
codesign -s "Developer ID Application: Hao Guan (29V29Y67P2)" -f -o runtime --deep --timestamp $APP_BUNDLE

### Package PlayCover

mkdir -p build/PlayCover
ln -sfh /Applications build/PlayCover/Applications
mv $APP_BUNDLE build/PlayCover
hdiutil create -srcfolder build/PlayCover -format UDBZ build/PlayCover.dmg

### Notarize PlayCover

xcrun notarytool submit build/PlayCover.dmg --keychain-profile "HG_NOTARY_PWD" --wait
xcrun stapler staple build/PlayCover.dmg

### Upload PlayCover

rm -rf update/updates
mkdir -p update/updates

mv build/PlayCover.dmg update/updates/PlayCover-$TAG_NAME.dmg
gh release create $TAG_NAME update/updates/PlayCover-$TAG_NAME.dmg --title "$TAG_NAME" --generate-notes

### Publish PlayCover

cd update
./sparkle/bin/generate_appcast \
    --download-url-prefix "https://github.com/hguandl/PlayCover/releases/download/$TAG_NAME/" \
    --link "https://github.com/hguandl/PlayCover/releases/tag/$TAG_NAME" \
    --full-release-notes-url "https://github.com/hguandl/PlayCover/releases/tag/$TAG_NAME" \
    -o appcast.xml ./updates
git add appcast.xml
git commit -S -m "Update appcast.xml"
git push origin update
