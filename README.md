# Update appcast.xml

```shell
./sparkle/bin/generate_appcast \
--download-url-prefix 'https://github.com/PlayCover/PlayCover/releases/download/$TAG_NAME/' \
--link 'https://github.com/PlayCover/PlayCover/releases/tag/$TAG_NAME' \
--full-release-notes-url 'https://github.com/PlayCover/PlayCover/releases/tag/$TAG_NAME' \
-o appcast.xml ./updates
```