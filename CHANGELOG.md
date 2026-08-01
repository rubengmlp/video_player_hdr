## 1.0.1
- Fixes a crash in `getSupportedHdrFormats()` on Android API < 24: the native side
  returned a boolean instead of a list, causing a cast error in Dart. It now returns
  an empty list.
- Fixes HDR methods on web: they now throw the documented `HdrVideoError` instead of
  crashing with `UnsupportedError` from `dart:io`.
- `getVideoMetadata()` on iOS now honors the controller's `httpHeaders` for network
  videos (previously they were only applied on Android).
- Fixes the iPhone 16 family model identifier mapping (Pro/non-Pro were swapped) and
  adds the iPhone 16e, iPhone 17 family, iPhone 17e and iPhone Air to the HDR format
  detection on iOS.
- Fixes the `@Deprecated` message of `VideoPlayerHdrController.network` to reference
  the correct class name.
- Updates the iOS podspec: version aligned with the package, minimum iOS raised from
  10.0 to 12.0 (Flutter's supported minimum), declares `swift_version`, removes the
  obsolete i386 exclusion, and fixes the homepage URL.

## 1.0.0
- Initial release

